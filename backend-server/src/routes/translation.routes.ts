import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';
import { emitTranslationProgress } from '../services/socket.service';

const router = Router();

// Language configuration
const SUPPORTED_LANGUAGES = {
  'en': 'English',
  'zh-Hant': 'Traditional Chinese',
  'zh-Hans': 'Simplified Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
  'es': 'Spanish',
  'fr': 'French',
  'ru': 'Russian',
  'ar': 'Arabic',
  'th': 'Thai',
} as const;

type LanguageCode = keyof typeof SUPPORTED_LANGUAGES;

interface TranslationRequest {
  cardId: string;
  targetLanguages: LanguageCode[];
  forceRetranslate?: boolean;
}

interface TranslationResponse {
  card: {
    name: string;
    description: string;
  };
  contentItems: Array<{
    id: string;
    name: string;
    content: string;
  }>;
}

/**
 * POST /api/translations/translate-card
 * Translate card content to multiple languages using GPT-4.1-nano
 * Requires authentication, validates card ownership
 * Cost: 1 credit per language per card
 */
router.post('/translate-card', authenticateUser, async (req: Request, res: Response) => {
  const startTime = Date.now();
  
  try {
    const { cardId, targetLanguages, forceRetranslate = false }: TranslationRequest = req.body;
    const userId = req.user!.id; // Safe because of authenticateUser middleware

    console.log(`📝 Translation request from user ${userId} for card ${cardId}`);
    console.log(`Languages: ${targetLanguages.join(', ')}, Force: ${forceRetranslate}`);

    // Validate request
    if (!cardId || !targetLanguages || targetLanguages.length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Missing required fields: cardId, targetLanguages'
      });
    }

    // Validate languages
    for (const lang of targetLanguages) {
      if (!(lang in SUPPORTED_LANGUAGES)) {
        return res.status(400).json({
          error: 'Validation error',
          message: `Unsupported language: ${lang}`
        });
      }
    }

    // Fetch card data
    const { data: cardData, error: cardError } = await supabaseAdmin
      .from('cards')
      .select('id, name, description, content_hash, translations, user_id, original_language')
      .eq('id', cardId)
      .single();

    if (cardError || !cardData) {
      return res.status(404).json({
        error: 'Not found',
        message: 'Card not found'
      });
    }

    // Verify ownership
    if (cardData.user_id !== userId) {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Card does not belong to user'
      });
    }

    // Fetch content items
    const { data: contentItems, error: itemsError } = await supabaseAdmin
      .from('content_items')
      .select('id, name, content, content_hash, translations')
      .eq('card_id', cardId)
      .order('sort_order');

    if (itemsError) {
      return res.status(500).json({
        error: 'Database error',
        message: `Failed to fetch content items: ${itemsError.message}`
      });
    }

    // Estimate token count
    const estimateTokens = (text: string) => Math.ceil(text.length / 4);
    const cardTokens = estimateTokens(cardData.name + cardData.description);
    const itemsTokens = contentItems?.reduce((sum, item) => 
      sum + estimateTokens(item.name + item.content), 0) || 0;
    const totalInputTokens = cardTokens + itemsTokens;

    // Check size limits
    const MAX_INPUT_TOKENS = 60000;
    if (totalInputTokens > MAX_INPUT_TOKENS) {
      return res.status(400).json({
        error: 'Content too large',
        message: `Content too large for translation (${totalInputTokens} tokens). Maximum: ${MAX_INPUT_TOKENS} tokens.`
      });
    }

    // Filter languages that need translation
    const languagesToTranslate = targetLanguages.filter(targetLang => {
      if (forceRetranslate) return true;
      
      if (!cardData.translations || !cardData.translations[targetLang]) {
        return true;
      }
      
      const cardExistingHash = cardData.translations[targetLang].content_hash;
      if (cardExistingHash !== cardData.content_hash) {
        return true;
      }
      
      if (contentItems && contentItems.length > 0) {
        const outdatedItems = contentItems.filter(item => {
          if (!item.translations || !item.translations[targetLang]) return true;
          return item.translations[targetLang].content_hash !== item.content_hash;
        });
        if (outdatedItems.length > 0) return true;
      }
      
      return false;
    });

    console.log(`Languages to translate after filtering: ${languagesToTranslate.join(', ')}`);

    // If no languages need translation, return early
    if (languagesToTranslate.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'All selected languages are already up-to-date',
        translated_languages: [],
        credits_used: 0,
        remaining_balance: 0,
      });
    }

    // Calculate credit cost
    const creditCost = languagesToTranslate.length;

    // Check credit balance
    const { data: balanceCheck, error: balanceError } = await supabaseAdmin.rpc(
      'check_credit_balance',
      { p_required_credits: creditCost, p_user_id: userId }
    );

    if (balanceError) {
      return res.status(500).json({
        error: 'Credit check failed',
        message: balanceError.message
      });
    }

    if (balanceCheck < creditCost) {
      return res.status(402).json({
        error: 'Insufficient credits',
        message: `Required: ${creditCost}, Available: ${balanceCheck}`
      });
    }

    // Get OpenAI API key
    const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
    if (!OPENAI_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'OpenAI API key not configured'
      });
    }

    // Prepare translations
    const completedLanguages: string[] = [];
    const failedLanguages: string[] = [];

    // Configure batch processing
    const BATCH_SIZE = 10; // 10 content items per batch
    const totalItems = contentItems?.length || 0;
    const numBatches = Math.ceil(totalItems / BATCH_SIZE);

    console.log(`🚀 Starting translation for ${languagesToTranslate.length} languages...`);
    console.log(`📦 Batch configuration: ${totalItems} items, ${numBatches} batches of ${BATCH_SIZE} items each`);
    console.log(`💾 Translations will be saved after each language completes`);
    console.log(`⚡ Concurrent processing: Max 3 languages at a time\n`);

    // Emit translation started event
    emitTranslationProgress(userId, cardId, {
      type: 'translation:started',
      cardId,
      totalLanguages: languagesToTranslate.length,
      languages: languagesToTranslate,
      timestamp: new Date().toISOString(),
    });

    // Process languages with controlled concurrency (max 3 at a time)
    const MAX_CONCURRENT_LANGUAGES = 3;
    const processLanguage = async (targetLang: LanguageCode, langIndex: number) => {
      const languageStartTime = Date.now();
      console.log(`🌐 [${langIndex + 1}/${languagesToTranslate.length}] Translating to ${SUPPORTED_LANGUAGES[targetLang]}...`);

      // Emit language started event with totalBatches information
      emitTranslationProgress(userId, cardId, {
        type: 'language:started',
        cardId,
        language: targetLang,
        languageIndex: langIndex + 1,
        totalLanguages: languagesToTranslate.length,
        totalBatches: numBatches,
        timestamp: new Date().toISOString(),
      });

      // Temporary storage for this language
      const cardTranslations: Record<string, any> = {};
      const contentItemsTranslations: Record<string, any> = {};

      try {

        // Process batches for this language
        for (let batchIndex = 0; batchIndex < numBatches; batchIndex++) {
          const batchStart = batchIndex * BATCH_SIZE;
          const batchEnd = Math.min(batchStart + BATCH_SIZE, totalItems);
          const batchItems = contentItems?.slice(batchStart, batchEnd) || [];
          const isFirstBatch = batchIndex === 0;

          console.log(`  📦 Batch ${batchIndex + 1}/${numBatches}: Items ${batchStart + 1}-${batchEnd} (${batchItems.length} items)`);

          const translationResponse = await retryWithBackoff(
            () => translateWithGPT4(
              {
                card: isFirstBatch ? {
                  name: cardData.name,
                  description: cardData.description,
                } : { name: '', description: '' }, // Only translate card in first batch
                contentItems: batchItems,
              },
              cardData.original_language || 'en',
              targetLang,
              OPENAI_API_KEY
            ),
            3,
            1000
          );

          // Store card translation (only from first batch)
          if (isFirstBatch) {
            cardTranslations[targetLang] = {
              name: translationResponse.card.name,
              description: translationResponse.card.description,
              translated_at: new Date().toISOString(),
              content_hash: cardData.content_hash,
            };

            console.log(`  ✅ Card translation completed`);
            console.log(`  🔍 DEBUG - Initial card hash captured: ${cardData.content_hash}`);
          }

          // Match content items by INDEX within the batch
          for (let idx = 0; idx < translationResponse.contentItems.length; idx++) {
            const translatedItem = translationResponse.contentItems[idx];
            const originalItem = batchItems[idx]; // Use batchItems, not full contentItems

            if (!originalItem) {
              console.warn(`  ⚠️ No original item at batch index ${idx}`);
              continue;
            }

            if (!contentItemsTranslations[originalItem.id]) {
              contentItemsTranslations[originalItem.id] = {};
            }

            contentItemsTranslations[originalItem.id][targetLang] = {
              name: translatedItem.name,
              content: translatedItem.content,
              translated_at: new Date().toISOString(),
              content_hash: originalItem.content_hash || '',
            };
          }

          console.log(`  ✅ Batch ${batchIndex + 1}/${numBatches} completed (${translationResponse.contentItems.length} items translated)`);

          // Emit batch progress event AFTER batch completes
          emitTranslationProgress(userId, cardId, {
            type: 'batch:progress',
            cardId,
            language: targetLang,
            batchIndex: batchIndex + 1,
            totalBatches: numBatches,
            itemsInBatch: batchItems.length,
            timestamp: new Date().toISOString(),
          });

          // Small delay between batches (except last batch)
          if (batchIndex < numBatches - 1) {
            await new Promise(resolve => setTimeout(resolve, 1000)); // 1 second delay
          }
        }

        console.log(`✅ Completed all batches for ${SUPPORTED_LANGUAGES[targetLang]}`);

        // Save this language's translations to database immediately
        console.log(`💾 Saving ${SUPPORTED_LANGUAGES[targetLang]} translations to database...`);
        
        // Re-fetch current hashes RIGHT before saving to ensure freshness
        // This prevents "outdated" status when content hash changes during translation
        console.log(`🔄 Re-fetching current hashes to prevent stale data...`);
        const { data: freshCardData } = await supabaseAdmin
          .from('cards')
          .select('content_hash')
          .eq('id', cardId)
          .single();

        const { data: freshItems } = await supabaseAdmin
          .from('content_items')
          .select('id, content_hash')
          .eq('card_id', cardId);

        // Update card translation with fresh hash
        if (freshCardData && cardTranslations[targetLang]) {
          const oldHash = cardTranslations[targetLang].content_hash;
          cardTranslations[targetLang].content_hash = freshCardData.content_hash;
          console.log(`  ✅ Card hash updated: ${oldHash} → ${freshCardData.content_hash}`);
          if (oldHash !== freshCardData.content_hash) {
            console.log(`  ⚠️  WARNING: Hash changed during translation! This was the bug.`);
          }
        } else {
          console.log(`  ❌ ERROR: Could not update card hash - freshCardData:`, freshCardData, 'translation exists:', !!cardTranslations[targetLang]);
        }

        // Update content items translations with fresh hashes
        if (freshItems && freshItems.length > 0) {
          let hashUpdates = 0;
          let hashMismatches = 0;
          for (const freshItem of freshItems) {
            if (contentItemsTranslations[freshItem.id]?.[targetLang]) {
              const oldItemHash = contentItemsTranslations[freshItem.id][targetLang].content_hash;
              contentItemsTranslations[freshItem.id][targetLang].content_hash = freshItem.content_hash;
              hashUpdates++;
              if (oldItemHash !== freshItem.content_hash) {
                hashMismatches++;
              }
            }
          }
          console.log(`  ✅ Updated ${hashUpdates} content item hashes (${hashMismatches} had mismatches)`);
        } else {
          console.log(`  ⚠️  No content items to update`);
        }
        
        // Log the final translation object being sent to DB
        console.log(`  🔍 DEBUG - Final translation object for ${targetLang}:`, JSON.stringify({
          card: cardTranslations[targetLang],
          sample_item: Object.keys(contentItemsTranslations).length > 0 
            ? { [Object.keys(contentItemsTranslations)[0]]: contentItemsTranslations[Object.keys(contentItemsTranslations)[0]][targetLang] }
            : 'no items'
        }, null, 2));
        
        const { error: saveError } = await supabaseAdmin.rpc(
          'store_card_translations',
          {
            p_user_id: userId,
            p_card_id: cardId,
            p_target_languages: [targetLang],
            p_card_translations: cardTranslations,
            p_content_items_translations: contentItemsTranslations,
            p_credit_cost: 1, // Charge 1 credit per language
          }
        );

        if (saveError) {
          console.error(`  ❌ Failed to save ${SUPPORTED_LANGUAGES[targetLang]} translations: ${saveError.message}`);
          throw new Error(`Failed to save translations: ${saveError.message}`);
        }

        console.log(`  ✅ ${SUPPORTED_LANGUAGES[targetLang]} translations saved successfully`);
        
        // Add to completed languages (thread-safe since we're in async context)
        completedLanguages.push(targetLang);

        const languageDuration = Date.now() - languageStartTime;
        console.log(`  ⏱️  ${SUPPORTED_LANGUAGES[targetLang]} completed in ${languageDuration}ms\n`);

        // Emit language completed event
        emitTranslationProgress(userId, cardId, {
          type: 'language:completed',
          cardId,
          language: targetLang,
          languageIndex: langIndex + 1,
          totalLanguages: languagesToTranslate.length,
          duration: languageDuration,
          timestamp: new Date().toISOString(),
        });

      } catch (error: any) {
        console.error(`❌ ${SUPPORTED_LANGUAGES[targetLang]} translation failed: ${error.message}`);
        failedLanguages.push(targetLang);
        
        // Emit language failed event
        emitTranslationProgress(userId, cardId, {
          type: 'language:failed',
          cardId,
          language: targetLang,
          error: error.message,
          timestamp: new Date().toISOString(),
        });
      }
    };

    // Process languages in batches of MAX_CONCURRENT_LANGUAGES
    for (let i = 0; i < languagesToTranslate.length; i += MAX_CONCURRENT_LANGUAGES) {
      const batch = languagesToTranslate.slice(i, i + MAX_CONCURRENT_LANGUAGES);
      const batchNumber = Math.floor(i / MAX_CONCURRENT_LANGUAGES) + 1;
      const totalBatches = Math.ceil(languagesToTranslate.length / MAX_CONCURRENT_LANGUAGES);
      
      console.log(`\n⚡ Processing language batch ${batchNumber}/${totalBatches}: ${batch.map(l => SUPPORTED_LANGUAGES[l as LanguageCode]).join(', ')}`);
      
      // Process this batch of languages concurrently
      await Promise.all(
        batch.map((lang, batchIndex) => processLanguage(lang, i + batchIndex))
      );
      
      console.log(`✅ Language batch ${batchNumber}/${totalBatches} completed\n`);
      
      // Small delay between language batches (except last batch)
      if (i + MAX_CONCURRENT_LANGUAGES < languagesToTranslate.length) {
        console.log(`⏳ Waiting 2 seconds before next language batch...\n`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }

    // All languages processed
    const duration = Date.now() - startTime;
    
    // Generate summary
    console.log(`\n📊 Translation Summary:`);
    console.log(`  ✅ Completed: ${completedLanguages.length}/${languagesToTranslate.length} languages`);
    if (completedLanguages.length > 0) {
      console.log(`     Languages: ${completedLanguages.map(l => SUPPORTED_LANGUAGES[l as LanguageCode]).join(', ')}`);
    }
    if (failedLanguages.length > 0) {
      console.log(`  ❌ Failed: ${failedLanguages.length} languages`);
      console.log(`     Languages: ${failedLanguages.map(l => SUPPORTED_LANGUAGES[l as LanguageCode]).join(', ')}`);
    }
    console.log(`  ⏱️  Duration: ${duration}ms`);
    console.log(`  💰 Credits used: ${completedLanguages.length}`);

    // Emit translation completed event
    emitTranslationProgress(userId, cardId, {
      type: 'translation:completed',
      cardId,
      completedLanguages,
      failedLanguages,
      duration,
      timestamp: new Date().toISOString(),
    });

    // Return appropriate response
    if (completedLanguages.length === 0) {
      return res.status(500).json({
        error: 'Translation failed',
        message: 'All languages failed to translate',
        completed_languages: [],
        failed_languages: failedLanguages,
        credits_used: 0,
      });
    }

    const statusCode = failedLanguages.length > 0 ? 207 : 200; // 207 = Multi-Status (partial success)
    
    return res.status(statusCode).json({
      success: true,
      card_id: cardId,
      translated_languages: completedLanguages,
      failed_languages: failedLanguages,
      credits_used: completedLanguages.length,
      partial_success: failedLanguages.length > 0,
      message: failedLanguages.length > 0
        ? `Completed ${completedLanguages.length}/${languagesToTranslate.length} languages. Failed: ${failedLanguages.map(l => SUPPORTED_LANGUAGES[l as LanguageCode]).join(', ')}`
        : `All ${completedLanguages.length} languages completed successfully`,
    });

  } catch (error: any) {
    console.error('❌ Translation error:', error);
    
    // Emit translation error event
    try {
      const { cardId } = req.body as TranslationRequest;
      const userId = (req as any).user?.id;
      if (userId && cardId) {
        emitTranslationProgress(userId, cardId, {
          type: 'translation:error',
          cardId,
          error: error.message,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (emitError) {
      console.error('Failed to emit error event:', emitError);
    }
    
    return res.status(500).json({
      error: 'Translation failed',
      message: error.message || 'Internal server error',
      details: error.toString(),
    });
  }
});

// Helper: Retry with exponential backoff
async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: Error = new Error('Unknown error');
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error: any) {
      lastError = error;
      
      if (error.message.includes('Unauthorized') || 
          error.message.includes('Content too large') ||
          error.message.includes('Insufficient credits')) {
        throw error;
      }
      
      if (attempt === maxRetries - 1) break;
      
      const delay = baseDelay * Math.pow(2, attempt);
      console.log(`Attempt ${attempt + 1} failed: ${error.message}. Retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw new Error(`Operation failed after ${maxRetries} attempts: ${lastError.message}`);
}

// Helper: Translate with GPT-4.1-nano
async function translateWithGPT4(
  data: {
    card: { name: string; description: string };
    contentItems: Array<{ id: string; name: string; content: string }>;
  },
  sourceLang: string,
  targetLang: LanguageCode,
  apiKey: string
): Promise<TranslationResponse> {
  const sourceLanguageName = SUPPORTED_LANGUAGES[sourceLang as LanguageCode] || 'English';
  const targetLanguageName = SUPPORTED_LANGUAGES[targetLang];

  const systemPrompt = `You are a professional translator specializing in museum, cultural heritage, tourism, and exhibition content. Your task is to translate content from ${sourceLanguageName} to ${targetLanguageName}.

GUIDELINES:
- Maintain cultural sensitivity and use proper terminology for museum/cultural contexts
- Preserve markdown formatting exactly (headings, lists, links, bold, italic, etc.)
- Keep proper nouns (names of people, places, artworks) in their original form when appropriate
- Translate measurements and dates according to target language conventions
- Ensure translations sound natural and engaging for visitors
- Maintain the original tone and style (formal, educational, welcoming)
- For technical terms, use standard translations in the museum/cultural field
- Preserve any HTML tags or special formatting
- For Arabic: use proper right-to-left formatting markers if needed

IMPORTANT: Return ONLY valid JSON with no additional text, explanations, or markdown code blocks. The JSON must match this exact structure:
{
  "card": {
    "name": "translated name",
    "description": "translated description"
  },
  "contentItems": [
    {
      "id": "uuid-here",
      "name": "translated name",
      "content": "translated content with preserved markdown"
    }
  ]
}`;

  // Build user prompt - only include card section if it has content (for batch processing)
  const hasCardContent = data.card.name || data.card.description;
  const cardSection = hasCardContent ? `CARD:
Name: ${data.card.name}
Description: ${data.card.description}

` : '';

  const userPrompt = `Translate the following content from ${sourceLanguageName} to ${targetLanguageName}:

${cardSection}CONTENT ITEMS (${data.contentItems.length} items):
${data.contentItems.map((item, idx) => `
Item ${idx + 1} (ID: ${item.id}):
- Name: ${item.name}
- Content: ${item.content}
`).join('\n')}
${!hasCardContent ? '\nNote: For the card section, return empty strings for name and description.' : ''}

Remember: Return ONLY the JSON object, no markdown code blocks or explanations.`;

  // Estimate total token count for input
  const estimateTokens = (text: string) => Math.ceil(text.length / 4);
  const systemPromptTokens = estimateTokens(systemPrompt);
  const userPromptTokens = estimateTokens(userPrompt);
  const totalInputTokens = systemPromptTokens + userPromptTokens;

  // gpt-4.1-nano context window
  const MODEL_CONTEXT_WINDOW = 128000; // gpt-4.1-nano has 128K context window
  
  // Calculate max completion tokens dynamically
  // Use configured max or default to 16K, but ensure input + output fits in context window
  const configuredMaxTokens = parseInt(process.env.OPENAI_TRANSLATION_MAX_TOKENS || '16000', 10);
  const availableOutputTokens = MODEL_CONTEXT_WINDOW - totalInputTokens;
  const maxCompletionTokens = Math.min(configuredMaxTokens, availableOutputTokens);

  // Validate we have enough space for output
  if (maxCompletionTokens < 1000) {
    throw new Error(
      `Input too large: ${totalInputTokens} input tokens leaves only ${availableOutputTokens} tokens for output. ` +
      `Model context window is ${MODEL_CONTEXT_WINDOW} tokens. ` +
      `Please reduce the amount of content or translate fewer items at once.`
    );
  }

  const totalTokensNeeded = totalInputTokens + maxCompletionTokens;

  console.log(`📊 Token estimation for ${targetLanguageName}:`, {
    systemPromptTokens,
    userPromptTokens,
    totalInputTokens,
    maxCompletionTokens,
    totalTokensNeeded,
    modelContextWindow: MODEL_CONTEXT_WINDOW,
    requestSizeBytes: systemPrompt.length + userPrompt.length,
    contentItemCount: data.contentItems.length,
  });

  // Configure timeout (2 minutes for large translations)
  const timeoutMs = parseInt(process.env.OPENAI_TRANSLATION_TIMEOUT_MS || '120000', 10);
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: process.env.OPENAI_TRANSLATION_MODEL || 'gpt-4.1-nano-2025-04-14',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
        max_completion_tokens: maxCompletionTokens,
        response_format: { type: 'json_object' }, // Ensure valid JSON output
        temperature: 0.3, // Low temperature for consistent translations
        // Note: gpt-4.1-nano doesn't support reasoning parameters (only o-series models do)
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errorData = await response.text();
      throw new Error(`OpenAI API error: ${response.statusText} - ${errorData}`);
    }

    const result = await response.json() as any;
  
  // Debug logging
  console.log('OpenAI Response structure:', JSON.stringify({
    hasChoices: !!result.choices,
    choicesLength: result.choices?.length,
    firstChoice: result.choices?.[0] ? {
      hasMessage: !!result.choices[0].message,
      messageKeys: result.choices[0].message ? Object.keys(result.choices[0].message) : [],
      contentLength: result.choices[0].message?.content?.length || 0,
      finishReason: result.choices[0].finish_reason
    } : null
  }, null, 2));
  
  if (!result.choices || result.choices.length === 0) {
    throw new Error('OpenAI returned an empty response');
  }

  const translatedContent = result.choices[0].message?.content;
  const finishReason = result.choices[0].finish_reason;
  
  if (!translatedContent || translatedContent.trim().length === 0) {
    console.error('Empty content error. Full response:', JSON.stringify(result, null, 2));
    throw new Error('OpenAI returned empty translation content');
  }

  if (finishReason === 'length') {
    throw new Error('Translation response was truncated. Content may be too large.');
  }

    // Parse JSON response
    let translationData: TranslationResponse;
    try {
      let cleanedContent = translatedContent
        .replace(/```json\s*/gi, '')
        .replace(/```\s*/g, '')
        .replace(/^[^{]*/g, '')
        .replace(/[^}]*$/g, '')
        .trim();
      
      const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        cleanedContent = jsonMatch[0];
      }
      
      translationData = JSON.parse(cleanedContent);
    } catch (parseError: any) {
      throw new Error(`Failed to parse translation response: ${parseError.message}`);
    }

    // Validate response structure
    if (!translationData.card || !translationData.contentItems) {
      throw new Error('Invalid translation response structure');
    }

    // Allow empty card data for subsequent batches (batch processing)
    const hasCardContent = data.card.name || data.card.description;
    if (hasCardContent) {
      // If we sent card data, validate we got it back
      if (!translationData.card.name || !translationData.card.description) {
        throw new Error('Invalid card translation: missing name or description');
      }
    }

    if (!Array.isArray(translationData.contentItems)) {
      throw new Error('Invalid contentItems: expected an array');
    }

    return translationData;
    
  } catch (error: any) {
    clearTimeout(timeoutId);
    
    // Enhanced error handling for network issues
    if (error.name === 'AbortError') {
      throw new Error(`Translation request timed out after ${timeoutMs}ms. Try reducing content size or increasing timeout.`);
    }
    
    if (error.code === 'ECONNRESET' || error.code === 'UND_ERR_SOCKET' || error.message.includes('fetch failed')) {
      console.error('🔴 Network error calling OpenAI API:', {
        message: error.message,
        code: error.code,
        cause: error.cause,
        stack: error.stack
      });
      throw new Error('Network error: Connection to OpenAI was closed. This may be due to request size or network issues. Try again or reduce content size.');
    }
    
    throw error;
  }
}

export default router;


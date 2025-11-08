import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';
import { emitTranslationProgress } from '../services/socket.service';
import { geminiClient } from '../services/gemini-client';

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

/**
 * POST /api/translations/translate-card
 * Synchronously translate card content to multiple languages
 * Provides real-time progress updates via Socket.IO
 */
router.post('/translate-card', authenticateUser, async (req: Request, res: Response) => {
  const startTime = Date.now();
  
  try {
    const { cardId, targetLanguages, forceRetranslate = false }: TranslationRequest = req.body;
    const userId = req.user!.id;

    console.log(`\n📝 Translation request from user ${userId} for card ${cardId}`);
    console.log(`   Languages: ${targetLanguages.join(', ')}, Force: ${forceRetranslate}`);

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

    console.log(`   Languages to translate: ${languagesToTranslate.join(', ')}`);

    // If no languages need translation, return early
    if (languagesToTranslate.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'All selected languages are already up-to-date',
        translated_languages: [],
        credits_used: 0,
      });
    }

    // Emit translation started event
    emitTranslationProgress(userId, cardId, {
      type: 'translation:started',
      cardId,
      languages: languagesToTranslate,
      totalLanguages: languagesToTranslate.length,
      timestamp: new Date().toISOString(),
    });

    // Process translations
    const completedLanguages: string[] = [];
    const failedLanguages: string[] = [];
    const totalItems = contentItems?.length || 0;
    const batchSize = parseInt(process.env.TRANSLATION_BATCH_SIZE || '10', 10);
    const numBatches = Math.ceil(totalItems / batchSize);
    const MAX_CONCURRENT_LANGUAGES = parseInt(process.env.TRANSLATION_MAX_CONCURRENT_LANGUAGES || '3', 10);
    const BATCH_DELAY_MS = parseInt(process.env.TRANSLATION_BATCH_DELAY_MS || '1000', 10);
    const LANGUAGE_BATCH_DELAY_MS = parseInt(process.env.TRANSLATION_LANGUAGE_BATCH_DELAY_MS || '2000', 10);

    // Collect ALL translations for batch saving (prevents race conditions)
    const allCardTranslations: Record<string, any> = {};
    const allContentItemsTranslations: Record<string, Record<string, any>> = {};

    // Process languages with controlled concurrency
    const processLanguage = async (targetLang: LanguageCode, langIndex: number) => {
      const languageStartTime = Date.now();
      console.log(`\n🌐 [${langIndex + 1}/${languagesToTranslate.length}] Translating to ${SUPPORTED_LANGUAGES[targetLang]}...`);

      // Emit language started event
      emitTranslationProgress(userId, cardId, {
        type: 'language:started',
        cardId,
        language: targetLang,
        languageIndex: langIndex + 1,
        totalLanguages: languagesToTranslate.length,
        totalBatches: numBatches,
        timestamp: new Date().toISOString(),
      });

      try {
        // Process batches for this language
        for (let batchIndex = 0; batchIndex < numBatches; batchIndex++) {
          const batchStart = batchIndex * batchSize;
          const batchEnd = Math.min(batchStart + batchSize, totalItems);
          const batchItems = contentItems?.slice(batchStart, batchEnd) || [];
          const isFirstBatch = batchIndex === 0;

          console.log(`   📦 Batch ${batchIndex + 1}/${numBatches} (items ${batchStart + 1}-${batchEnd})`);

          // Translate batch
          const translations = await translateBatch(
            cardData,
            batchItems,
            targetLang,
            isFirstBatch
          );

          // Store translations in shared collection
          if (isFirstBatch && translations.card) {
            allCardTranslations[targetLang] = {
              name: translations.card.name,
              description: translations.card.description,
              content_hash: cardData.content_hash,
              translated_at: new Date().toISOString(),
            };
          }

          if (translations.contentItems) {
            translations.contentItems.forEach((item: any, index: number) => {
              const originalItem = batchItems[index];
              if (!allContentItemsTranslations[originalItem.id]) {
                allContentItemsTranslations[originalItem.id] = {};
              }
              allContentItemsTranslations[originalItem.id][targetLang] = {
                name: item.name,
                content: item.content,
                content_hash: originalItem.content_hash,
                translated_at: new Date().toISOString(),
              };
            });
          }

          // Emit batch progress
          emitTranslationProgress(userId, cardId, {
            type: 'batch:completed',
            cardId,
            language: targetLang,
            batchIndex: batchIndex + 1,
            totalBatches: numBatches,
            timestamp: new Date().toISOString(),
          });

          // Delay between batches
          if (batchIndex < numBatches - 1) {
            await new Promise(resolve => setTimeout(resolve, BATCH_DELAY_MS));
          }
        }

        const languageTime = ((Date.now() - languageStartTime) / 1000).toFixed(1);
        console.log(`   ✅ ${SUPPORTED_LANGUAGES[targetLang]} completed in ${languageTime}s`);

        completedLanguages.push(targetLang);

        // Emit language completed event
        emitTranslationProgress(userId, cardId, {
          type: 'language:completed',
          cardId,
          language: targetLang,
          timestamp: new Date().toISOString(),
        });
      } catch (error: any) {
        console.error(`   ❌ ${SUPPORTED_LANGUAGES[targetLang]} failed:`, error.message);
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
      const languageBatch = languagesToTranslate.slice(i, i + MAX_CONCURRENT_LANGUAGES);
      await Promise.all(languageBatch.map((lang: LanguageCode, index: number) => 
        processLanguage(lang, i + index)
      ));
      
      // Delay between language batches
      if (i + MAX_CONCURRENT_LANGUAGES < languagesToTranslate.length) {
        await new Promise(resolve => setTimeout(resolve, LANGUAGE_BATCH_DELAY_MS));
      }
    }

    // Save ALL translations to database (after all languages complete)
    // This prevents race conditions from concurrent language processing
    console.log(`\n💾 Saving all translations to database...`);
    await saveTranslations(cardId, cardData, allCardTranslations, allContentItemsTranslations);

    // Calculate total time
    const totalTime = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`✅ Translation completed in ${totalTime}s`);
    console.log(`   Completed: ${completedLanguages.length}, Failed: ${failedLanguages.length}\n`);

    // Consume credits for each completed language
    for (const language of completedLanguages) {
      try {
        await supabaseAdmin.rpc('consume_translation_credits', {
          p_user_id: userId,
          p_card_id: cardId,
          p_language: language,
          p_credit_cost: 1.0,
        });
      } catch (error: any) {
        console.error(`❌ Failed to consume credit for ${language}:`, error.message);
      }
    }

    // Record translation completion in history
    if (completedLanguages.length > 0 || failedLanguages.length > 0) {
      try {
        await supabaseAdmin.rpc('record_translation_completion', {
          p_user_id: userId,
          p_card_id: cardId,
          p_target_languages: completedLanguages,
          p_credit_cost: completedLanguages.length,
          p_status: failedLanguages.length > 0 ? 'partial' : 'completed',
          p_error_message: failedLanguages.length > 0 
            ? `Failed languages: ${failedLanguages.join(', ')}` 
            : null,
          p_metadata: {
            completed: completedLanguages.length,
            failed: failedLanguages.length,
            duration: parseFloat(totalTime),
          },
        });
      } catch (error: any) {
        console.error('❌ Failed to record translation history:', error.message);
      }
    }

    // Emit translation completed event
    emitTranslationProgress(userId, cardId, {
      type: 'translation:completed',
      cardId,
      completedLanguages,
      failedLanguages,
      duration: parseFloat(totalTime),
      timestamp: new Date().toISOString(),
    });

    // Return response
    return res.status(200).json({
      success: true,
      message: 'Translation completed',
      translated_languages: completedLanguages,
      failed_languages: failedLanguages,
      credits_used: completedLanguages.length,
      duration: parseFloat(totalTime),
    });
  } catch (error: any) {
    console.error('❌ Translation error:', error);
    
    return res.status(500).json({
      error: 'Translation failed',
      message: error.message || 'Internal server error',
    });
  }
});

/**
 * Translate a batch of content using Gemini
 */
async function translateBatch(
  cardData: any,
  batchItems: any[],
  targetLang: LanguageCode,
  includeCard: boolean
): Promise<any> {
  // Build prompt
  const sourceContent: any = {
    contentItems: batchItems.map(item => ({
      id: item.id,
      name: item.name,
      content: item.content,
    }))
  };

  if (includeCard) {
    sourceContent.card = {
      name: cardData.name,
      description: cardData.description,
    };
  }

  const systemInstruction = `You are a professional translator. Translate the given content from ${cardData.original_language || 'English'} to ${SUPPORTED_LANGUAGES[targetLang]}.

CRITICAL INSTRUCTIONS:
1. Return ONLY a valid JSON object matching the input structure exactly
2. Keep all "id" fields unchanged
3. Translate "name", "description", and "content" fields naturally
4. Maintain the same structure and number of items
5. Do not add any explanation or markdown formatting
6. Ensure cultural appropriateness and natural phrasing`;

  const prompt = `${systemInstruction}\n\nTranslate this content to ${SUPPORTED_LANGUAGES[targetLang]}:\n\n${JSON.stringify(sourceContent, null, 2)}`;

  // Call Gemini API
  const data = await geminiClient.generateContent(prompt);
  
  if (!data.candidates || data.candidates.length === 0) {
    throw new Error('Gemini API returned no candidates');
  }

  const textContent = data.candidates[0].content.parts[0].text;
  const translatedContent = JSON.parse(textContent);

  return translatedContent;
}

/**
 * Save translations to database
 * IMPORTANT: Re-fetches current hashes before saving to prevent "outdated" status
 * See: TRANSLATION_HASH_FRESHNESS_FIX.md
 */
async function saveTranslations(
  cardId: string,
  cardData: any,
  cardTranslations: Record<string, any>,
  contentItemsTranslations: Record<string, Record<string, any>>
) {
  // CRITICAL: Re-fetch current card hash before saving
  // This ensures we save with the EXACT current hash, preventing "outdated" status
  const { data: freshCardData } = await supabaseAdmin
    .from('cards')
    .select('content_hash')
    .eq('id', cardId)
    .single();

  // Update card translations with fresh hash
  if (Object.keys(cardTranslations).length > 0) {
    // Update each language's translation with the FRESH hash
    const updatedCardTranslations: Record<string, any> = {};
    for (const [lang, trans] of Object.entries(cardTranslations)) {
      updatedCardTranslations[lang] = {
        ...trans,
        content_hash: freshCardData?.content_hash || trans.content_hash,
      };
    }

    const finalTranslations = { ...cardData.translations, ...updatedCardTranslations };
    
    await supabaseAdmin
      .from('cards')
      .update({ translations: finalTranslations })
      .eq('id', cardId);
  }

  // Save content item translations with fresh hashes
  for (const [itemId, translations] of Object.entries(contentItemsTranslations)) {
    // Re-fetch current content_hash for this item
    const { data: freshItemData } = await supabaseAdmin
      .from('content_items')
      .select('translations, content_hash')
      .eq('id', itemId)
      .single();

    // Update each language's translation with the FRESH hash
    const updatedItemTranslations: Record<string, any> = {};
    for (const [lang, trans] of Object.entries(translations)) {
      updatedItemTranslations[lang] = {
        ...trans,
        content_hash: freshItemData?.content_hash || trans.content_hash,
      };
    }

    const finalTranslations = { ...freshItemData?.translations, ...updatedItemTranslations };
    
    await supabaseAdmin
      .from('content_items')
      .update({ translations: finalTranslations })
      .eq('id', itemId);
  }
}

export default router;


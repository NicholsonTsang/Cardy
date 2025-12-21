import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';
import { geminiClient } from '../services/gemini-client';

const router = Router();

/**
 * Check if user has premium subscription via stored procedure
 */
async function isPremiumUser(userId: string): Promise<boolean> {
  const { data, error } = await supabaseAdmin.rpc(
    'check_premium_subscription_server',
    { p_user_id: userId }
  );
  
  if (error) {
    return false;
  }
  
  return data === true;
}

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
 * Attempt to repair malformed JSON from LLM responses
 * Handles common issues: BOM, unquoted keys, single quotes, trailing commas, unescaped chars, missing brackets
 */
function repairJSON(text: string): string {
  let result = text;
  
  // Remove BOM (Byte Order Mark) and other invisible characters at start
  result = result.replace(/^\uFEFF/, ''); // UTF-8 BOM
  result = result.replace(/^\u00EF\u00BB\u00BF/, ''); // UTF-8 BOM (alternate)
  result = result.replace(/^[\u200B-\u200D\uFEFF\u00A0]+/, ''); // Zero-width spaces, NBSP
  
  result = result.trim();
  
  // Remove markdown code blocks
  if (result.startsWith('```json')) {
    result = result.slice(7);
  } else if (result.startsWith('```')) {
    result = result.slice(3);
  }
  if (result.endsWith('```')) {
    result = result.slice(0, -3);
  }
  result = result.trim();
  
  // Fix unescaped backslashes (not part of valid escape sequences)
  result = result.replace(/\\(?!["\\/bfnrtu])/g, '\\\\');
  
  // Remove trailing commas before } or ]
  result = result.replace(/,(\s*[}\]])/g, '$1');
  
  // Add missing commas between property values and next property names
  // Pattern: "value" followed by whitespace then "propertyName":
  // This catches: "value"\n    "nextProp": which should be "value",\n    "nextProp":
  result = result.replace(/(")\s*\n(\s*"[^"]+"\s*:)/g, '$1,\n$2');
  
  // Also catch: } followed by whitespace then "propertyName": (missing comma after object)
  result = result.replace(/(})\s*\n(\s*"[^"]+"\s*:)/g, '$1,\n$2');
  
  // And: ] followed by whitespace then "propertyName": (missing comma after array)
  result = result.replace(/(\])\s*\n(\s*"[^"]+"\s*:)/g, '$1,\n$2');
  
  // Try to fix unquoted property names (limited - for simple cases)
  // Match: { key: or , key: where key is unquoted
  result = result.replace(/([{,]\s*)([a-zA-Z_][a-zA-Z0-9_]*)(\s*:)/g, '$1"$2"$3');
  
  // Fix single quotes to double quotes (be careful with apostrophes in text)
  // Only fix quotes around property names and simple string values
  // This regex is conservative to avoid breaking apostrophes in content
  result = result.replace(/'([^'\\]*(?:\\.[^'\\]*)*)'/g, (match, content) => {
    // If content looks like a property value or is short, convert
    if (content.length < 100 || /^[a-zA-Z0-9_-]+$/.test(content)) {
      return `"${content.replace(/"/g, '\\"')}"`;
    }
    return match; // Leave long text content alone
  });
  
  // Fix missing closing brackets - count brackets and add missing ones
  const openBraces = (result.match(/{/g) || []).length;
  const closeBraces = (result.match(/}/g) || []).length;
  const openBrackets = (result.match(/\[/g) || []).length;
  const closeBrackets = (result.match(/\]/g) || []).length;
  
  // Add missing closing brackets/braces at the end
  if (openBrackets > closeBrackets) {
    // Check if it ends with } and needs ] before it
    if (result.trimEnd().endsWith('}')) {
      const missingBrackets = openBrackets - closeBrackets;
      // Insert ] before the last }
      const lastBraceIndex = result.lastIndexOf('}');
      result = result.slice(0, lastBraceIndex) + ']'.repeat(missingBrackets) + result.slice(lastBraceIndex);
    } else {
      result += ']'.repeat(openBrackets - closeBrackets);
    }
  }
  if (openBraces > closeBraces) {
    result += '}'.repeat(openBraces - closeBraces);
  }
  
  return result;
}

/**
 * Escape control characters inside JSON string values
 * This handles literal newlines, tabs, etc. that should be escaped
 */
function escapeControlCharsInStrings(text: string): string {
  let result = '';
  let inString = false;
  let escaped = false;
  
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    const charCode = char.charCodeAt(0);
    
    if (escaped) {
      result += char;
      escaped = false;
      continue;
    }
    
    if (char === '\\' && inString) {
      escaped = true;
      result += char;
      continue;
    }
    
    if (char === '"' && !escaped) {
      inString = !inString;
      result += char;
      continue;
    }
    
    // If inside a string and we find a control character, escape it
    if (inString && charCode < 32) {
      if (char === '\n') {
        result += '\\n';
      } else if (char === '\r') {
        result += '\\r';
      } else if (char === '\t') {
        result += '\\t';
      } else {
        // Other control chars - use unicode escape
        result += '\\u' + charCode.toString(16).padStart(4, '0');
      }
    } else {
      result += char;
    }
  }
  
  return result;
}

/**
 * Safely parse JSON with multiple repair strategies
 */
function safeParseJSON(text: string): any {
  const strategies = [
    { name: 'direct', fn: (t: string) => t },
    { name: 'control-chars-first', fn: (t: string) => escapeControlCharsInStrings(t) },
    { name: 'repair', fn: (t: string) => repairJSON(t) },
    { name: 'control-then-repair', fn: (t: string) => repairJSON(escapeControlCharsInStrings(t)) },
    { name: 'repair-then-control', fn: (t: string) => escapeControlCharsInStrings(repairJSON(t)) },
  ];
  
  let firstError: Error | null = null;
  
  for (const strategy of strategies) {
    try {
      const processed = strategy.fn(text);
      const result = JSON.parse(processed);
      if (strategy.name !== 'direct') {
        console.log(`      ✅ JSON parsed using '${strategy.name}' strategy`);
      }
      return result;
    } catch (error) {
      if (!firstError) firstError = error as Error;
      // Continue to next strategy
    }
  }
  
  // All strategies failed - log details for debugging
  console.error('JSON parse failed after all repair strategies');
  console.error('Original error:', firstError?.message);
  console.error('First 500 chars:', text.substring(0, 500));
  console.error('Last 500 chars:', text.substring(Math.max(0, text.length - 500)));
  
  // Show character at error position if available
  const match = firstError?.message.match(/position (\d+)/);
  if (match) {
    const pos = parseInt(match[1]);
    const start = Math.max(0, pos - 30);
    const end = Math.min(text.length, pos + 30);
    const context = text.substring(start, end);
    const marker = ' '.repeat(pos - start) + '^';
    console.error(`Around position ${pos}:\n${JSON.stringify(context)}\n${marker}`);
    console.error(`Char at position ${pos}: code=${text.charCodeAt(pos)}, char=${JSON.stringify(text[pos])}`);
  }
  
  throw firstError;
}

/**
 * POST /api/translations/translate-card
 * Synchronously translate card content to multiple languages
 * Returns translation results after processing completes
 */
router.post('/translate-card', authenticateUser, async (req: Request, res: Response) => {
  const startTime = Date.now();
  
  try {
    const { cardId, targetLanguages, forceRetranslate = false }: TranslationRequest = req.body;
    const userId = req.user!.id;

    console.log(`\n📝 Translation request from user ${userId} for card ${cardId}`);
    console.log(`   Languages: ${targetLanguages.join(', ')}, Force: ${forceRetranslate}`);

    // Check if user has premium subscription (translations are free for premium only)
    const hasPremium = await isPremiumUser(userId);
    if (!hasPremium) {
      console.log(`❌ Translation denied: User ${userId} is not a premium subscriber`);
      return res.status(403).json({
        error: 'Premium required',
        message: 'Multi-language translations are only available for Premium subscribers. Please upgrade your plan to access this feature.'
      });
    }

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

    // Fetch card data via stored procedure
    console.log(`   🔍 Calling get_card_for_translation_server for ${cardId}...`);
    const { data: cardDataRows, error: cardError } = await supabaseAdmin.rpc(
      'get_card_for_translation_server',
      { p_card_id: cardId }
    );

    if (cardError) {
      console.error('   ❌ RPC Error:', JSON.stringify(cardError, null, 2));
    } else {
      console.log(`   ✅ RPC returned ${cardDataRows?.length ?? 0} rows`);
      
      if (!cardDataRows || cardDataRows.length === 0) {
        console.log(`   ⚠️ Card not found via RPC. Performing direct DB check...`);
        // Debug: check if card exists at all using admin client direct query
        const { data: directCheck, error: directError } = await supabaseAdmin
           .from('cards')
           .select('id, user_id')
           .eq('id', cardId)
           .single();
        console.log(`   🕵️ Direct DB check:`, directError ? `Error: ${directError.message}` : `Found: ${JSON.stringify(directCheck)}`);
      }
    }

    const cardData = cardDataRows?.[0];

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

    // Fetch content items via stored procedure
    const { data: contentItems, error: itemsError } = await supabaseAdmin.rpc(
      'get_content_items_for_translation_server',
      { p_card_id: cardId }
    );

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
        const outdatedItems = contentItems.filter((item: any) => {
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

          // Store translations in shared collection (include ALL text fields)
          if (isFirstBatch && translations.card) {
            allCardTranslations[targetLang] = {
              name: translations.card.name,
              description: translations.card.description,
              ai_instruction: translations.card.ai_instruction || '',
              ai_knowledge_base: translations.card.ai_knowledge_base || '',
              ai_welcome_general: translations.card.ai_welcome_general || '',
              ai_welcome_item: translations.card.ai_welcome_item || '',
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
                ai_knowledge_base: item.ai_knowledge_base || '',
                content_hash: originalItem.content_hash,
                translated_at: new Date().toISOString(),
              };
            });
          }

          // Delay between batches
          if (batchIndex < numBatches - 1) {
            await new Promise(resolve => setTimeout(resolve, BATCH_DELAY_MS));
          }
        }

        const languageTime = ((Date.now() - languageStartTime) / 1000).toFixed(1);
        console.log(`   ✅ ${SUPPORTED_LANGUAGES[targetLang]} completed in ${languageTime}s`);

        completedLanguages.push(targetLang);
      } catch (error: any) {
        console.error(`   ❌ ${SUPPORTED_LANGUAGES[targetLang]} failed:`, error.message);
        failedLanguages.push(targetLang);
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

    // Note: Translations are FREE for premium users - no credit consumption
    // Record translation completion in history via stored procedure
    if (completedLanguages.length > 0 || failedLanguages.length > 0) {
      try {
        await supabaseAdmin.rpc('insert_translation_history_server', {
          p_card_id: cardId,
          p_user_id: userId,
          p_target_languages: completedLanguages,
          p_credit_cost: 0, // Free for premium users
          p_status: failedLanguages.length > 0 ? 'partial' : 'completed',
          p_error_message: failedLanguages.length > 0 
            ? `Failed languages: ${failedLanguages.join(', ')}` 
            : null,
          p_metadata: {
            completed: completedLanguages.length,
            failed: failedLanguages.length,
            duration: parseFloat(totalTime),
            free_for_premium: true,
          },
        });
      } catch (error: any) {
        console.error('❌ Failed to record translation history:', error.message);
      }
    }

    // Return response
    return res.status(200).json({
      success: true,
      message: 'Translation completed',
      translated_languages: completedLanguages,
      failed_languages: failedLanguages,
      credits_used: 0, // Free for premium users
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
  // Build prompt - include ALL translatable text fields
  const sourceContent: any = {
    contentItems: batchItems.map(item => ({
      id: item.id,
      name: item.name,
      content: item.content,
      ai_knowledge_base: item.ai_knowledge_base || '', // Content-specific AI knowledge
    }))
  };

  if (includeCard) {
    sourceContent.card = {
      name: cardData.name,
      description: cardData.description,
      ai_instruction: cardData.ai_instruction || '', // AI role/personality
      ai_knowledge_base: cardData.ai_knowledge_base || '', // AI background knowledge
      ai_welcome_general: cardData.ai_welcome_general || '', // General AI welcome message
      ai_welcome_item: cardData.ai_welcome_item || '', // Item AI welcome message
    };
  }

  const systemInstruction = `You are a professional translator. Translate the given content from ${cardData.original_language || 'English'} to ${SUPPORTED_LANGUAGES[targetLang]}.

CRITICAL INSTRUCTIONS:
1. Return ONLY a valid JSON object matching the input structure exactly
2. Keep all "id" fields unchanged
3. Translate ALL text fields: "name", "description", "content", "ai_instruction", "ai_knowledge_base", "ai_welcome_general", "ai_welcome_item"
4. Maintain the same structure and number of items
5. Do not add any explanation or markdown formatting
6. Ensure cultural appropriateness and natural phrasing
7. For empty strings (""), return empty strings - do not translate them
8. CRITICAL: Ensure all special characters in JSON strings are properly escaped (backslashes as \\\\, quotes as \\", etc.)`;

  const prompt = `${systemInstruction}\n\nTranslate this content to ${SUPPORTED_LANGUAGES[targetLang]}:\n\n${JSON.stringify(sourceContent, null, 2)}`;

  // Call Gemini API with retry logic for transient failures
  const MAX_RETRIES = 2;
  let lastError: Error | null = null;
  
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    try {
      if (attempt > 0) {
        console.log(`      🔄 Retry attempt ${attempt}/${MAX_RETRIES}...`);
        // Wait before retry (exponential backoff)
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
      
      const data = await geminiClient.generateContent(prompt);
      
      if (!data.candidates || data.candidates.length === 0) {
        throw new Error('Gemini API returned no candidates');
      }

      const textContent = data.candidates[0].content.parts[0].text;
      
      // Use safe JSON parser with automatic repair for LLM output issues
      const translatedContent = safeParseJSON(textContent);

      return translatedContent;
    } catch (error: any) {
      lastError = error;
      const isRetryable = error.message?.includes('fetch failed') || 
                          error.message?.includes('ECONNRESET') ||
                          error.message?.includes('timeout') ||
                          error.message?.includes('network');
      
      if (!isRetryable || attempt === MAX_RETRIES) {
        throw error;
      }
      console.log(`      ⚠️ Transient error: ${error.message}`);
    }
  }
  
  throw lastError || new Error('Translation failed after retries');
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
  // CRITICAL: Re-fetch current card hash before saving via stored procedure
  // This ensures we save with the EXACT current hash, preventing "outdated" status
  const { data: freshCardHash } = await supabaseAdmin.rpc(
    'get_card_content_hash_server',
    { p_card_id: cardId }
  );

  // Update card translations with fresh hash
  if (Object.keys(cardTranslations).length > 0) {
    // Update each language's translation with the FRESH hash
    const updatedCardTranslations: Record<string, any> = {};
    for (const [lang, trans] of Object.entries(cardTranslations)) {
      updatedCardTranslations[lang] = {
        ...trans,
        content_hash: freshCardHash || trans.content_hash,
      };
    }

    const finalTranslations = { ...cardData.translations, ...updatedCardTranslations };
    
    await supabaseAdmin.rpc('update_card_translations_server', {
      p_card_id: cardId,
      p_translations: finalTranslations
    });
  }

  // Save content item translations with fresh hashes
  for (const [itemId, translations] of Object.entries(contentItemsTranslations)) {
    // Re-fetch current content_hash for this item via stored procedure
    const { data: freshItemRows } = await supabaseAdmin.rpc(
      'get_content_item_for_update_server',
      { p_item_id: itemId }
    );
    
    const freshItemData = freshItemRows?.[0];

    // Update each language's translation with the FRESH hash
    const updatedItemTranslations: Record<string, any> = {};
    for (const [lang, trans] of Object.entries(translations)) {
      updatedItemTranslations[lang] = {
        ...trans,
        content_hash: freshItemData?.content_hash || trans.content_hash,
      };
    }

    const finalTranslations = { ...freshItemData?.translations, ...updatedItemTranslations };
    
    await supabaseAdmin.rpc('update_content_item_translations_server', {
      p_item_id: itemId,
      p_translations: finalTranslations
    });
  }
}

export default router;


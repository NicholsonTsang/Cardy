// =================================================================
// TRANSLATE CARD CONTENT EDGE FUNCTION
// =================================================================
// AI-powered translation of card content using GPT-4
// Cost: 1 credit per language per card
// Supported languages: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th
// =================================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { corsHeaders } from '../_shared/cors.ts';

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

// Translation request type
interface TranslationRequest {
  cardId: string;
  targetLanguages: LanguageCode[];
  forceRetranslate?: boolean;
}

// Card data structure
interface CardData {
  id: string;
  name: string;
  description: string;
  content_hash: string;
  translations: Record<string, any>;
}

interface ContentItemData {
  id: string;
  name: string;
  content: string;
  content_hash: string;
  translations: Record<string, any>;
}

// Translation response from GPT
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

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get environment variables
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!;

    // Create Supabase admin client
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get JWT token from Authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing Authorization header');
    }

    const token = authHeader.replace('Bearer ', '');

    // Validate user authentication
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
    
    if (authError || !user) {
      throw new Error('Unauthorized: Invalid or expired token');
    }

    // Parse request body
    const { cardId, targetLanguages, forceRetranslate = false }: TranslationRequest = await req.json();

    // Validate request
    if (!cardId || !targetLanguages || targetLanguages.length === 0) {
      throw new Error('Missing required fields: cardId, targetLanguages');
    }

    // Validate languages
    for (const lang of targetLanguages) {
      if (!(lang in SUPPORTED_LANGUAGES)) {
        throw new Error(`Unsupported language: ${lang}`);
      }
    }

    // Fetch card data
    const { data: cardData, error: cardError } = await supabaseAdmin
      .from('cards')
      .select('id, name, description, content_hash, translations, user_id, original_language')
      .eq('id', cardId)
      .single();

    if (cardError || !cardData) {
      throw new Error('Card not found');
    }

    // Verify ownership
    if (cardData.user_id !== user.id) {
      throw new Error('Unauthorized: Card does not belong to user');
    }

    // Fetch content items
    const { data: contentItems, error: itemsError } = await supabaseAdmin
      .from('content_items')
      .select('id, name, content, content_hash, translations')
      .eq('card_id', cardId)
      .order('sort_order');

    if (itemsError) {
      throw new Error(`Failed to fetch content items: ${itemsError.message}`);
    }

    // Estimate token count (rough approximation: 1 token ≈ 0.75 words)
    const estimateTokens = (text: string) => Math.ceil(text.length / 4);
    
    const cardTokens = estimateTokens(cardData.name + cardData.description);
    const itemsTokens = contentItems?.reduce((sum, item) => 
      sum + estimateTokens(item.name + item.content), 0) || 0;
    const totalInputTokens = cardTokens + itemsTokens;
    const estimatedOutputTokens = totalInputTokens * 1.2; // Translation often slightly longer

    // Check if content is too large
    const MAX_INPUT_TOKENS = 60000; // Conservative limit (half of 128k context)
    const MAX_OUTPUT_TOKENS = 16000; // GPT-4o supports up to 16k output tokens
    
    if (totalInputTokens > MAX_INPUT_TOKENS) {
      throw new Error(
        `Content too large for translation (${totalInputTokens} tokens). ` +
        `Maximum supported: ${MAX_INPUT_TOKENS} tokens. ` +
        `Consider reducing content or translating in multiple sessions.`
      );
    }

    if (estimatedOutputTokens > MAX_OUTPUT_TOKENS) {
      console.warn(`Large translation detected: ${estimatedOutputTokens} estimated output tokens`);
    }

    // Filter languages that need translation (skip up-to-date unless force retranslate)
    console.log('=== TRANSLATION FILTER DEBUG ===');
    console.log('Target languages requested:', targetLanguages);
    console.log('Force retranslate:', forceRetranslate);
    console.log('Card current hash:', cardData.content_hash);
    console.log('Card translations:', cardData.translations);
    console.log('Content items count:', contentItems?.length || 0);
    
    const languagesToTranslate = targetLanguages.filter(targetLang => {
      console.log(`\n--- Checking language: ${targetLang} ---`);
      
      if (forceRetranslate) {
        console.log(`${targetLang}: INCLUDE (forceRetranslate=true)`);
        return true;
      }
      
      // Check if card translation exists
      if (!cardData.translations || !cardData.translations[targetLang]) {
        console.log(`${targetLang}: INCLUDE (no existing card translation)`);
        return true;
      }
      
      // Check card-level hash
      const cardExistingHash = cardData.translations[targetLang].content_hash;
      console.log(`${targetLang}: Card has existing translation`);
      console.log(`${targetLang}: Card stored hash = ${cardExistingHash}`);
      console.log(`${targetLang}: Card current hash = ${cardData.content_hash}`);
      
      const cardHashMatches = cardExistingHash === cardData.content_hash;
      console.log(`${targetLang}: Card hashes match? ${cardHashMatches}`);
      
      if (!cardHashMatches) {
        console.log(`${targetLang}: INCLUDE (card outdated - hash mismatch)`);
        return true;
      }
      
      // Check content items - ALL items must be up-to-date
      if (contentItems && contentItems.length > 0) {
        const outdatedItems = contentItems.filter(item => {
          // Check if this item has translation for this language
          if (!item.translations || !item.translations[targetLang]) {
            return true; // Missing translation = outdated
          }
          
          const itemStoredHash = item.translations[targetLang].content_hash;
          const itemCurrentHash = item.content_hash;
          const itemHashMatches = itemStoredHash === itemCurrentHash;
          
          if (!itemHashMatches) {
            console.log(`${targetLang}: Content item ${item.id} outdated (${itemStoredHash} != ${itemCurrentHash})`);
          }
          
          return !itemHashMatches; // Return true if outdated
        });
        
        if (outdatedItems.length > 0) {
          console.log(`${targetLang}: INCLUDE (${outdatedItems.length} content item(s) outdated or missing translation)`);
          return true;
        }
      }
      
      // Both card and all content items are up-to-date
      console.log(`${targetLang}: SKIP (fully up-to-date - card and all content items match)`);
      return false;
    });
    
    console.log('\n=== FILTER RESULT ===');
    console.log('Languages to translate:', languagesToTranslate);
    console.log('Count:', languagesToTranslate.length);
    console.log('=== END DEBUG ===\n');

    // If no languages need translation, return early
    if (languagesToTranslate.length === 0) {
      console.log('All selected languages are already up-to-date');
      return new Response(
        JSON.stringify({
          success: true,
          message: 'All selected languages are already up-to-date',
          translated_languages: [],
          credits_used: 0,
          remaining_balance: 0,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      );
    }

    console.log(`Translating ${languagesToTranslate.length} languages in parallel...`);

    // Calculate credit cost (1 credit per language that needs translation)
    const creditCost = languagesToTranslate.length;

    // Check if user has sufficient credits (via stored procedure)
    const { data: balanceCheck, error: balanceError } = await supabaseAdmin.rpc(
      'check_credit_balance',
      { p_required_credits: creditCost, p_user_id: user.id }
    );

    if (balanceError) {
      throw new Error(`Credit check failed: ${balanceError.message}`);
    }

    if (balanceCheck < creditCost) {
      throw new Error(`Insufficient credits. Required: ${creditCost}, Available: ${balanceCheck}`);
    }

    // Prepare translations object
    const cardTranslations: Record<string, any> = {};
    const contentItemsTranslations: Record<string, any> = {};

    // Translate all languages in parallel using Promise.all
    const translationPromises = languagesToTranslate.map(async (targetLang) => {
      console.log(`Starting translation to ${SUPPORTED_LANGUAGES[targetLang]}...`);

      // Call GPT-4-nano for translation with retry mechanism
      const translationResponse = await retryWithBackoff(
        () => translateWithGPT4(
          {
            card: {
              name: cardData.name,
              description: cardData.description,
            },
            contentItems: contentItems || [],
          },
          cardData.original_language || 'en',
          targetLang,
          OPENAI_API_KEY
        ),
        3, // Max 3 retries
        1000 // Start with 1s delay (then 2s, then 4s)
      );

      console.log(`Completed translation to ${SUPPORTED_LANGUAGES[targetLang]}`);
      
      return { targetLang, translationResponse };
    });

    // Wait for all translations to complete
    const translationResults = await Promise.all(translationPromises);

    // Process all translation results
    for (const { targetLang, translationResponse } of translationResults) {
      // Store card translation
      cardTranslations[targetLang] = {
        name: translationResponse.card.name,
        description: translationResponse.card.description,
        translated_at: new Date().toISOString(),
        content_hash: cardData.content_hash,
      };

      // Store content items translations
      for (const item of translationResponse.contentItems) {
        if (!contentItemsTranslations[item.id]) {
          contentItemsTranslations[item.id] = {};
        }

        // Find original item to get content_hash
        const originalItem = contentItems?.find(ci => ci.id === item.id);
        
        contentItemsTranslations[item.id][targetLang] = {
          name: item.name,
          content: item.content,
          translated_at: new Date().toISOString(),
          content_hash: originalItem?.content_hash || '',
        };
      }
    }

    // Store translations via stored procedure
    // Only pass languages that were actually translated
    const { data: result, error: storeError } = await supabaseAdmin.rpc(
      'store_card_translations',
      {
        p_user_id: user.id,
        p_card_id: cardId,
        p_target_languages: languagesToTranslate, // Use filtered list, not all selected languages
        p_card_translations: cardTranslations,
        p_content_items_translations: contentItemsTranslations,
        p_credit_cost: languagesToTranslate.length, // Charge only for languages actually translated
      }
    );

    if (storeError) {
      throw new Error(`Failed to store translations: ${storeError.message}`);
    }

    // Return success response
    return new Response(
      JSON.stringify(result),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );

  } catch (error) {
    console.error('Translation error:', error);
    return new Response(
      JSON.stringify({
        error: error.message || 'Translation failed',
        details: error.toString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});

// =================================================================
// Helper function: Retry with exponential backoff
// =================================================================
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
      
      // Don't retry on certain errors
      if (error.message.includes('Unauthorized') || 
          error.message.includes('Content too large') ||
          error.message.includes('Insufficient credits')) {
        throw error;
      }
      
      // If this is the last attempt, throw the error
      if (attempt === maxRetries - 1) {
        break;
      }
      
      // Calculate delay with exponential backoff
      const delay = baseDelay * Math.pow(2, attempt);
      console.log(`Attempt ${attempt + 1} failed: ${error.message}. Retrying in ${delay}ms...`);
      
      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw new Error(`Operation failed after ${maxRetries} attempts: ${lastError.message}`);
}

// =================================================================
// Helper function: Translate with GPT-5-nano
// =================================================================
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

  // Build system prompt
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

  // Build user prompt with data
  const userPrompt = `Translate the following card content from ${sourceLanguageName} to ${targetLanguageName}:

CARD:
Name: ${data.card.name}
Description: ${data.card.description}

CONTENT ITEMS (${data.contentItems.length} items):
${data.contentItems.map((item, idx) => `
Item ${idx + 1} (ID: ${item.id}):
- Name: ${item.name}
- Content: ${item.content}
`).join('\n')}

Remember: Return ONLY the JSON object, no markdown code blocks or explanations.`;

  // Calculate dynamic max_tokens based on content size
  const estimateInputTokens = (systemPrompt.length + userPrompt.length) / 4;
  const estimatedOutputTokens = Math.ceil(estimateInputTokens * 1.2);
  const maxTokens = Math.min(16000, Math.max(4000, estimatedOutputTokens)); // Between 4k-16k

  console.log(`Translation tokens - Input: ~${Math.ceil(estimateInputTokens)}, Output: ~${maxTokens}`);

  // Call OpenAI API
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4.1-nano-2025-04-14', // Use GPT-4.1-nano for efficient, high-quality translation
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.3, // Lower temperature for consistent translations
      max_tokens: maxTokens, // Dynamic based on content size (4k-16k)
    }),
  });

  if (!response.ok) {
    const errorData = await response.text();
    throw new Error(`OpenAI API error: ${response.statusText} - ${errorData}`);
  }

  const result = await response.json();
  
  // Validate response structure
  if (!result.choices || result.choices.length === 0) {
    console.error('Invalid OpenAI response structure:', JSON.stringify(result).substring(0, 500));
    throw new Error('OpenAI returned an empty or invalid response');
  }

  const translatedContent = result.choices[0].message?.content;
  const finishReason = result.choices[0].finish_reason;
  
  // Check if content is empty or null
  if (!translatedContent || translatedContent.trim().length === 0) {
    console.error('Empty translation content from OpenAI. Full response:', JSON.stringify(result));
    throw new Error('OpenAI returned empty translation content. This may indicate the content is too large or the model encountered an error.');
  }

  // Check if response was truncated
  if (finishReason === 'length') {
    console.warn('Translation was truncated due to max_completion_tokens limit. Increase limit or reduce content size.');
    throw new Error(
      'Translation response was truncated because it exceeded the token limit. ' +
      'Your card content may be too large. Consider reducing the content or splitting into multiple cards.'
    );
  }

  console.log('Translation response - Length:', translatedContent.length, 'chars, Finish reason:', finishReason);

  // Parse JSON response (handle potential markdown code blocks)
  let translationData: TranslationResponse;
  try {
    // Aggressive cleanup of common formatting issues
    let cleanedContent = translatedContent
      .replace(/```json\s*/gi, '') // Remove ```json
      .replace(/```\s*/g, '')       // Remove ```
      .replace(/^[^{]*/g, '')       // Remove anything before first {
      .replace(/[^}]*$/g, '')       // Remove anything after last }
      .trim();
    
    // Try to extract JSON if embedded in text
    const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      cleanedContent = jsonMatch[0];
    }
    
    translationData = JSON.parse(cleanedContent);
  } catch (parseError) {
    console.error('Failed to parse GPT-5-nano response:', translatedContent.substring(0, 500));
    throw new Error(
      `Failed to parse translation response: ${parseError.message}. ` +
      `Response preview: ${translatedContent.substring(0, 200)}...`
    );
  }

  // Validate response structure
  if (!translationData.card || !translationData.contentItems) {
    console.error('Invalid response structure:', JSON.stringify(translationData).substring(0, 500));
    throw new Error(
      'Invalid translation response structure. Missing card or contentItems. ' +
      `Keys found: ${Object.keys(translationData).join(', ')}`
    );
  }

  // Validate required fields
  if (!translationData.card.name || !translationData.card.description) {
    throw new Error('Invalid card translation: missing name or description');
  }

  if (!Array.isArray(translationData.contentItems)) {
    throw new Error('Invalid contentItems: expected an array');
  }

  return translationData;
}


import { Router, Request, Response } from 'express';
import { authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';

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
    const cardTranslations: Record<string, any> = {};
    const contentItemsTranslations: Record<string, any> = {};

    // Translate all languages in parallel
    console.log(`🚀 Starting parallel translation for ${languagesToTranslate.length} languages...`);
    
    const translationPromises = languagesToTranslate.map(async (targetLang) => {
      console.log(`📝 Translating to ${SUPPORTED_LANGUAGES[targetLang]}...`);

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
        3,
        1000
      );

      console.log(`✅ Completed translation to ${SUPPORTED_LANGUAGES[targetLang]}`);
      return { targetLang, translationResponse };
    });

    const translationResults = await Promise.all(translationPromises);

    // Process results
    for (const { targetLang, translationResponse } of translationResults) {
      cardTranslations[targetLang] = {
        name: translationResponse.card.name,
        description: translationResponse.card.description,
        translated_at: new Date().toISOString(),
        content_hash: cardData.content_hash,
      };

      for (const item of translationResponse.contentItems) {
        if (!contentItemsTranslations[item.id]) {
          contentItemsTranslations[item.id] = {};
        }

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
    const { data: result, error: storeError } = await supabaseAdmin.rpc(
      'store_card_translations',
      {
        p_user_id: userId,
        p_card_id: cardId,
        p_target_languages: languagesToTranslate,
        p_card_translations: cardTranslations,
        p_content_items_translations: contentItemsTranslations,
        p_credit_cost: languagesToTranslate.length,
      }
    );

    if (storeError) {
      return res.status(500).json({
        error: 'Database error',
        message: `Failed to store translations: ${storeError.message}`
      });
    }

    const duration = Date.now() - startTime;
    console.log(`✅ Translation completed in ${duration}ms`);

    return res.status(200).json(result);

  } catch (error: any) {
    console.error('❌ Translation error:', error);
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

  const estimateInputTokens = (systemPrompt.length + userPrompt.length) / 4;
  const estimatedOutputTokens = Math.ceil(estimateInputTokens * 1.2);
  const maxTokens = Math.min(16000, Math.max(4000, estimatedOutputTokens));

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4.1-nano-2025-04-14',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.3,
      max_tokens: maxTokens,
    }),
  });

  if (!response.ok) {
    const errorData = await response.text();
    throw new Error(`OpenAI API error: ${response.statusText} - ${errorData}`);
  }

  const result = await response.json() as any;
  
  if (!result.choices || result.choices.length === 0) {
    throw new Error('OpenAI returned an empty response');
  }

  const translatedContent = result.choices[0].message?.content;
  const finishReason = result.choices[0].finish_reason;
  
  if (!translatedContent || translatedContent.trim().length === 0) {
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

  if (!translationData.card.name || !translationData.card.description) {
    throw new Error('Invalid card translation: missing name or description');
  }

  if (!Array.isArray(translationData.contentItems)) {
    throw new Error('Invalid contentItems: expected an array');
  }

  return translationData;
}

export default router;


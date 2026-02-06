import { Router, Request, Response } from 'express';
import { optionalAuth, authenticateUser } from '../middleware/auth';
import { supabaseAdmin } from '../config/supabase';

const router = Router();

/**
 * POST /api/ai/chat/stream
 * Stream AI chat responses using SSE
 * Optional authentication (works for both public and authenticated users)
 */
router.post('/chat/stream', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { messages, systemPrompt, systemInstructions, language } = req.body;

    console.log('📝 Streaming chat request:', {
      messageCount: messages?.length || 0,
      language,
      hasSystemPrompt: !!(systemPrompt || systemInstructions),
      authenticated: !!req.user
    });

    // Validate messages
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Messages array is required and must not be empty'
      });
    }

    // Filter valid messages
    const validMessages = messages.filter(m => m && m.content != null && m.content !== '');
    if (validMessages.length === 0) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'No valid messages with content found'
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

    // Build messages with system prompt
    // OPTIMIZATION: OpenAI automatically caches static system prompts for cost reduction
    // To maximize caching benefits:
    // 1. System prompt should be consistent across requests for the same card
    // 2. System prompt should be placed first in the messages array
    // 3. Frontend should avoid regenerating prompts unnecessarily
    // With caching: ~40% cost reduction on repeated system prompts (after 1st message)
    const systemMessage = systemPrompt || systemInstructions || 'You are a helpful assistant.';
    const fullMessages = [
      { role: 'system', content: systemMessage },
      ...validMessages
    ];

    // Call OpenAI streaming API with prompt caching
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_TEXT_MODEL || 'gpt-4o-mini',
        messages: fullMessages,
        max_tokens: parseInt(process.env.OPENAI_MAX_TOKENS || '3500'),
        temperature: 0.7,
        stream: true,
        // OpenAI automatically applies prompt caching to repeated content
        // No explicit parameter needed - caching happens server-side
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ OpenAI API error:', errorText);
      return res.status(response.status).json({
        error: 'OpenAI API error',
        message: errorText
      });
    }

    // Set up SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    // Stream the response
    const reader = response.body?.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    if (!reader) {
      return res.status(500).json({ error: 'Failed to get response stream' });
    }

    try {
      while (true) {
        const { done, value } = await reader.read();

        if (done) {
          res.write('data: [DONE]\n\n');
          res.end();
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);

            if (data === '[DONE]') continue;

            try {
              const parsed = JSON.parse(data);
              const content = parsed.choices[0]?.delta?.content;

              if (content) {
                const event = `data: ${JSON.stringify({ content })}\n\n`;
                res.write(event);
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }
    } catch (streamError) {
      console.error('❌ Stream error:', streamError);
      res.end();
    }
    return;

  } catch (error: any) {
    console.error('❌ Chat stream error:', error);
    if (!res.headersSent) {
      return res.status(500).json({
        error: 'Internal server error',
        message: error.message
      });
    }
    // Headers already sent, can't send error response
    return;
  }
});

/**
 * POST /api/ai/generate-tts
 * Generate audio from text using OpenAI TTS
 * Optional authentication
 */
router.post('/generate-tts', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { text, voice, language } = req.body;

    if (!text || typeof text !== 'string') {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Text is required and must be a string'
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

    // Get TTS configuration
    const ttsModel = process.env.OPENAI_TTS_MODEL || 'tts-1';
    const ttsVoice = voice || process.env.OPENAI_TTS_VOICE || 'alloy';
    const ttsFormat = process.env.OPENAI_AUDIO_FORMAT || 'wav';

    console.log('🔊 Generating TTS audio:', {
      textLength: text.length,
      model: ttsModel,
      voice: ttsVoice,
      format: ttsFormat,
      language: language || 'auto',
      authenticated: !!req.user
    });

    // Call OpenAI TTS API
    const ttsResponse = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: ttsModel,
        voice: ttsVoice,
        input: text,
        response_format: ttsFormat,
      }),
    });

    if (!ttsResponse.ok) {
      const errorText = await ttsResponse.text();
      console.error('❌ OpenAI TTS API error:', errorText);
      return res.status(ttsResponse.status).json({
        error: 'TTS generation failed',
        message: errorText
      });
    }

    // Get audio data
    const audioData = await ttsResponse.arrayBuffer();

    console.log(`✅ TTS audio generated: ${audioData.byteLength} bytes`);

    // Return audio
    res.setHeader('Content-Type', `audio/${ttsFormat}`);
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.send(Buffer.from(audioData));
    return;

  } catch (error: any) {
    console.error('❌ TTS generation error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * POST /api/ai/realtime-token
 * Generate ephemeral token for OpenAI Realtime API
 * Optional authentication
 */
router.post('/realtime-token', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { sessionConfig } = req.body;

    // Get OpenAI API key
    const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
    if (!OPENAI_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'OpenAI API key not configured'
      });
    }

    // Get Realtime model
    const REALTIME_MODEL = process.env.OPENAI_REALTIME_MODEL || 'gpt-realtime-mini-2025-12-15';

    console.log('🎤 Generating ephemeral token:', {
      model: REALTIME_MODEL,
      voice: sessionConfig?.voice || 'alloy',
      authenticated: !!req.user
    });

    // Create ephemeral token
    const response = await fetch('https://api.openai.com/v1/realtime/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: REALTIME_MODEL,
        voice: sessionConfig?.voice || 'alloy',
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('❌ OpenAI API error:', error);
      return res.status(response.status).json({
        error: 'Failed to generate ephemeral token',
        message: error
      });
    }

    const data = await response.json() as any;

    console.log('✅ Ephemeral token generated');

    return res.status(200).json({
      success: true,
      client_secret: data.client_secret.value,
      expires_at: data.client_secret.expires_at,
    });

  } catch (error: any) {
    console.error('❌ Error generating ephemeral token:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

/**
 * POST /api/ai/generate-ai-settings
 * Generate AI configuration fields (instruction, knowledge base, welcome messages)
 * using OpenAI based on card context and content items
 * Requires authentication (creator tool)
 */
router.post('/generate-ai-settings', authenticateUser, async (req: Request, res: Response) => {
  try {
    const {
      cardId,
      cardName,
      cardDescription,
      originalLanguage,
      contentMode,
      isGrouped,
      billingType
    } = req.body;

    if (!cardName || typeof cardName !== 'string' || !cardName.trim()) {
      return res.status(400).json({
        error: 'Validation error',
        message: 'Card name is required'
      });
    }

    const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
    if (!OPENAI_API_KEY) {
      return res.status(500).json({
        error: 'Configuration error',
        message: 'OpenAI API key not configured'
      });
    }

    // Fetch content items for richer context (edit mode only)
    let contentItemsContext = '';
    if (cardId) {
      try {
        const { data: contentItems } = await supabaseAdmin.rpc(
          'get_content_items_server',
          { p_card_id: cardId }
        );
        if (contentItems && contentItems.length > 0) {
          const itemsSummary = contentItems
            .slice(0, 20)
            .map((item: any) => {
              const content = item.content ? item.content.substring(0, 200) : '';
              const knowledge = item.ai_knowledge_base
                ? ` [Knowledge: ${item.ai_knowledge_base.substring(0, 100)}]`
                : '';
              return `- ${item.name}${content ? ': ' + content : ''}${knowledge}`;
            })
            .join('\n');
          contentItemsContext = `\n\nContent Items (${contentItems.length} total):\n${itemsSummary}`;
        }
      } catch (err) {
        console.warn('Failed to fetch content items for AI generation:', err);
      }
    }

    const LANGUAGE_NAMES: Record<string, string> = {
      'en': 'English', 'zh-Hant': 'Traditional Chinese',
      'zh-Hans': 'Simplified Chinese', 'ja': 'Japanese',
      'ko': 'Korean', 'es': 'Spanish', 'fr': 'French',
      'ru': 'Russian', 'ar': 'Arabic', 'th': 'Thai'
    };
    const langName = LANGUAGE_NAMES[originalLanguage] || 'English';

    const systemPrompt = `You are an expert at configuring AI assistants for digital interactive experiences (museums, restaurants, events, exhibitions, tourist attractions, etc.).

Given information about a venue/experience project, generate optimal AI assistant configuration.

You MUST respond with a JSON object containing exactly these 4 string fields:
- "ai_instruction": Role and personality instructions for the AI assistant (max 80 words). Define the AI's persona, tone, and behavioral guidelines specific to this venue/experience.
- "ai_knowledge_base": Comprehensive knowledge base (max 1500 words). Include relevant facts, history, context, and domain expertise that helps the AI answer visitor questions accurately. Be specific and practical, not generic.
- "ai_welcome_general": Welcome message for the general assistant (max 80 words). A warm greeting introducing what the AI can help with. Natural and conversational.
- "ai_welcome_item": Welcome message for the item-specific assistant (max 80 words). Use {name} as a placeholder for the content item name. Should feel focused and expert-like.

IMPORTANT:
- Write ALL content in ${langName}
- Tailor everything to the specific type of venue/experience described
- If content items are provided, use them to infer the domain and generate highly relevant knowledge
- Knowledge base should contain practical, factual information, not generic filler text
- Welcome messages should be concise for voice delivery`;

    const userPrompt = `Project Name: ${cardName}
${cardDescription ? `Description: ${cardDescription}` : ''}
Original Language: ${langName}
Content Display Mode: ${contentMode || 'list'}
Content Structure: ${isGrouped ? 'Grouped into categories' : 'Flat list'}
Access Type: ${billingType || 'digital'}${contentItemsContext}`;

    console.log('🤖 Generating AI settings:', {
      cardName,
      hasCardId: !!cardId,
      language: originalLanguage,
      hasContentItems: !!contentItemsContext
    });

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_TEXT_MODEL || 'gpt-4o-mini',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        max_tokens: parseInt(process.env.OPENAI_MAX_TOKENS || '3500'),
        temperature: 0.7,
        response_format: { type: 'json_object' }
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ OpenAI API error:', errorText);
      return res.status(response.status).json({
        error: 'OpenAI API error',
        message: 'Failed to generate AI settings'
      });
    }

    const completion = await response.json() as any;
    const content = completion.choices?.[0]?.message?.content;

    if (!content) {
      return res.status(500).json({
        error: 'Generation error',
        message: 'No content returned from AI'
      });
    }

    const generated = JSON.parse(content);

    const result = {
      ai_instruction: typeof generated.ai_instruction === 'string' ? generated.ai_instruction : '',
      ai_knowledge_base: typeof generated.ai_knowledge_base === 'string' ? generated.ai_knowledge_base : '',
      ai_welcome_general: typeof generated.ai_welcome_general === 'string' ? generated.ai_welcome_general : '',
      ai_welcome_item: typeof generated.ai_welcome_item === 'string' ? generated.ai_welcome_item : '',
    };

    console.log('✅ AI settings generated successfully');

    return res.json({ success: true, data: result });

  } catch (error: any) {
    console.error('❌ AI generation error:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message || 'Failed to generate AI settings'
    });
  }
});

export default router;


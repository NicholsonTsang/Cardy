/**
 * Google Gemini API Client with OAuth2 Authentication
 * Uses Google service account for server-side authentication
 */

import { GoogleAuth } from 'google-auth-library';

export class GeminiClient {
  private auth: GoogleAuth;
  private accessToken: string | null = null;
  private tokenExpiry: number = 0;

  constructor() {
    // Initialize Google Auth with service account from GOOGLE_APPLICATION_CREDENTIALS
    // or Application Default Credentials
    this.auth = new GoogleAuth({
      scopes: [
        'https://www.googleapis.com/auth/generative-language',
        'https://www.googleapis.com/auth/cloud-platform',
      ],
      // Will automatically use GOOGLE_APPLICATION_CREDENTIALS env var if set
    });
  }

  /**
   * Get access token (with caching)
   */
  private async getAccessToken(): Promise<string> {
    // Return cached token if still valid
    if (this.accessToken && Date.now() < this.tokenExpiry) {
      return this.accessToken;
    }

    // Get new access token
    const client = await this.auth.getClient();
    const tokenResponse = await client.getAccessToken();
    
    if (!tokenResponse.token) {
      throw new Error('Failed to get access token from Google Auth');
    }

    this.accessToken = tokenResponse.token;
    // Set expiry to 5 minutes before actual expiry for safety
    this.tokenExpiry = Date.now() + (55 * 60 * 1000);

    return this.accessToken;
  }

  /**
   * Call Gemini API with OAuth2 authentication
   */
  async generateContent(prompt: string, config: {
    model?: string;
    temperature?: number;
    maxOutputTokens?: number;
  } = {}): Promise<any> {
    const model = config.model || process.env.GEMINI_TRANSLATION_MODEL || 'gemini-2.5-flash-lite';
    const temperature = config.temperature ?? parseFloat(process.env.GEMINI_TRANSLATION_TEMPERATURE || '0.3');
    const maxOutputTokens = config.maxOutputTokens ?? parseInt(process.env.GEMINI_TRANSLATION_MAX_TOKENS || '8192');

    // Use OAuth2 with service account
    return await this.generateContentWithOAuth(prompt, { model, temperature, maxOutputTokens });
  }

  /**
   * Call Gemini API using OAuth2 access token
   */
  private async generateContentWithOAuth(prompt: string, config: {
    model: string;
    temperature: number;
    maxOutputTokens: number;
  }): Promise<any> {
    const accessToken = await this.getAccessToken();

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: prompt
            }]
          }],
          generationConfig: {
            temperature: config.temperature,
            maxOutputTokens: config.maxOutputTokens,
            responseMimeType: 'application/json',
          }
        }),
      }
    );

    if (!response.ok) {
      const error = await response.json() as any;
      throw new Error(`Gemini API error: ${error.error?.message || response.statusText}`);
    }

    return await response.json();
  }
  /**
   * Stream Gemini API response using SSE (Server-Sent Events).
   * Used for text chat streaming to visitors.
   * Returns the raw Response so the caller can read the stream.
   */
  async streamGenerateContent(
    systemInstruction: string,
    contents: Array<{ role: 'user' | 'model'; parts: Array<{ text: string }> }>,
    config: {
      model?: string;
      temperature?: number;
      maxOutputTokens?: number;
    } = {}
  ): Promise<Response> {
    const model = config.model || process.env.GEMINI_CHAT_MODEL || 'gemini-2.5-flash-lite';
    const temperature = config.temperature ?? parseFloat(process.env.GEMINI_CHAT_TEMPERATURE || '0.7');
    const maxOutputTokens = config.maxOutputTokens ?? parseInt(process.env.GEMINI_CHAT_MAX_TOKENS || '3500');

    const accessToken = await this.getAccessToken();

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?alt=sse`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          system_instruction: {
            parts: [{ text: systemInstruction }]
          },
          contents,
          generationConfig: {
            temperature,
            maxOutputTokens,
          }
        }),
      }
    );

    if (!response.ok) {
      const error = await response.json() as any;
      throw new Error(`Gemini API error: ${error.error?.message || response.statusText}`);
    }

    return response;
  }
}

// Export singleton instance
export const geminiClient = new GeminiClient();


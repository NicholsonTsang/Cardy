    // =================================================================
// TRANSLATION STORE
// Manages AI-powered multi-language translations
// =================================================================

import { defineStore } from 'pinia';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from './auth';

export interface TranslationStatus {
  language: string;
  language_name: string;
  status: 'original' | 'up_to_date' | 'outdated' | 'not_translated';
  translated_at: string | null;
  needs_update: boolean;
  content_fields_count: number;
}

export interface TranslationHistory {
  id: string;
  card_id: string;
  target_languages: string[];
  credit_cost: number;
  translated_by: string;
  translator_email: string;
  translated_at: string;
  status: string;
  error_message: string | null;
  metadata: any;
}

export interface TranslateCardResponse {
  success: boolean;
  card_id: string;
  translated_languages: string[];
  credits_used: number;
  remaining_balance: number;
  translation_history_id: string;
}

export const SUPPORTED_LANGUAGES = {
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

export type LanguageCode = keyof typeof SUPPORTED_LANGUAGES;

export const useTranslationStore = defineStore('translation', {
  state: () => ({
    translationStatus: {} as Record<string, TranslationStatus>,
    translationHistory: [] as TranslationHistory[],
    isTranslating: false,
    translationProgress: 0,
    translationError: null as string | null,
    currentCardId: null as string | null,
  }),

  getters: {
    /**
     * Get list of languages that need translation (not translated yet)
     */
    untranslatedLanguages(): TranslationStatus[] {
      return Object.values(this.translationStatus).filter(
        (status) => status.status === 'not_translated'
      );
    },

    /**
     * Get list of languages with outdated translations
     */
    outdatedLanguages(): TranslationStatus[] {
      return Object.values(this.translationStatus).filter(
        (status) => status.status === 'outdated'
      );
    },

    /**
     * Get list of languages with up-to-date translations
     */
    upToDateLanguages(): TranslationStatus[] {
      return Object.values(this.translationStatus).filter(
        (status) => status.status === 'up_to_date'
      );
    },

    /**
     * Get the original language of the card
     */
    originalLanguage(): TranslationStatus | undefined {
      return Object.values(this.translationStatus).find(
        (status) => status.status === 'original'
      );
    },

    /**
     * Count of translated languages (excluding original)
     */
    translatedCount(): number {
      return this.upToDateLanguages.length + this.outdatedLanguages.length;
    },

    /**
     * Total supported languages count
     */
    totalLanguagesCount(): number {
      return Object.keys(SUPPORTED_LANGUAGES).length;
    },
  },

  actions: {
    /**
     * Fetch translation status for a specific card
     */
    async fetchTranslationStatus(cardId: string) {
      try {
        this.currentCardId = cardId;
        this.translationError = null;

        const { data, error } = await supabase.rpc('get_card_translation_status', {
          p_card_id: cardId,
        });

        if (error) {
          console.error('Error fetching translation status:', error);
          this.translationError = error.message;
          throw error;
        }

        // Convert array to object keyed by language
        this.translationStatus = (data as TranslationStatus[]).reduce(
          (acc, item) => {
            acc[item.language] = item;
            return acc;
          },
          {} as Record<string, TranslationStatus>
        );

        return data;
      } catch (error: any) {
        console.error('Failed to fetch translation status:', error);
        this.translationError = error.message;
        throw error;
      }
    },

    /**
     * Translate card to selected languages
     */
    async translateCard(cardId: string, targetLanguages: LanguageCode[]) {
      this.isTranslating = true;
      this.translationProgress = 0;
      this.translationError = null;

      try {
        const authStore = useAuthStore();
        const session = authStore.session;

        if (!session) {
          throw new Error('No active session');
        }

        // Call Backend API
        const response = await fetch(
          `${import.meta.env.VITE_BACKEND_URL}/api/translations/translate-card`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${session.access_token}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              cardId,
              targetLanguages,
              forceRetranslate: false,
            }),
          }
        );

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.error || 'Translation failed');
        }

        const result: TranslateCardResponse = await response.json();

        // Refresh translation status
        await this.fetchTranslationStatus(cardId);

        this.translationProgress = 100;

        return result;
      } catch (error: any) {
        console.error('Translation error:', error);
        this.translationError = error.message;
        throw error;
      } finally {
        this.isTranslating = false;
      }
    },

    /**
     * Delete a specific language translation
     */
    async deleteTranslation(cardId: string, language: LanguageCode) {
      try {
        this.translationError = null;

        const { data, error } = await supabase.rpc('delete_card_translation', {
          p_card_id: cardId,
          p_language: language,
        });

        if (error) {
          console.error('Error deleting translation:', error);
          this.translationError = error.message;
          throw error;
        }

        // Refresh translation status
        await this.fetchTranslationStatus(cardId);

        return data;
      } catch (error: any) {
        console.error('Failed to delete translation:', error);
        this.translationError = error.message;
        throw error;
      }
    },

    /**
     * Fetch translation history for a card
     */
    async fetchTranslationHistory(cardId: string, limit = 50, offset = 0) {
      try {
        this.translationError = null;

        const { data, error } = await supabase.rpc('get_translation_history', {
          p_card_id: cardId,
          p_limit: limit,
          p_offset: offset,
        });

        if (error) {
          console.error('Error fetching translation history:', error);
          this.translationError = error.message;
          throw error;
        }

        this.translationHistory = data as TranslationHistory[];

        return data;
      } catch (error: any) {
        console.error('Failed to fetch translation history:', error);
        this.translationError = error.message;
        throw error;
      }
    },

    /**
     * Get full translations for a card (for preview/editing)
     */
    async getCardTranslations(cardId: string, language?: LanguageCode) {
      try {
        this.translationError = null;

        const { data, error } = await supabase.rpc('get_card_translations', {
          p_card_id: cardId,
          p_language: language || null,
        });

        if (error) {
          console.error('Error fetching card translations:', error);
          this.translationError = error.message;
          throw error;
        }

        return data;
      } catch (error: any) {
        console.error('Failed to fetch card translations:', error);
        this.translationError = error.message;
        throw error;
      }
    },

    /**
     * Get list of outdated translations
     */
    async getOutdatedTranslations(cardId: string) {
      try {
        this.translationError = null;

        const { data, error } = await supabase.rpc('get_outdated_translations', {
          p_card_id: cardId,
        });

        if (error) {
          console.error('Error fetching outdated translations:', error);
          this.translationError = error.message;
          throw error;
        }

        return data;
      } catch (error: any) {
        console.error('Failed to fetch outdated translations:', error);
        this.translationError = error.message;
        throw error;
      }
    },

    /**
     * Reset store state
     */
    reset() {
      this.translationStatus = {};
      this.translationHistory = [];
      this.isTranslating = false;
      this.translationProgress = 0;
      this.translationError = null;
      this.currentCardId = null;
    },
  },
});


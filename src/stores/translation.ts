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
  message: string;
  job_id?: string | null;  // Optional for backward compatibility
  status?: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled';
  languages?: string[];  // Optional for backward compatibility
  credits_reserved?: number;  // Optional for backward compatibility
  translated_languages: string[];  // Successfully translated languages
  failed_languages: string[];  // Failed translations
  credits_used: number;
  duration: number;
}

export interface TranslationJob {
  id: string;
  card_id: string;
  user_id: string;
  target_languages: string[];
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled';
  progress: Record<string, {
    status: 'pending' | 'processing' | 'completed' | 'failed';
    error?: string;
    batches_completed?: number;
    total_batches?: number;
    updated_at: string;
  }>;
  retry_count: number;
  max_retries: number;
  credit_reserved: number;
  credit_consumed: number;
  error_message: string | null;
  started_at: string | null;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
  metadata: any;
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
    // Job tracking
    activeJobs: {} as Record<string, TranslationJob>, // jobId -> Job
    pollingIntervals: {} as Record<string, number>, // jobId -> intervalId
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
     * Translate card to selected languages (creates background job)
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

        // Call Backend API to create translation job
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
          throw new Error(errorData.message || errorData.error || 'Translation failed');
        }

        const result: TranslateCardResponse = await response.json();

        // If job was created, start polling for status
        if (result.job_id) {
          await this.startPollingJob(result.job_id, cardId);
        } else {
          // No job created (e.g., all languages up-to-date)
        await this.fetchTranslationStatus(cardId);
          this.isTranslating = false;
        }

        return result;
      } catch (error: any) {
        console.error('Translation error:', error);
        this.translationError = error.message;
        this.isTranslating = false;
        throw error;
      }
    },

    /**
     * Get translation job status
     */
    async getTranslationJob(jobId: string): Promise<TranslationJob> {
      try {
        const authStore = useAuthStore();
        const session = authStore.session;

        if (!session) {
          throw new Error('No active session');
        }

        const response = await fetch(
          `${import.meta.env.VITE_BACKEND_URL}/api/translations/job/${jobId}`,
          {
            method: 'GET',
            headers: {
              'Authorization': `Bearer ${session.access_token}`,
            },
          }
        );

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.message || errorData.error || 'Failed to fetch job');
        }

        const result = await response.json();
        const job = result.job as TranslationJob;

        // Update active jobs
        this.activeJobs[jobId] = job;

        return job;
      } catch (error: any) {
        console.error('Error fetching translation job:', error);
        throw error;
      }
    },

    /**
     * Start polling for job status
     */
    async startPollingJob(jobId: string, cardId: string) {
      // Clear any existing polling interval for this job
      this.stopPollingJob(jobId);

      // Poll immediately
      await this.pollJobOnce(jobId, cardId);

      // Set up polling interval (every 5 seconds)
      const intervalId = window.setInterval(async () => {
        await this.pollJobOnce(jobId, cardId);
      }, 5000);

      this.pollingIntervals[jobId] = intervalId;
    },

    /**
     * Poll job status once
     */
    async pollJobOnce(jobId: string, cardId: string) {
      try {
        const job = await this.getTranslationJob(jobId);

        // Update progress
        if (job.status === 'processing' || job.status === 'pending') {
          // Calculate overall progress from language progress
          const languages = job.target_languages;
          const completedLanguages = Object.values(job.progress).filter(
            p => p.status === 'completed'
          ).length;
          this.translationProgress = Math.round((completedLanguages / languages.length) * 100);
        }

        // If job is complete, stop polling and refresh status
        if (job.status === 'completed' || job.status === 'failed' || job.status === 'cancelled') {
          this.stopPollingJob(jobId);
          await this.fetchTranslationStatus(cardId);
          this.isTranslating = false;
          this.translationProgress = 100;

          // Remove from active jobs after a delay
          setTimeout(() => {
            delete this.activeJobs[jobId];
          }, 5000);
        }
      } catch (error: any) {
        console.error('Error polling job:', error);
        // Stop polling on error
        this.stopPollingJob(jobId);
        this.isTranslating = false;
        this.translationError = error.message;
      }
    },

    /**
     * Stop polling for job status
     */
    stopPollingJob(jobId: string) {
      const intervalId = this.pollingIntervals[jobId];
      if (intervalId) {
        clearInterval(intervalId);
        delete this.pollingIntervals[jobId];
      }
    },

    /**
     * Retry failed job languages
     */
    async retryFailedJob(jobId: string): Promise<{ new_job_id: string }> {
      try {
        const authStore = useAuthStore();
        const session = authStore.session;

        if (!session) {
          throw new Error('No active session');
        }

        const response = await fetch(
          `${import.meta.env.VITE_BACKEND_URL}/api/translations/job/${jobId}/retry`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${session.access_token}`,
              'Content-Type': 'application/json',
            },
          }
        );

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.message || errorData.error || 'Failed to retry job');
        }

        const result = await response.json();
        
        // Start polling the new job
        const job = this.activeJobs[jobId];
        if (job) {
          await this.startPollingJob(result.new_job_id, job.card_id);
        }

        return result;
      } catch (error: any) {
        console.error('Error retrying job:', error);
        throw error;
      }
    },

    /**
     * Cancel a pending or processing job
     */
    async cancelJob(jobId: string, reason?: string) {
      try {
        const authStore = useAuthStore();
        const session = authStore.session;

        if (!session) {
          throw new Error('No active session');
        }

        const response = await fetch(
          `${import.meta.env.VITE_BACKEND_URL}/api/translations/job/${jobId}/cancel`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${session.access_token}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ reason }),
          }
        );

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.message || errorData.error || 'Failed to cancel job');
        }

        // Stop polling and update job
        this.stopPollingJob(jobId);
        await this.getTranslationJob(jobId);
        this.isTranslating = false;

        return await response.json();
      } catch (error: any) {
        console.error('Error cancelling job:', error);
        throw error;
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


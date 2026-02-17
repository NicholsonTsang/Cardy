import { SUPPORTED_LANGUAGES } from '@/stores/translation';

/**
 * Language flag emoji map
 */
const LANGUAGE_FLAGS: Record<string, string> = {
  en: '\u{1F1EC}\u{1F1E7}',
  'zh-Hant': '\u{1F1F9}\u{1F1FC}',
  'zh-Hans': '\u{1F1E8}\u{1F1F3}',
  ja: '\u{1F1EF}\u{1F1F5}',
  ko: '\u{1F1F0}\u{1F1F7}',
  es: '\u{1F1EA}\u{1F1F8}',
  fr: '\u{1F1EB}\u{1F1F7}',
  ru: '\u{1F1F7}\u{1F1FA}',
  ar: '\u{1F1F8}\u{1F1E6}',
  th: '\u{1F1F9}\u{1F1ED}',
};

/**
 * Get the flag emoji for a language code.
 */
export function getLanguageFlag(langCode: string): string {
  return LANGUAGE_FLAGS[langCode] || '\u{1F310}';
}

/**
 * Get the display name for a language code.
 */
export function getLanguageName(langCode: string): string {
  return SUPPORTED_LANGUAGES[langCode] || langCode;
}

/**
 * Format a date string for display.
 * Uses short month format: "Jan 1, 2025"
 */
export function formatDate(dateString: string | undefined | null): string {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

/**
 * Format a date string with time.
 * Uses: "January 1, 2025, 12:00 PM"
 */
export function formatDateTime(dateString: string | undefined | null): string {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Format a large number with K/M suffixes.
 */
export function formatNumber(num: number): string {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
  return num.toLocaleString();
}

/**
 * Truncate text by stripping HTML/markdown and limiting to maxLength characters.
 */
export function truncateText(text: string | undefined | null, maxLength: number): string {
  if (!text) return '';
  const plainText = text.replace(/<[^>]*>/g, '').replace(/[#*_`]/g, '');
  return plainText.length > maxLength
    ? plainText.slice(0, maxLength) + '...'
    : plainText;
}

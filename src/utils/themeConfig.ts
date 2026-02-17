/**
 * Theme configuration for mobile client customization.
 * Stored in card.metadata.theme
 */
export interface ThemeConfig {
  primaryColor?: string
  backgroundColor?: string
  gradientEndColor?: string
  textColor?: string
}

export const DEFAULT_THEME: Required<ThemeConfig> = {
  primaryColor: '#6366f1',
  backgroundColor: '#0f172a',
  gradientEndColor: '#4338ca',
  textColor: '#ffffff',
}

export const THEME_CSS_VARS = {
  primaryColor: '--theme-primary',
  backgroundColor: '--theme-bg',
  gradientEndColor: '--theme-gradient-end',
  textColor: '--theme-text',
} as const

export function resolveTheme(theme?: Partial<ThemeConfig>): Required<ThemeConfig> {
  return { ...DEFAULT_THEME, ...(theme || {}) }
}

export function hexToRgb(hex: string): string {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if (!result) return '255, 255, 255'
  return `${parseInt(result[1], 16)}, ${parseInt(result[2], 16)}, ${parseInt(result[3], 16)}`
}

function hexToRgbArray(hex: string): number[] | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if (!result) return null
  return [parseInt(result[1], 16), parseInt(result[2], 16), parseInt(result[3], 16)]
}

export function generateMidGradient(bgColor: string, endColor: string): string {
  const bgRgb = hexToRgbArray(bgColor)
  const endRgb = hexToRgbArray(endColor)
  if (!bgRgb || !endRgb) return '#1e3a8a'
  const mid = bgRgb.map((c, i) => Math.round((c + endRgb[i]) / 2))
  return `#${mid.map(c => c.toString(16).padStart(2, '0')).join('')}`
}

export function isValidHexColor(color: string): boolean {
  return /^#[0-9a-fA-F]{6}$/.test(color)
}

/**
 * Build CSS variable style object from theme config.
 * Applied as inline style on the mobile container element.
 */
export function buildThemeStyleVars(theme?: Partial<ThemeConfig>): Record<string, string> {
  const resolved = resolveTheme(theme)
  const primaryRgb = hexToRgb(resolved.primaryColor)
  const bgRgb = hexToRgb(resolved.backgroundColor)
  const textRgb = hexToRgb(resolved.textColor)
  const midGradient = generateMidGradient(resolved.backgroundColor, resolved.gradientEndColor)

  return {
    [THEME_CSS_VARS.primaryColor]: resolved.primaryColor,
    '--theme-primary-rgb': primaryRgb,
    [THEME_CSS_VARS.backgroundColor]: resolved.backgroundColor,
    '--theme-bg-rgb': bgRgb,
    [THEME_CSS_VARS.gradientEndColor]: resolved.gradientEndColor,
    '--theme-gradient-mid': midGradient,
    '--theme-surface': `rgba(${textRgb}, 0.07)`,
    [THEME_CSS_VARS.textColor]: resolved.textColor,
    '--theme-text-rgb': textRgb,
  }
}

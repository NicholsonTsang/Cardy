/**
 * Prompt Builder Utility
 *
 * Provides structured, concise system prompts for AI assistants.
 * Follows prompt engineering best practices:
 * - Clear role definition
 * - Explicit language requirements
 * - Structured knowledge context
 * - Natural conversation flow (suggestions only in greeting)
 *
 * Version History:
 * - v2.0.0 (2026-02-02): Optimized for prompt caching, added truncation, fixed rebuilding
 * - v1.0.0: Initial structured prompt system
 */

// PROMPT VERSION - Increment when changing prompt structure or behavior
// Used for debugging and A/B testing
const PROMPT_VERSION = '2.0.0'

interface PromptConfig {
  cardName: string
  cardDescription?: string
  languageName: string
  languageCode: string
  chineseVoice?: 'mandarin' | 'cantonese'
  knowledgeBase?: string
  customInstruction?: string
  // For content-item mode
  contentItemName?: string
  contentItemContent?: string
  contentItemKnowledge?: string
  parentContext?: {
    name: string
    description?: string
    knowledge?: string
  }
  // Mode context
  modeContext?: string
  // Content directory for card-level assistant (list of all content items)
  contentDirectory?: string
}

/**
 * Build language requirement section
 */
function buildLanguageRequirement(
  languageName: string,
  languageCode: string,
  chineseVoice?: 'mandarin' | 'cantonese'
): string {
  // Check if Chinese
  if (languageCode.startsWith('zh-')) {
    if (chineseVoice === 'cantonese') {
      return `LANGUAGE: CANTONESE (廣東話) only. Use Cantonese vocabulary, grammar, and expressions naturally.`
    }
    return `LANGUAGE: MANDARIN (普通話) only. Use Mandarin vocabulary, grammar, and expressions naturally.`
  }
  return `LANGUAGE: ${languageName} only. Never use any other language.`
}

/**
 * Build natural conversation behavior section
 * Key: NO constant suggestions - just answer naturally like a knowledgeable friend
 */
function buildBehaviorGuidelines(isItemMode: boolean): string {
  const baseGuidelines = `
CONVERSATION STYLE:
• Be natural and conversational - like a knowledgeable friend
• Answer questions directly and concisely (2-3 sentences)
• Share interesting facts and stories when relevant
• DO NOT suggest questions or topics in every response
• Only offer suggestions if the user explicitly asks "what else?" or seems stuck`

  if (isItemMode) {
    return baseGuidelines + `
• Focus deeply on this specific item
• Mention related items only when directly relevant to the answer`
  }

  return baseGuidelines + `
• Help users discover what interests them
• Provide specific recommendations when asked`
}

/**
 * Build system prompt for Card-Level (General) Assistant
 */
export function buildCardLevelPrompt(config: PromptConfig): string {
  const languageReq = buildLanguageRequirement(
    config.languageName,
    config.languageCode,
    config.chineseVoice
  )

  const behavior = buildBehaviorGuidelines(false)

  let prompt = `[v${PROMPT_VERSION}] # ROLE
You are the personal AI guide for "${config.cardName}".

# ${languageReq}

# ABOUT "${config.cardName}"
${config.cardDescription || 'A digital interactive experience.'}
`

  if (config.knowledgeBase) {
    prompt += `
# KNOWLEDGE BASE
${config.knowledgeBase}
`
  }

  if (config.contentDirectory) {
    prompt += `
# CONTENT DIRECTORY
The following items are available in this experience. Use this to help visitors find what they're looking for:
${config.contentDirectory}
`
  }

  if (config.customInstruction) {
    prompt += `
# SPECIAL INSTRUCTIONS
${config.customInstruction}
`
  }

  prompt += `
${behavior}`

  return prompt.trim()
}

/**
 * Build system prompt for Content-Item Assistant
 */
export function buildContentItemPrompt(config: PromptConfig): string {
  const languageReq = buildLanguageRequirement(
    config.languageName,
    config.languageCode,
    config.chineseVoice
  )

  const behavior = buildBehaviorGuidelines(true)

  let prompt = `[v${PROMPT_VERSION}] # ROLE
You are an expert guide for "${config.contentItemName}" within "${config.cardName}".

# ${languageReq}

# CURRENT ITEM: "${config.contentItemName}"
${config.contentItemContent || ''}
${config.modeContext ? `\n# DISPLAY MODE\n${config.modeContext}` : ''}
`

  if (config.parentContext) {
    prompt += `
# CONTEXT
Part of: "${config.parentContext.name}"
${config.parentContext.description ? `Description: ${config.parentContext.description}` : ''}
${config.parentContext.knowledge ? `\nBackground: ${config.parentContext.knowledge}` : ''}
`
  }

  if (config.contentItemKnowledge) {
    prompt += `
# ITEM KNOWLEDGE
${config.contentItemKnowledge}
`
  }

  if (config.knowledgeBase) {
    prompt += `
# GENERAL KNOWLEDGE
${config.knowledgeBase}
`
  }

  if (config.customInstruction) {
    prompt += `
# SPECIAL INSTRUCTIONS
${config.customInstruction}
`
  }

  prompt += `
${behavior}`

  return prompt.trim()
}

/**
 * Build a compact content directory string from content items.
 * For grouped content: shows categories with their children.
 * For flat content: shows a simple list of item names.
 * Truncates to stay within token budget (~2000 chars max).
 */
export function buildContentDirectory(
  items: Array<{ content_item_id: string; content_item_parent_id: string | null; content_item_name: string; content_item_sort_order: number }>,
  allItems?: Array<{ content_item_id: string; content_item_parent_id: string | null; content_item_name: string; content_item_sort_order: number }>
): string {
  const MAX_LENGTH = 2000
  const source = allItems || items

  // Separate parents (categories) and children (spread to avoid mutating input)
  const parents = [...source.filter(i => !i.content_item_parent_id)]
    .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
  const children = [...source.filter(i => i.content_item_parent_id)]
    .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)

  // If there are children, it's grouped content
  if (children.length > 0) {
    const lines: string[] = []
    for (const parent of parents) {
      const kids = children.filter(c => c.content_item_parent_id === parent.content_item_id)
      if (kids.length > 0) {
        lines.push(`• ${parent.content_item_name}: ${kids.map(k => k.content_item_name).join(', ')}`)
      } else {
        lines.push(`• ${parent.content_item_name}`)
      }
    }
    const result = lines.join('\n')
    return result.length > MAX_LENGTH ? result.substring(0, MAX_LENGTH) + '...' : result
  }

  // Flat content: simple list (spread to avoid mutating input)
  const sorted = [...items].sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
  const result = sorted.map(i => `• ${i.content_item_name}`).join('\n')
  return result.length > MAX_LENGTH ? result.substring(0, MAX_LENGTH) + '...' : result
}

/**
 * Build greeting instructions for realtime voice mode
 *
 * This is the ONLY place where topic suggestions should appear.
 * After the greeting, conversations should flow naturally without constant suggestions.
 */
export function buildRealtimeGreetingInstructions(
  languageName: string,
  customWelcome?: string,
  isItemMode: boolean = false
): string {
  const languageNote = `RESPOND ONLY in ${languageName}.`

  if (customWelcome) {
    // OPTIMIZATION: Truncate custom welcome to prevent excessively long greetings
    // Limit to 200 characters to keep voice greetings under ~15 seconds
    const MAX_WELCOME_LENGTH = 200
    const truncated = customWelcome.length > MAX_WELCOME_LENGTH
      ? customWelcome.substring(0, MAX_WELCOME_LENGTH).trim() + '...'
      : customWelcome

    // Use custom welcome as inspiration, but keep it brief for voice
    return `${languageNote}

GREETING GUIDANCE (from creator${customWelcome.length > MAX_WELCOME_LENGTH ? ', summarized' : ''}):
"${truncated}"

Generate a BRIEF spoken greeting (1-2 sentences max) that:
1. Warmly welcomes the user
2. Mentions what you can help with based on the guidance above
3. Ends with an open invitation like "What would you like to know?"

This is your ONLY greeting - after this, just answer questions naturally without suggesting topics.`
  }

  return `${languageNote}

Generate a BRIEF spoken greeting (1-2 sentences max) that:
1. Warmly welcomes the user
2. Introduces yourself as their ${isItemMode ? 'expert guide for this item' : 'personal guide'}
3. Mentions 2-3 things you know about (history, stories, tips, etc.)
4. Ends with "What would you like to know?" or similar open question

Example: "Hi! I'm your guide. I can share the history, interesting stories, or tips. What would you like to know?"

IMPORTANT: This greeting is your ONLY chance to suggest topics. After this, just answer questions naturally like a friendly expert - no need to keep suggesting what to ask.`
}


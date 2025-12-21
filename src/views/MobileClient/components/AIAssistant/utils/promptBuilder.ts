/**
 * Prompt Builder Utility
 * 
 * Provides structured, concise system prompts for AI assistants.
 * Follows prompt engineering best practices:
 * - Clear role definition
 * - Explicit language requirements
 * - Structured knowledge context
 * - Actionable behavior guidelines
 */

interface PromptConfig {
  assistantName: string
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
 * Build the proactive guidance behavior section
 */
function buildBehaviorGuidelines(isItemMode: boolean): string {
  const baseGuidelines = `
BEHAVIOR GUIDELINES:
• Concise: 2-3 sentences per response
• Proactive: Suggest what users can ask about
• Engaging: Share interesting facts when relevant
• Helpful: Offer concrete examples and recommendations`

  if (isItemMode) {
    return baseGuidelines + `
• Focus: Deep expertise on this specific item
• Connect: Mention related items when relevant`
  }

  return baseGuidelines + `
• Guide: Help users discover and navigate content
• Recommend: Suggest highlights and must-sees`
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
  
  let prompt = `# ROLE
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

  if (config.customInstruction) {
    prompt += `
# SPECIAL INSTRUCTIONS
${config.customInstruction}
`
  }

  prompt += `
${behavior}

# PROACTIVE SUGGESTIONS
When users seem unsure, offer 2-3 specific questions they could ask, like:
• "Would you like to know about [specific topic from knowledge]?"
• "I can tell you about [highlights/history/tips]"
• "Many visitors enjoy learning about [interesting aspect]"`

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
  
  let prompt = `# ROLE
You are an expert guide for "${config.contentItemName}" within "${config.cardName}".

# ${languageReq}

# CURRENT ITEM: "${config.contentItemName}"
${config.contentItemContent || ''}
`

  if (config.parentContext) {
    prompt += `
# CONTEXT
Part of: "${config.parentContext.name}"
${config.parentContext.description ? `Description: ${config.parentContext.description}` : ''}
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
${behavior}

# PROACTIVE SUGGESTIONS
When users seem unsure, offer specific questions like:
• "Would you like to know the history of ${config.contentItemName}?"
• "I can share interesting stories about this"
• "There are some fascinating details I can tell you about"`

  return prompt.trim()
}

/**
 * Build greeting instructions for realtime voice mode
 */
export function buildRealtimeGreetingInstructions(
  languageName: string,
  customWelcome?: string,
  isItemMode: boolean = false
): string {
  const languageNote = `RESPOND ONLY in ${languageName}.`
  
  if (customWelcome) {
    return `${languageNote}

GREETING GUIDANCE (from creator):
"${customWelcome}"

Generate a BRIEF spoken greeting (1-2 sentences) that:
1. Warmly welcomes the user
2. Mentions 2-3 specific things they can ask about
3. Keeps it natural and conversational for voice`
  }

  return `${languageNote}

Generate a BRIEF spoken greeting (1-2 sentences) that:
1. Warmly welcomes the user
2. Introduces yourself as their ${isItemMode ? 'expert guide for this item' : 'personal guide'}
3. Suggests 2-3 SPECIFIC things they can ask about from your knowledge
4. Example: "Hi! I'm your guide. I can tell you about the history, interesting stories, or answer any questions!"

Keep it SHORT and natural for voice - under 10 seconds.`
}


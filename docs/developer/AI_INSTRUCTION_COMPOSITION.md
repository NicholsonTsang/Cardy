# AI Instruction Composition

**Guide to composing effective AI prompts, optimizing performance, and best practices**

## Overview

This document explains:
- How AI prompts are structured and prioritized
- Optimization techniques for cost and performance
- Best practices for writing effective instructions and knowledge bases

---

## Prompt Composition Structure

### Data Fields

**Cards Table:**
- `ai_instruction` (100 words max) - Behavioral rules and personality
- `ai_knowledge_base` (2000 words max) - General knowledge and context
- `ai_welcome_general` - Custom greeting for Card-Level Assistant
- `ai_welcome_item` - Custom greeting for Item Assistant (supports `{name}` placeholder)
- `name`, `description` - Basic context

**Content Items Table:**
- `ai_knowledge_base` (500 words max) - Item-specific knowledge
- `content` - Full markdown content (primary source)
- `name`, `parent_id` - Context and hierarchy

### Priority Order

Information is processed from highest to lowest priority:

```
1. LANGUAGE REQUIREMENT ← Highest priority
2. ROLE DEFINITION
3. CONTENT CONTEXT (item content or card description)
4. ITEM KNOWLEDGE (content_items.ai_knowledge_base)
5. CARD KNOWLEDGE (cards.ai_knowledge_base)
6. CUSTOM INSTRUCTIONS (cards.ai_instruction)
7. BEHAVIOR GUIDELINES ← Lowest priority
```

**Key Principle:** Earlier items have stronger influence. Place critical behavioral rules in `ai_instruction`, not in knowledge bases.

---

## Assistant Types

### Card-Level Assistant
**Context:** General project questions

**Receives:**
- Card name, description, knowledge base, instructions
- User's chat history and language preference
- ❌ Does NOT receive individual content items

### Content-Item Assistant
**Context:** Specific item questions

**Receives:**
- Everything Card-Level has, PLUS:
- Current item's full content and knowledge base
- Parent item context (if hierarchical)
- ❌ Does NOT receive sibling or child items

---

## Prompt Templates

### Card-Level Prompt

```markdown
# ROLE
You are the personal AI guide for "{cardName}"

# LANGUAGE
LANGUAGE: {languageName} only. Never use any other language.

# ABOUT "{cardName}"
{cardDescription}

# KNOWLEDGE BASE
{ai_knowledge_base}

# SPECIAL INSTRUCTIONS
{ai_instruction}

# CONVERSATION STYLE
• Answer questions directly and concisely (2-3 sentences)
• Share interesting facts when relevant
• DO NOT suggest questions in every response
• Only offer suggestions if user asks "what else?" or seems stuck
```

### Content-Item Prompt

```markdown
# ROLE
You are an expert guide for "{itemName}" within "{cardName}"

# LANGUAGE
LANGUAGE: {languageName} only. Never use any other language.

# CURRENT ITEM: "{itemName}"
{contentItemContent}
[This is the PRIMARY FOCUS]

# CONTEXT
[If parent exists]
This item is part of: "{parentItemName}"
{parentItemContent}

# ITEM KNOWLEDGE
{content_item_ai_knowledge_base}

# GENERAL KNOWLEDGE
{cardData.ai_knowledge_base}

# SPECIAL INSTRUCTIONS
{cardData.ai_instruction}

# CONVERSATION STYLE
• Answer directly and concisely (2-3 sentences)
• Focus deeply on this specific item
• Share interesting facts when relevant
• DO NOT suggest questions in every response
```

**Note:** Sections are only included if data exists. Language requirement is always placed first (highest priority).



---

## Optimization Techniques

### Cost Optimization

**Prompt Caching (Automatic)**
- OpenAI caches static system prompts after first message
- Reduces costs by ~40% for multi-message conversations
- No configuration needed - works automatically

**Selective Rebuilding**
- Prompts regenerate only when data changes
- Use `ref()` with watchers instead of `computed()` in Vue components
- Reduces unnecessary prompt reconstruction by 90%

**Cost Savings Example (10,000 conversations/month, 5 messages each):**
- Before optimization: $3.95/month
- After optimization: $2.35/month (40% savings)

### Common Issues & Quick Fixes

**Issue: AI doesn't follow instructions**
- ❌ Instructions in knowledge base → ✅ Use `ai_instruction` field
- ❌ Vague rules → ✅ Use specific, imperative commands
- ❌ Contradictory instructions → ✅ Ensure consistency across fields

**Issue: AI gives generic answers**
- ❌ "We have exhibits" → ✅ "5 exhibits: Dinosaurs (12 skeletons), Marine Life (30k gallon tank)..."
- ❌ Wrong assistant type → ✅ Use Item Assistant for specific content
- ❌ Missing details → ✅ Add numbers, names, specific facts

**Issue: Responses too long**
- ✅ Add to `ai_instruction`: "Answer in 2-3 sentences for simple questions"
- ✅ Condense knowledge base to bullet points
- ✅ Remove verbose descriptions

**Issue: AI suggests topics constantly**
- ✅ Add to `ai_instruction`: "NEVER suggest questions unless user asks 'what else?'"
- ✅ Strengthen language requirement (place it first)

**Issue: Outdated information**
- Text/Voice modes: Changes take effect immediately (refresh page for new chat)
- Realtime mode: Requires reconnection to apply changes

---

## Best Practices

### Writing Instructions (`ai_instruction`)

**Do:**
- ✅ Use specific, imperative commands ("Answer in 2-3 sentences")
- ✅ Define tone and personality ("Be warm and encouraging")
- ✅ Set behavioral boundaries ("Never mention competitors")
- ✅ Keep under 100 words
- ✅ Focus on HOW to behave, not WHAT to know

**Don't:**
- ❌ Be vague ("Be helpful and friendly")
- ❌ Mix factual knowledge with behavioral rules
- ❌ Use weak phrasing ("Try to..." or "You should...")
- ❌ Exceed word limit

### Writing Knowledge Bases (`ai_knowledge_base`)

**Do:**
- ✅ Use bullet points or short paragraphs
- ✅ Include specific facts: numbers, names, dates
- ✅ Keep it factual and objective
- ✅ Organize by topic
- ✅ Focus on WHAT to know, not HOW to behave

**Don't:**
- ❌ Mix instructions with knowledge
- ❌ Write in first person
- ❌ Duplicate content that's already in item content
- ❌ Exceed limits (card: 2000 words, item: 500 words)

### Card vs Item Knowledge Distribution

**Card-Level Knowledge** (General context):
- Project overview and background
- Policies, hours, logistics
- Information applicable to all items

**Item-Level Knowledge** (Specific details):
- Facts about THIS item only
- Technical details not in main content
- Item-specific anecdotes

**Example:**
```
Card: "Family-owned since 1987. Chef Marco trained in Bologna. 200+ Italian wines."
Item: "Chef Marco's signature dish. Truffles from Alba (Oct-Dec). Pairs with Barolo."
```

### Hierarchical Content

**Parent items** provide category overview; **child items** focus on specifics.

AI automatically inherits parent context when viewing child items.

```
Parent: "Exhibits" → "5 main sections. Interactive elements in each."
Child: "Dinosaurs Hall" → "12 skeletons. T-Rex from 1952."
```

---

## Quick Reference

### Field Limits

| Field | Max Size | Recommended | Priority |
|-------|----------|-------------|----------|
| `ai_instruction` | 100 words | 50-80 words | HIGH |
| `ai_knowledge_base` (card) | 2000 words | 500-1500 words | MEDIUM |
| `ai_knowledge_base` (item) | 500 words | 100-300 words | HIGH |

### Key Principles

1. **Use `ai_instruction` for HOW to behave** (tone, style, rules)
2. **Use `ai_knowledge_base` for WHAT to know** (facts, details)
3. **Earlier in priority order = stronger influence**
4. **Keep it specific** (numbers, names, facts vs. vague descriptions)
5. **Test incrementally** (start with Text Chat mode)

### Common Fixes

| Problem | Solution |
|---------|----------|
| AI ignores rules | Move to `ai_instruction` field (higher priority) |
| Generic answers | Add specific facts with numbers, names, dates |
| Wrong language | Ensure language requirement is first in prompt |
| Too many suggestions | Add "NEVER suggest questions" to `ai_instruction` |
| Answers too long | Add "Answer in 2-3 sentences" to `ai_instruction` |

---

**Implementation:** `src/views/MobileClient/components/AIAssistant/utils/promptBuilder.ts`

**Related Docs:** AI_INTEGRATION.md, CLAUDE.md

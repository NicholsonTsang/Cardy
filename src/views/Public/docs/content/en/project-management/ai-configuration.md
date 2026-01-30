## AI Assistant Configuration

ExperienceQR features a powerful dual AI assistant system that allows visitors to have natural conversations at both the project level and individual content item level.

## Dual AI Assistant System

### Project-Level Assistant (General)

The project-level assistant answers general questions about your entire venue or experience.

**Appears on:**
- Project Overview page
- Content list/grid/cards navigation pages
- Floating button throughout the mobile experience

**Best for questions like:**
- "What should I see first?"
- "Where is the most popular item?"
- "What are your opening hours?"
- "Can you recommend something for kids?"

### Content Item Assistant (Specific)

Each content item can have its own AI assistant for detailed, item-specific information.

**Appears on:**
- Content Detail page
- As an inline button within the item view

**Best for questions like:**
- "Tell me more about this artwork"
- "What techniques were used here?"
- "Who created this piece?"
- "What's the history behind this item?"

## AI Settings Overview

### Project-Level Configuration

Configure the general AI assistant that answers questions about your entire project:

- **AI Instructions** - Guide how the AI responds (tone, focus areas, restrictions)
- **Knowledge Base** - General information about your venue/project
- **General Welcome Message** - Custom greeting when visitors start a conversation

![AI Configuration](/Image/docs/ai-configuration.png "AI Configuration Panel")

### Content-Level Configuration

Each content item can have its own AI configuration:

- **Item Knowledge Base** - Specific details about this item
- **Item Welcome Message** - Custom greeting for item-specific conversations (supports `{name}` placeholder)

## AI and Session Costs

Enabling AI affects your session costs:

| Plan | AI Enabled | AI Disabled | Savings |
|------|------------|-------------|---------|
| **Starter** | $0.05/session | $0.025/session | 50% off |
| **Premium** | $0.04/session | $0.02/session | 50% off |

:::tip Cost Optimization
Disable AI on projects that don't need voice/chat assistance to pay half the session rate.
:::

## Writing Effective AI Instructions

AI Instructions tell the assistant how to behave. Keep them under ~100 words.

:::tip Instruction Best Practices
Be specific about:
- Tone (formal, casual, friendly, enthusiastic)
- Focus areas (history, recommendations, facts)
- Restrictions (avoid pricing, don't make promises)
:::

### Example Instructions

**Museum Guide:**
```
You are a friendly museum guide. Focus on art history and artist backgrounds.
Keep answers concise but informative. Suggest related artworks when relevant.
Don't discuss artwork valuations or authentication.
```

**Restaurant Assistant:**
```
You are a helpful restaurant assistant. Describe dishes enthusiastically.
Mention ingredients and preparation when asked. Suggest pairings.
Don't discuss competitor restaurants or make health claims.
```

## Building Knowledge Bases

The knowledge base provides context for AI responses. This is where you add all the information the AI should know.

### For Projects (~2000 words max)

Include:
- Venue history and background
- Operating hours and location details
- General policies and guidelines
- Frequently asked questions
- Staff recommendations and highlights

### For Content Items

Include:
- Detailed descriptions and history
- Creator/artist information
- Interesting facts and stories
- Related items or recommendations
- Technical details (materials, dimensions, dates)

:::info Knowledge Quality = AI Quality
The more detailed and accurate your knowledge base, the better the AI assistant will perform. Update it based on common visitor questions.
:::

## Custom Welcome Messages

Welcome messages set the tone for visitor interactions and guide them on what to ask.

### General Welcome (Project-Level)

Used when visitors access the main AI assistant:

**Example:**
> "Welcome to the Museum of Modern Art! I can explain any artwork here, share artist stories, suggest personalized tours, or answer questions about our facilities. What would you like to explore?"

### Item Welcome (Content-Item Level)

Used when visitors tap the AI button on a specific item. Use `{name}` as a placeholder for the item name:

**Example:**
> "You're looking at {name}. I can share its history, explain the techniques used, discuss the artist's inspiration, or connect it to other works in our collection. What interests you most?"

## Voice and Text Modes

Both AI assistants support:

- **Text Chat** - Type questions and receive written responses
- **Voice Recording** - Speak your question, receive text response with audio playback
- **Real-time Voice** - Have a natural back-and-forth conversation (like talking to a guide)

The AI automatically responds in the visitor's selected language when translations are available.

## AI in Different Content Modes

The AI adapts its behavior based on your content display mode:

| Mode | AI Behavior |
|------|-------------|
| Single | Deep-dive on the featured item |
| List | Help browse and filter options |
| Grid | Explore the gallery, suggest items |
| Cards | Guide through featured content |

## Testing Your AI

Before publishing, test your AI configuration:

1. Use the **Preview** mode in your dashboard
2. Ask various questions a visitor might ask
3. Test both general questions and item-specific ones
4. Verify responses are accurate and helpful
5. Adjust instructions or knowledge base as needed

![AI Testing](/Image/docs/ai-testing.png "Testing AI Responses")

### Test Questions to Try

| Type | Example Questions |
|------|-------------------|
| General | "What are your hours?", "What should I see first?" |
| Specific | "Tell me about [item name]", "Who created this?" |
| Recommendations | "What's popular?", "What's good for kids?" |
| Practical | "Where is the restroom?", "Is there a café?" |

## Troubleshooting

### AI Gives Wrong Answers

- Check if information is in the knowledge base
- Look for conflicting information
- Make instructions more specific

### AI Goes Off-Topic

Add to instructions:
```
If asked about topics outside [your venue], politely redirect:
"I specialize in [venue name]. Is there something about our
exhibits I can help with?"
```

### Responses Too Long/Short

Adjust instructions:
- For shorter: "Keep responses to 2-3 sentences maximum."
- For longer: "Provide detailed responses with examples when asked."

## AI Assistant Configuration

ExperienceQR features a powerful dual AI assistant system that allows visitors to have natural conversations at both the project level and individual content item level.

## Dual AI Assistant System

### Project-Level Assistant (General)

The project-level assistant answers general questions about your entire venue or experience.

**Appears on:**
- Card Overview page
- Content list/grid navigation pages
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

## Proactive AI Guidance

Our AI assistants are designed to be **proactive**, not passive. Instead of generic "How can I help?" greetings, they:

1. **Suggest specific topics** based on the knowledge base
2. **Offer 2-3 example questions** visitors might ask
3. **Share unprompted insights** that enhance the experience
4. **Guide users** with phrases like "I can also tell you about..." or "Many visitors ask about..."

### Example Proactive Greeting

> "Hi! I'm your guide for the Renaissance Gallery. I can share stories about these masterpieces, explain the artists' techniques, or recommend what to see next. What interests you most?"

## Writing Effective AI Instructions

:::tip Instruction Best Practices
Be specific about:
- Tone (formal, casual, friendly)
- Focus areas (history, recommendations, facts)
- Restrictions (avoid pricing discussions, don't make promises)
:::

Example instruction:
```
You are a friendly museum guide. Focus on art history and artist backgrounds. 
Keep answers concise but informative. Suggest related artworks when relevant.
Don't discuss artwork valuations or authentication.
```

## Building Knowledge Bases

The knowledge base provides context for AI responses. Include:

### For Projects
- Venue history and background
- Operating hours and location details
- General policies and guidelines
- Frequently asked questions
- Staff recommendations

### For Content Items
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
- **Voice Recording** - Speak your question, receive text response
- **Real-time Voice** - Have a natural back-and-forth conversation

The AI automatically responds in the visitor's selected language using translated knowledge bases.

## Testing Your AI

Before publishing, test your AI configuration:

1. Use the Preview mode in your dashboard
2. Ask various questions a visitor might ask
3. Test both general questions and item-specific ones
4. Verify responses are accurate, helpful, and proactive
5. Adjust instructions or knowledge base as needed

![AI Testing](/Image/docs/ai-testing.png "Testing AI Responses")

## Content Mode Context

The AI adapts its behavior based on the current content mode:

| Mode | AI Behavior |
|------|-------------|
| Single | Deep-dive on the featured item |
| List | Help browse and filter options |
| Grid | Explore the gallery, suggest items |
| Grouped | Navigate categories, compare items |
| Inline | Guide through the continuous experience |

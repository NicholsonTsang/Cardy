# AI Assistants

This guide covers setting up and configuring AI-powered voice and chat assistants for your visitors.

## What Are AI Assistants?

AI Assistants allow visitors to have natural conversations about your content through:

- **Text chat** - Type questions and get answers
- **Voice messages** - Record questions, hear responses
- **Real-time voice** - Live conversation (like talking to a guide)

The AI uses your content and knowledge to provide accurate, contextual responses.

## AI Assistant Types

Each project can have two AI assistants:

### General Assistant

| Aspect | Description |
|--------|-------------|
| **Location** | Overview page, floating chat button |
| **Scope** | Entire project |
| **Knowledge** | Project description + knowledge base |
| **Best for** | General questions about your project |

### Item Assistant

| Aspect | Description |
|--------|-------------|
| **Location** | Individual content item pages |
| **Scope** | Specific content item |
| **Knowledge** | Item content + item-specific knowledge |
| **Best for** | Detailed questions about specific content items |

## Enabling AI

### Turn On AI for a Project

1. Open your project
2. Go to **Settings** or **AI Assistant** tab
3. Toggle **"Enable AI Assistant"** on
4. Configure settings (see below)
5. Save changes

### AI and Billing

AI-enabled projects have a higher session cost:

| Plan | AI Session Cost | Non-AI Session Cost |
|------|-----------------|---------------------|
| Starter | $0.05 | $0.025 |
| Premium | $0.04 | $0.02 |

**Tip:** Only enable AI for projects where visitors will use it.

## Configuring AI

### AI Instructions

Tell the AI how to behave:

**Location:** Project Settings → AI Instructions

**What to include:**
- AI's role/persona
- Tone of voice
- Topics to focus on
- Topics to avoid
- Any restrictions

**Character limit:** ~100 words

**Example:**
```
You are a friendly museum guide for the Natural History Museum.
Speak in a conversational, enthusiastic tone.
Focus on facts about our exhibits and collections.
Never discuss topics outside the museum.
If unsure, suggest visitors ask staff.
Keep responses concise for mobile reading.
```

### AI Knowledge Base

Provide background information the AI should know:

**Location:** Project Settings → AI Knowledge Base

**What to include:**
- Facts not in your content
- Historical context
- Frequently asked questions and answers
- Behind-the-scenes information
- Practical details (hours, prices, policies)

**Character limit:** ~2000 words

**Example:**
```
ABOUT THE MUSEUM
Founded in 1869, the Natural History Museum houses over 5 million specimens.
Open daily 9am-5pm, closed Mondays.
Admission: Adults $20, Children $12, Members free.

DINOSAUR HALL
Our T-Rex skeleton is named "Sue" and is 90% complete.
She was discovered in Montana in 1990.
The skull alone weighs 600 pounds.

FAQ
Q: Can we take photos? A: Yes, without flash.
Q: Is there a cafe? A: Yes, on the ground floor.
Q: Are strollers allowed? A: Yes, available for rent.
```

### Welcome Messages

Customize what visitors see when they start a conversation:

#### General Welcome Message

Shown when opening the main assistant.

**Example:**
```
Welcome to the Natural History Museum! 👋

I'm your AI guide. Ask me anything about our exhibits,
or try: "What's the most popular exhibit?"
```

#### Item Welcome Message

Shown when opening assistant on a content item. Use `{name}` placeholder for the item name.

**Example:**
```
Hi! I can tell you more about {name}.

What would you like to know?
```

## Voice Features

### Voice Messages

Visitors can:
1. Tap the microphone button
2. Record their question
3. Hear the AI response read aloud

**Supported languages:** All 10 platform languages

### Real-Time Voice

Live conversation mode:

1. Visitor taps "Start Conversation"
2. Speaks naturally
3. AI responds in real-time
4. Like talking to a human guide

**Requirements:**
- Microphone permission
- Stable internet connection
- Supported browser

### Voice Settings

| Setting | Description |
|---------|-------------|
| **Voice** | AI voice character (alloy, echo, nova, etc.) |
| **Language** | Detected automatically from visitor's selection |

## Writing Effective AI Instructions

### Be Specific

**Too vague:**
```
Be helpful and answer questions.
```

**Better:**
```
You are a knowledgeable guide for the City Art Museum.
Answer questions about artworks, artists, and exhibitions.
Keep responses under 3 sentences unless asked for more detail.
```

### Set Boundaries

**Include restrictions:**
```
Do NOT discuss:
- Artwork prices or valuations
- Staff personal information
- Security details
- Competitor museums
```

### Define Personality

**Give character:**
```
Speak as an enthusiastic art lover who gets excited
sharing knowledge. Use phrases like "Isn't that fascinating?"
and "One of my favorites is..."
```

## Writing Effective Knowledge

### Structure Information

Use clear sections:

```
=== HOURS & ADMISSION ===
Monday: Closed
Tuesday-Sunday: 10am-6pm
Last entry: 5:30pm

Adults: $25
Students: $15 (with valid ID)
Children under 5: Free

=== CURRENT EXHIBITIONS ===
"Modern Masters" - Through March 2024
"Photography Now" - Through May 2024
```

### Include FAQs

Anticipate common questions:

```
FREQUENTLY ASKED QUESTIONS

Q: Is there parking?
A: Yes, underground parking is $15/day. Enter from Main Street.

Q: Can I bring food?
A: Outside food is not permitted. Visit our café on level 2.

Q: Are pets allowed?
A: Only service animals are permitted.
```

### Add Context

Provide depth:

```
THE STARRY NIGHT (Van Gogh, 1889)

This painting was created during Van Gogh's stay at the
Saint-Paul-de-Mausole asylum. The swirling sky may represent
his turbulent mental state. The village below is imaginary,
though inspired by views from his window.

FUN FACT: Van Gogh considered this painting a "failure"
and rarely mentioned it in his letters.
```

## Testing Your AI

### Before Going Live

1. **Enable AI** on your project
2. **Scan the QR code** or open preview
3. **Ask test questions:**
   - Basic facts about your venue
   - Questions about specific items
   - Edge cases (what shouldn't it answer?)
   - Different phrasings of the same question

### Test Questions to Try

| Category | Example Questions |
|----------|-------------------|
| **Basic info** | "What are your hours?" / "What does this product do?" |
| **Specific items** | "Tell me about [item name]" |
| **Recommendations** | "What should I look at first?" |
| **Practical** | "How do I get started?" |
| **Out of scope** | "What's the weather today?" |

### Refining Responses

If answers aren't good:

1. **Check knowledge base** - Is the information there?
2. **Clarify instructions** - Be more specific
3. **Add examples** - Show the AI what you want
4. **Test again** - Iterate until satisfied

## Multi-Language AI

### How It Works

The AI automatically:
- Detects visitor's language selection
- Responds in that language
- Uses translated knowledge if available

### Translation Support

| Plan | Languages |
|------|-----------|
| Free | AI responds in English only |
| Starter | AI responds in selected language (2 max) |
| Premium | All 10 languages |

**Languages:** English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French, Russian, Arabic, Thai

## Best Practices

### Do's

- ✅ Keep instructions concise and clear
- ✅ Include practical information (hours, prices)
- ✅ Anticipate common questions
- ✅ Test thoroughly before launch
- ✅ Update knowledge when things change
- ✅ Set appropriate boundaries

### Don'ts

- ❌ Include sensitive information
- ❌ Make promises the AI can't keep
- ❌ Use jargon visitors won't understand
- ❌ Forget to test in different languages
- ❌ Leave outdated information

## Troubleshooting

### AI Gives Wrong Answers

**Causes:**
- Information not in knowledge base
- Conflicting information
- Unclear instructions

**Solutions:**
- Add correct information to knowledge base
- Remove contradictions
- Be more specific in instructions

### AI Won't Stay on Topic

**Add to instructions:**
```
If asked about topics outside [your subject], politely redirect:
"I specialize in [project name]. Is there something about
our content I can help with?"
```

### Voice Not Working

**Check:**
- Microphone permissions granted
- Browser supports audio
- Stable internet connection
- Try refreshing the page

### Responses Too Long/Short

**Adjust instructions:**
```
Keep responses to 2-3 sentences maximum.
```
or
```
Provide detailed responses with examples when answering
questions about artwork techniques.
```

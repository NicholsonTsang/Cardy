# Conference - Grouped Mode (Digital Access)

A multi-day tech conference with sessions organized by day and track. Grouped mode allows attendees to browse by day/track (categories) and see individual sessions (items).

---

## Card Settings

```yaml
name: "TechSummit 2025 - Conference Guide"
description: |
  Welcome to **TechSummit 2025**! 🚀
  
  December 10-12 | Convention Center
  
  Browse sessions by day, track, and speaker. Build your personalized 
  schedule with our AI assistant.

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Conference logo or venue photo]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are a helpful conference assistant. Help attendees find relevant 
  sessions based on their interests, navigate the venue, and answer 
  questions about speakers and topics. Be enthusiastic about tech and 
  help people discover talks they might not have considered.

ai_knowledge_base: |
  TechSummit 2025 - Annual Technology Conference
  Dates: December 10-12, 2025
  Venue: Downtown Convention Center
  Attendees: 5,000 expected
  
  Venue layout:
  - Main Hall: Keynotes (capacity 3,000)
  - Room A: AI & ML Track (500)
  - Room B: Web & Mobile Track (500)
  - Room C: Cloud & DevOps Track (500)
  - Room D: Workshops (100)
  - Expo Hall: Sponsor booths
  
  WiFi: TechSummit2025 / password: innovate2025
  App: Download TechSummit app for live schedule updates
  Meals: Breakfast 8-9am, Lunch 12:30-2pm, Coffee breaks 10:30am & 3:30pm

ai_welcome_general: "Welcome to TechSummit 2025! I can help you find sessions by topic, build your schedule, locate rooms, find WiFi info, or suggest talks based on your interests. What are you looking for?"
ai_welcome_item: "Great choice! For \"{name}\", I can share speaker bio, session objectives, prerequisites, or recommend related sessions. What would help you prepare?"
```

---

## Content Items

### Day 1 - December 10 (Wednesday)
```yaml
name: "Day 1 - December 10"
content: ""
image_url: null
ai_knowledge_base: |
  Day 1 focus: Opening keynote and foundational sessions.
  Theme: "The Future of Technology"
  Special events: Welcome reception 6-8pm in Expo Hall
  Early bird workshop: "Intro to AI" 7:30am (pre-registration required)
sort_order: 1
parent_id: null
```

#### Opening Keynote
```yaml
name: "Opening Keynote: The Next Decade of Tech"
content: |
  **🎤 Sarah Chen, CEO of FutureTech**
  
  📍 Main Hall | ⏰ 9:00 AM - 10:15 AM
  
  Join us as Sarah Chen shares her vision for the next decade of 
  technology. From AI breakthroughs to sustainable computing, 
  discover what's coming and how to prepare.
  
  Sarah has led FutureTech to a $50B valuation and was named 
  "Most Influential Tech Leader" by Wired Magazine.
  
  ---
  
  🏷️ **Track:** Keynote  
  📊 **Level:** All Levels  
  ⭐ **Featured Speaker**

image_url: "[Upload: sarah_chen.jpg]"
ai_knowledge_base: |
  Sarah Chen founded FutureTech in 2015, grew to 10,000 employees. 
  Previous roles: VP Engineering at Google, CTO at Stripe. Stanford CS 
  PhD focused on distributed systems. Known for accurate predictions - 
  called the smartphone revolution in 2005. Will discuss: AI regulation, 
  quantum computing timeline, climate tech, and workforce evolution.
sort_order: 1
parent_id: "[Reference: Day 1 category ID]"
```

#### AI Session 1
```yaml
name: "Building Production ML Systems"
content: |
  **🎤 Dr. James Liu, ML Lead at DataScale**
  
  📍 Room A | ⏰ 10:45 AM - 11:30 AM
  
  Learn the architectural patterns and best practices for deploying 
  machine learning models at scale. James shares lessons from 
  running ML systems serving 100M+ predictions daily.
  
  ---
  
  **Topics Covered:**
  - Feature stores and real-time inference
  - Model versioning and A/B testing
  - Monitoring and debugging ML in production
  - Cost optimization strategies
  
  🏷️ **Track:** AI & Machine Learning  
  📊 **Level:** Intermediate  
  💻 **Slides:** Available in app after session

image_url: "[Upload: james_liu.jpg]"
ai_knowledge_base: |
  James Liu has 12 years ML experience. PhD from MIT in predictive 
  systems. DataScale processes 50TB data daily. Session includes live 
  demo of their monitoring dashboard. Will share their open-source 
  feature store framework. Good for engineers moving from prototype to 
  production ML.
sort_order: 2
parent_id: "[Reference: Day 1 category ID]"
```

#### Web Session 1
```yaml
name: "Modern Web Performance in 2025"
content: |
  **🎤 Elena Rodriguez, Performance Engineer at Shopify**
  
  📍 Room B | ⏰ 10:45 AM - 11:30 AM
  
  Web performance directly impacts user experience and business metrics. 
  Discover the latest techniques for building blazing-fast web applications.
  
  ---
  
  **Topics Covered:**
  - Core Web Vitals optimization
  - Image and font loading strategies
  - JavaScript bundling in 2025
  - Edge computing and CDN strategies
  
  🏷️ **Track:** Web & Mobile  
  📊 **Level:** Intermediate  
  🔗 **Resources:** github.com/elena/webperf-2025

image_url: "[Upload: elena_rodriguez.jpg]"
ai_knowledge_base: |
  Elena improved Shopify's LCP by 40% last year. Previously at Google 
  Chrome team working on performance metrics. Active contributor to 
  web standards. Will demo real Shopify optimizations. Includes hands-on 
  exercises if you bring laptop.
sort_order: 3
parent_id: "[Reference: Day 1 category ID]"
```

#### Cloud Session 1
```yaml
name: "Zero Trust Security Architecture"
content: |
  **🎤 Marcus Thompson, CISO at FinanceCloud**
  
  📍 Room C | ⏰ 10:45 AM - 11:30 AM
  
  Traditional perimeter security is dead. Learn how to implement 
  zero trust architecture to protect your cloud infrastructure 
  in an age of sophisticated threats.
  
  ---
  
  **Topics Covered:**
  - Zero trust principles and frameworks
  - Identity-based access control
  - Micro-segmentation strategies
  - Real-world implementation case studies
  
  🏷️ **Track:** Cloud & DevOps  
  📊 **Level:** Advanced  
  📋 **Prerequisite:** Cloud security fundamentals

image_url: "[Upload: marcus_thompson.jpg]"
ai_knowledge_base: |
  Marcus led security for $2T in transactions at FinanceCloud. 
  20+ years in cybersecurity, former NSA. Will discuss actual 
  breach attempts and how zero trust prevented them. Covers AWS, 
  Azure, and GCP implementations. Highly rated speaker from last year.
sort_order: 4
parent_id: "[Reference: Day 1 category ID]"
```

---

### Day 2 - December 11 (Thursday)
```yaml
name: "Day 2 - December 11"
content: ""
image_url: null
ai_knowledge_base: |
  Day 2 focus: Deep dive technical sessions and hands-on workshops.
  Theme: "Building for Scale"
  Special events: Speaker dinner (invite only), Birds of a Feather sessions 5-6pm
  Evening: Hackathon kickoff 7pm (48-hour event)
sort_order: 2
parent_id: null
```

#### Day 2 Keynote
```yaml
name: "Keynote: Responsible AI - Building Trust"
content: |
  **🎤 Dr. Aisha Patel, Chief Ethics Officer at TechGiant**
  
  📍 Main Hall | ⏰ 9:00 AM - 10:00 AM
  
  As AI becomes ubiquitous, how do we ensure it serves humanity? 
  Dr. Patel shares frameworks for ethical AI development and 
  responsible deployment.
  
  Named one of TIME's 100 Most Influential People in AI.
  
  ---
  
  🏷️ **Track:** Keynote  
  📊 **Level:** All Levels  
  ⭐ **Featured Speaker**

image_url: "[Upload: aisha_patel.jpg]"
ai_knowledge_base: |
  Dr. Patel wrote the book "AI Ethics in Practice" (bestseller). 
  Advises EU on AI regulation. TechGiant's ethics board has veto 
  power on products. Will discuss: bias in hiring algorithms, 
  AI in healthcare decisions, deepfake detection, and open-source 
  AI governance. Q&A session follows.
sort_order: 1
parent_id: "[Reference: Day 2 category ID]"
```

#### Workshop
```yaml
name: "Workshop: Building Your First LLM Application"
content: |
  **🎤 David Kim, Developer Advocate at OpenAI**
  
  📍 Room D | ⏰ 10:30 AM - 12:30 PM | **2 Hours**
  
  **⚠️ Pre-registration required - Limited to 100 attendees**
  
  Hands-on workshop building a real application using GPT-4 API. 
  You'll leave with a working chatbot deployed to production.
  
  ---
  
  **What You'll Build:**
  - Custom chatbot with RAG (Retrieval Augmented Generation)
  - Semantic search over your documents
  - Streaming responses with proper error handling
  
  **Bring:** Laptop with Python 3.9+ installed
  
  🏷️ **Track:** Workshop  
  📊 **Level:** Beginner-Intermediate  
  💰 **Included:** $100 OpenAI API credits

image_url: "[Upload: david_kim.jpg]"
ai_knowledge_base: |
  David Kim created the popular "LLM in a Weekend" course (50K students). 
  5 years at OpenAI, worked on GPT-3 and GPT-4 launches. Workshop uses 
  LangChain framework. Prerequisites: basic Python knowledge. 
  Assistants will be available for troubleshooting. Complete code 
  provided in GitHub repo.
sort_order: 2
parent_id: "[Reference: Day 2 category ID]"
```

#### AI Panel
```yaml
name: "Panel: The Future of Work in the AI Era"
content: |
  **Moderated by Tech Reporter Maya Johnson**
  
  📍 Room A | ⏰ 2:00 PM - 3:00 PM
  
  How will AI transform jobs over the next decade? Industry leaders 
  debate automation, augmentation, and the skills that matter.
  
  ---
  
  **Panelists:**
  - Sarah Chen, CEO, FutureTech
  - Dr. Robert Garcia, Labor Economist, Stanford
  - Lisa Wang, Chief People Officer, MegaCorp
  - Tom O'Brien, Union President, Tech Workers United
  
  🏷️ **Track:** AI & Machine Learning  
  📊 **Level:** All Levels  
  📱 **Live Q&A:** Submit questions via app

image_url: "[Upload: panel_image.jpg]"
ai_knowledge_base: |
  Controversial topic - expect heated debate. Garcia's research shows 
  30% of jobs will be transformed by 2030. Wang believes AI creates 
  more jobs than it eliminates. O'Brien advocates for retraining 
  programs. Audience voting on predictions built into session.
sort_order: 3
parent_id: "[Reference: Day 2 category ID]"
```

---

### Day 3 - December 12 (Friday)
```yaml
name: "Day 3 - December 12"
content: ""
image_url: null
ai_knowledge_base: |
  Day 3 focus: Advanced topics and closing ceremonies.
  Theme: "Looking Ahead"
  Special events: Hackathon judging 10am-12pm, Award ceremony 4pm
  Early departure: Luggage storage available at registration desk
sort_order: 3
parent_id: null
```

#### Closing Keynote
```yaml
name: "Closing Keynote: What I Wish I Knew"
content: |
  **🎤 Michael Torres, Founder of five unicorn startups**
  
  📍 Main Hall | ⏰ 2:00 PM - 3:00 PM
  
  After building five billion-dollar companies, Michael shares the 
  lessons that shaped his journey—and the mistakes he hopes you'll avoid.
  
  An honest, unfiltered conversation about entrepreneurship in tech.
  
  ---
  
  🏷️ **Track:** Keynote  
  📊 **Level:** All Levels  
  ⭐ **Featured Speaker**

image_url: "[Upload: michael_torres.jpg]"
ai_knowledge_base: |
  Michael Torres founded StreamTech (acquired by Netflix), 
  CloudBase (IPO), DataFlow (acquired by Salesforce), RoboInvest 
  (current), and GreenEnergy (current). Forbes 400 list. Known for 
  brutally honest talks. Will discuss: failed companies he doesn't 
  mention, mental health challenges, family sacrifices, and what 
  success really means. Standing ovation expected.
sort_order: 1
parent_id: "[Reference: Day 3 category ID]"
```

#### Awards
```yaml
name: "TechSummit Awards & Closing"
content: |
  **🏆 Celebrating Excellence in Tech**
  
  📍 Main Hall | ⏰ 4:00 PM - 5:00 PM
  
  Join us as we recognize outstanding achievements and innovations 
  from the past year.
  
  ---
  
  **Award Categories:**
  - Startup of the Year
  - Best Open Source Project
  - Diversity & Inclusion Champion
  - Breakthrough Innovation
  - Community Impact Award
  
  **Hackathon Winners:** Announced during ceremony
  
  🏷️ **Track:** All Attendees  
  🍾 **Reception follows**

image_url: "[Upload: awards_trophy.jpg]"
ai_knowledge_base: |
  Award finalists announced via app day before. Past winners include 
  now-famous startups like DataBridge and AIAssist. Hackathon prizes 
  total $50,000. Closing reception 5-7pm with open bar and networking. 
  Photo booth with speakers available. Swag bag pickup at exit.
sort_order: 2
parent_id: "[Reference: Day 3 category ID]"
```

---

## Notes for Implementation

1. **Grouped mode** organizes sessions by day (categories) and sessions (items)
2. **Digital Access** serves as conference badge holder + guide
3. Each session has speaker-specific AI knowledge
4. Include **room** and **time** prominently for navigation
5. **Track tags** help attendees filter by interest
6. Consider adding networking events as additional items
7. Update in real-time if sessions change (digital access alternative)
8. Speaker photos create visual recognition at conference


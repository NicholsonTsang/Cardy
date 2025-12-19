-- Conference - Grouped List Mode (Digital Access)
-- Template: Tech conference with sessions by day
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_day1 UUID;
    v_day2 UUID;
    v_day3 UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, image_url,
        is_access_enabled, access_token
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'TechSummit 2025 - Conference Guide',
        E'Welcome to **TechSummit 2025**! 🚀\n\nDecember 10-12 | Convention Center\n\nBrowse sessions by day, track, and speaker. Build your personalized schedule with our AI assistant.',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are a helpful conference assistant. Help attendees find relevant sessions based on their interests, navigate the venue, and answer questions about speakers and topics. Be enthusiastic about tech and help people discover talks they might not have considered.',
        E'TechSummit 2025 - Annual Technology Conference\nDates: December 10-12, 2025\nVenue: Downtown Convention Center\nAttendees: 5,000 expected\n\nVenue layout:\n- Main Hall: Keynotes (capacity 3,000)\n- Room A: AI & ML Track (500)\n- Room B: Web & Mobile Track (500)\n- Room C: Cloud & DevOps Track (500)\n- Room D: Workshops (100)\n- Expo Hall: Sponsor booths\n\nWiFi: TechSummit2025 / password: innovate2025\nApp: Download TechSummit app for live schedule updates\nMeals: Breakfast 8-9am, Lunch 12:30-2pm, Coffee breaks 10:30am & 3:30pm',
        'Welcome to TechSummit 2025! I can help you find sessions by topic, build your schedule, locate rooms, find WiFi info, or suggest talks based on your interests. What are you looking for?',
        'Great choice! For "{name}", I can share speaker bio, session objectives, prerequisites, or recommend related sessions. What would help you prepare?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Day 1
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Day 1 - December 10', '', 
        'Day 1 focus: Opening keynote and foundational sessions. Theme: "The Future of Technology". Special events: Welcome reception 6-8pm in Expo Hall. Early bird workshop: "Intro to AI" 7:30am (pre-registration required).', 1)
    RETURNING id INTO v_day1;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_day1, 'Opening Keynote: The Next Decade of Tech', E'**🎤 Sarah Chen, CEO of FutureTech**\n\n📍 Main Hall | ⏰ 9:00 AM - 10:15 AM\n\nJoin us as Sarah Chen shares her vision for the next decade of technology. From AI breakthroughs to sustainable computing, discover what''s coming and how to prepare.\n\nSarah has led FutureTech to a $50B valuation and was named "Most Influential Tech Leader" by Wired Magazine.\n\n---\n\n🏷️ **Track:** Keynote\n📊 **Level:** All Levels\n⭐ **Featured Speaker**', NULL, 'Sarah Chen founded FutureTech in 2015, grew to 10,000 employees. Previous roles: VP Engineering at Google, CTO at Stripe. Stanford CS PhD focused on distributed systems. Known for accurate predictions - called the smartphone revolution in 2005. Will discuss: AI regulation, quantum computing timeline, climate tech, and workforce evolution.', 1),
    
    (v_card_id, v_day1, 'Building Production ML Systems', E'**🎤 Dr. James Liu, ML Lead at DataScale**\n\n📍 Room A | ⏰ 10:45 AM - 11:30 AM\n\nLearn the architectural patterns and best practices for deploying machine learning models at scale. James shares lessons from running ML systems serving 100M+ predictions daily.\n\n---\n\n**Topics Covered:**\n- Feature stores and real-time inference\n- Model versioning and A/B testing\n- Monitoring and debugging ML in production\n- Cost optimization strategies\n\n🏷️ **Track:** AI & Machine Learning\n📊 **Level:** Intermediate\n💻 **Slides:** Available in app after session', NULL, 'James Liu has 12 years ML experience. PhD from MIT in predictive systems. DataScale processes 50TB data daily. Session includes live demo of their monitoring dashboard. Will share their open-source feature store framework. Good for engineers moving from prototype to production ML.', 2),
    
    (v_card_id, v_day1, 'Modern Web Performance in 2025', E'**🎤 Elena Rodriguez, Performance Engineer at Shopify**\n\n📍 Room B | ⏰ 10:45 AM - 11:30 AM\n\nWeb performance directly impacts user experience and business metrics. Discover the latest techniques for building blazing-fast web applications.\n\n---\n\n**Topics Covered:**\n- Core Web Vitals optimization\n- Image and font loading strategies\n- JavaScript bundling in 2025\n- Edge computing and CDN strategies\n\n🏷️ **Track:** Web & Mobile\n📊 **Level:** Intermediate\n🔗 **Resources:** github.com/elena/webperf-2025', NULL, 'Elena improved Shopify''s LCP by 40% last year. Previously at Google Chrome team working on performance metrics. Active contributor to web standards. Will demo real Shopify optimizations. Includes hands-on exercises if you bring laptop.', 3),
    
    (v_card_id, v_day1, 'Zero Trust Security Architecture', E'**🎤 Marcus Thompson, CISO at FinanceCloud**\n\n📍 Room C | ⏰ 10:45 AM - 11:30 AM\n\nTraditional perimeter security is dead. Learn how to implement zero trust architecture to protect your cloud infrastructure in an age of sophisticated threats.\n\n---\n\n**Topics Covered:**\n- Zero trust principles and frameworks\n- Identity-based access control\n- Micro-segmentation strategies\n- Real-world implementation case studies\n\n🏷️ **Track:** Cloud & DevOps\n📊 **Level:** Advanced\n📋 **Prerequisite:** Cloud security fundamentals', NULL, 'Marcus led security for $2T in transactions at FinanceCloud. 20+ years in cybersecurity, former NSA. Will discuss actual breach attempts and how zero trust prevented them. Covers AWS, Azure, and GCP implementations. Highly rated speaker from last year.', 4);

    -- Day 2
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Day 2 - December 11', '', 
        'Day 2 focus: Deep dive technical sessions and hands-on workshops. Theme: "Building for Scale". Special events: Speaker dinner (invite only), Birds of a Feather sessions 5-6pm. Evening: Hackathon kickoff 7pm (48-hour event).', 2)
    RETURNING id INTO v_day2;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_day2, 'Keynote: Responsible AI - Building Trust', E'**🎤 Dr. Aisha Patel, Chief Ethics Officer at TechGiant**\n\n📍 Main Hall | ⏰ 9:00 AM - 10:00 AM\n\nAs AI becomes ubiquitous, how do we ensure it serves humanity? Dr. Patel shares frameworks for ethical AI development and responsible deployment.\n\nNamed one of TIME''s 100 Most Influential People in AI.\n\n---\n\n🏷️ **Track:** Keynote\n📊 **Level:** All Levels\n⭐ **Featured Speaker**', NULL, 'Dr. Patel wrote the book "AI Ethics in Practice" (bestseller). Advises EU on AI regulation. TechGiant''s ethics board has veto power on products. Will discuss: bias in hiring algorithms, AI in healthcare decisions, deepfake detection, and open-source AI governance. Q&A session follows.', 1),
    
    (v_card_id, v_day2, 'Workshop: Building Your First LLM Application', E'**🎤 David Kim, Developer Advocate at OpenAI**\n\n📍 Room D | ⏰ 10:30 AM - 12:30 PM | **2 Hours**\n\n**⚠️ Pre-registration required - Limited to 100 attendees**\n\nHands-on workshop building a real application using GPT-4 API. You''ll leave with a working chatbot deployed to production.\n\n---\n\n**What You''ll Build:**\n- Custom chatbot with RAG (Retrieval Augmented Generation)\n- Semantic search over your documents\n- Streaming responses with proper error handling\n\n**Bring:** Laptop with Python 3.9+ installed\n\n🏷️ **Track:** Workshop\n📊 **Level:** Beginner-Intermediate\n💰 **Included:** $100 OpenAI API credits', NULL, 'David Kim created the popular "LLM in a Weekend" course (50K students). 5 years at OpenAI, worked on GPT-3 and GPT-4 launches. Workshop uses LangChain framework. Prerequisites: basic Python knowledge. Assistants will be available for troubleshooting. Complete code provided in GitHub repo.', 2),
    
    (v_card_id, v_day2, 'Panel: The Future of Work in the AI Era', E'**Moderated by Tech Reporter Maya Johnson**\n\n📍 Room A | ⏰ 2:00 PM - 3:00 PM\n\nHow will AI transform jobs over the next decade? Industry leaders debate automation, augmentation, and the skills that matter.\n\n---\n\n**Panelists:**\n- Sarah Chen, CEO, FutureTech\n- Dr. Robert Garcia, Labor Economist, Stanford\n- Lisa Wang, Chief People Officer, MegaCorp\n- Tom O''Brien, Union President, Tech Workers United\n\n🏷️ **Track:** AI & Machine Learning\n📊 **Level:** All Levels\n📱 **Live Q&A:** Submit questions via app', NULL, 'Controversial topic - expect heated debate. Garcia''s research shows 30% of jobs will be transformed by 2030. Wang believes AI creates more jobs than it eliminates. O''Brien advocates for retraining programs. Audience voting on predictions built into session.', 3);

    -- Day 3
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Day 3 - December 12', '', 
        'Day 3 focus: Advanced topics and closing ceremonies. Theme: "Looking Ahead". Special events: Hackathon judging 10am-12pm, Award ceremony 4pm. Early departure: Luggage storage available at registration desk.', 3)
    RETURNING id INTO v_day3;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_day3, 'Closing Keynote: What I Wish I Knew', E'**🎤 Michael Torres, Founder of five unicorn startups**\n\n📍 Main Hall | ⏰ 2:00 PM - 3:00 PM\n\nAfter building five billion-dollar companies, Michael shares the lessons that shaped his journey—and the mistakes he hopes you''ll avoid.\n\nAn honest, unfiltered conversation about entrepreneurship in tech.\n\n---\n\n🏷️ **Track:** Keynote\n📊 **Level:** All Levels\n⭐ **Featured Speaker**', NULL, 'Michael Torres founded StreamTech (acquired by Netflix), CloudBase (IPO), DataFlow (acquired by Salesforce), RoboInvest (current), and GreenEnergy (current). Forbes 400 list. Known for brutally honest talks. Will discuss: failed companies he doesn''t mention, mental health challenges, family sacrifices, and what success really means. Standing ovation expected.', 1),
    
    (v_card_id, v_day3, 'TechSummit Awards & Closing', E'**🏆 Celebrating Excellence in Tech**\n\n📍 Main Hall | ⏰ 4:00 PM - 5:00 PM\n\nJoin us as we recognize outstanding achievements and innovations from the past year.\n\n---\n\n**Award Categories:**\n- Startup of the Year\n- Best Open Source Project\n- Diversity & Inclusion Champion\n- Breakthrough Innovation\n- Community Impact Award\n\n**Hackathon Winners:** Announced during ceremony\n\n🏷️ **Track:** All Attendees\n🍾 **Reception follows**', NULL, 'Award finalists announced via app day before. Past winners include now-famous startups like DataBridge and AIAssist. Hackathon prizes total $50,000. Closing reception 5-7pm with open bar and networking. Photo booth with speakers available. Swag bag pickup at exit.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('conference', v_card_id, 'events', true, true, 9);

    RAISE NOTICE 'Successfully created Conference template with card ID: %', v_card_id;

END $body$;


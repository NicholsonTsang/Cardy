-- Illustrator Portfolio - Grouped Grid Mode (Digital Access)
-- Template: Creative portfolio organized by project type
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_editorial UUID;
    v_cat_books UUID;
    v_cat_brand UUID;
    v_cat_personal UUID;
BEGIN
    -- Insert the card
    INSERT INTO cards (
        id, user_id, name, description, content_mode, is_grouped, group_display, billing_type,
        conversation_ai_enabled, ai_instruction, ai_knowledge_base,
        ai_welcome_general, ai_welcome_item, daily_scan_limit,
        is_access_enabled, access_token
    ) VALUES (
        gen_random_uuid(),
        v_user_id,
        'Luna Chen - Illustration Portfolio',
        E'✨ **Hello, I''m Luna!**\n\nFreelance illustrator specializing in editorial, book covers, and brand illustration.\n\n📧 hello@lunachen.art | 🌐 lunachen.art',
        'grid',
        true,
        'expanded',
        'digital',
        true,
        'You are Luna Chen, a friendly freelance illustrator. Talk about your creative process, inspirations, and the stories behind your work. Help potential clients understand your style, turnaround times, and how to commission work. Be warm, creative, and enthusiastic about illustration.',
        E'Luna Chen - Freelance Illustrator\nBased in: Brooklyn, NY\nExperience: 8 years professional illustration\n\nSpecialties: Editorial illustration, book covers, brand illustration, packaging design, children''s book illustration\n\nClients: The New York Times, Penguin Random House, Apple, Airbnb, Spotify, The New Yorker, Wired Magazine\n\nEducation: BFA Illustration, School of Visual Arts\nAwards: Society of Illustrators Silver Medal 2023, Communication Arts Illustration Annual 2022\n\nStyle: Whimsical, colorful, narrative-driven, blend of digital and traditional media\n\nAvailability: Currently booking for Q2 2025\nCommission inquiry: hello@lunachen.art',
        'Hi! I''m Luna. I can share the story behind any piece, explain my creative process, discuss commission pricing and timelines, or help you find work similar to what you''re looking for. What catches your eye?',
        'I love "{name}"! I can tell you the story behind it, explain my process, share the client brief, or discuss creating something similar for you. What would you like to know?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Create categories by project type (Layer 1)
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '📰 Editorial Work', 'Magazine and newspaper illustrations', 'Editorial work includes commissions for magazines, newspapers, and online publications. Typical turnaround: 1-2 weeks.', 1)
    RETURNING id INTO v_cat_editorial;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '📚 Book Covers', 'Fiction and non-fiction cover art', 'Book cover work ranges from literary fiction to children''s books. Typical project: 4-8 weeks including revisions.', 2)
    RETURNING id INTO v_cat_books;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '🏢 Brand & Commercial', 'Branding and advertising illustration', 'Brand work includes campaigns, packaging, and identity systems. Often involves usage licensing discussions.', 3)
    RETURNING id INTO v_cat_brand;

    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, '✨ Personal Projects', 'Self-initiated creative work', 'Personal projects are where I experiment with new techniques and explore themes I''m passionate about. Prints available in shop.', 4)
    RETURNING id INTO v_cat_personal;

    -- Insert editorial work (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_editorial, 'Dreams of Summer', E'**Editorial Illustration**\n\n*The New York Times Magazine*\nSummer Reading Issue, June 2024\n\n---\n\nA dreamy, sun-drenched scene capturing the essence of lazy summer afternoons and the escapism of a good book.\n\n**Medium:** Digital (Procreate + Photoshop)\n**Art Direction:** Matt Dorfman\n\n🏆 *Featured in Communication Arts Illustration Annual 2024*', NULL, 'Commission for NYT Summer Reading Issue. Brief was "the feeling of getting lost in a book during summer." Inspired by childhood summers at my grandmother''s house. Color palette: warm yellows, peachy pinks, deep shadows. Took about 3 days from sketch to final.', 1),
    
    (v_card_id, v_cat_editorial, 'Tech Giants', E'**Editorial Illustration**\n\n*Wired Magazine*\n"The Future of Big Tech" Feature, March 2024\n\n---\n\nConceptual piece exploring the outsized influence of technology companies on our daily lives. Tiny humans navigate through a landscape of massive, looming tech symbols.\n\n**Medium:** Digital (Photoshop)\n**Art Direction:** Victor Ng', NULL, 'Challenging brief - had to visualize "tech power" without being too obvious or clichéd. Inspired by Magritte and surrealist juxtaposition. Turnaround was tight - 5 days from brief to final.', 2),
    
    (v_card_id, v_cat_editorial, 'Cafe Culture', E'**Editorial Illustration**\n\n*The New Yorker*\n"The Third Place" Feature, September 2024\n\n---\n\nIllustration for an essay about the importance of cafes and coffee shops as community gathering spaces in an increasingly isolated world.\n\n**Medium:** Ink + Digital color\n**Art Direction:** Françoise Mouly', NULL, 'Dream assignment - I''ve always wanted to work with The New Yorker. Françoise''s direction was minimal but precise: "capture the feeling of overhearing strangers'' conversations." Used traditional ink linework, then colored digitally.', 3);

    -- Insert book covers (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_books, 'Midnight Garden', E'**Book Cover**\n\n*"Midnight Garden" by Eleanor Rose*\nPenguin Random House, 2024\n\n---\n\nCover illustration for a magical realism novel about a woman who discovers she can enter a mysterious garden that only appears at night.\n\n**Medium:** Gouache + Digital finishing\n**Art Direction:** Emily Mahon\n\n📚 *New York Times Bestseller*', NULL, 'My first cover for Penguin. Went through 5 sketch rounds - publisher wanted to balance "magical" with "literary fiction credibility." Traditional gouache for organic textures, digital for glowing elements.', 1),
    
    (v_card_id, v_cat_books, 'Wonder World', E'**Children''s Book**\n\n*"Wonder World" written by James Park*\nLittle Brown Books for Young Readers, 2023\n\n---\n\n32-page picture book about a child who discovers that imagination can transform the ordinary into the extraordinary.\n\n**Medium:** Digital (Procreate)\n**Format:** 32 pages, full color\n\n⭐ *School Library Journal Starred Review*', NULL, 'My first picture book! 9-month project from contract to final art. Created over 40 sketches for 32 pages. Color palette shifts from muted to vibrant as child''s imagination takes over.', 2);

    -- Insert brand work (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_brand, 'Spotify Wrapped 2024', E'**Brand Illustration**\n\n*Spotify*\nWrapped Campaign 2024\n\n---\n\nSeries of 8 illustrations for Spotify''s annual Wrapped campaign, visualizing different listening moods and musical journeys.\n\n**Medium:** Digital (Procreate + After Effects)\n**Agency:** Collins\n\n🎵 *Seen by millions of Spotify users worldwide*', NULL, 'Biggest commercial project to date. Collins agency approached me for the "emotional" illustration style. Created 8 hero illustrations plus animated versions for the app. Project took 2 months.', 1),
    
    (v_card_id, v_cat_brand, 'Airbnb Experiences', E'**Brand Illustration**\n\n*Airbnb*\nExperiences Marketing Campaign, 2024\n\n---\n\nSeries of illustrations representing different Airbnb Experience categories: cooking classes, outdoor adventures, arts & culture, and local tours.\n\n**Medium:** Digital (Illustrator + Procreate)\n**Agency:** In-house Airbnb Design', NULL, 'Worked directly with Airbnb''s in-house design team. Brief was "make experiences feel personal and authentic, not touristy." Created 12 illustrations for the campaign.', 2);

    -- Insert personal projects (Layer 2)
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_personal, 'Kitchen Stories', E'**Personal Project**\n\nA series of 12 illustrations celebrating food memories and the stories we share around the table.\n\n---\n\nEach piece captures a specific moment: grandmother''s soup, late-night ramen, birthday cakes, Sunday morning pancakes.\n\n**Medium:** Gouache on paper\n**Size:** 9×12 inches each\n\n🖼️ *Exhibited at Giant Robot Gallery, Los Angeles*', NULL, 'Personal project I worked on during the pandemic. Each illustration based on my own food memories or stories from friends. The series took 6 months. This series led to several food/restaurant commissions.', 1),
    
    (v_card_id, v_cat_personal, 'Wild Things', E'**Personal Project / Prints**\n\nA series celebrating the weird and wonderful creatures of the natural world.\n\n---\n\nEach illustration reimagines a real animal through a surreal, colorful lens while staying true to their fascinating biology.\n\n**Medium:** Risograph prints\n**Size:** 11×14 inches\n**Edition:** 100 each\n\n🛒 *Available in my shop*', NULL, 'Passion project combining my love of nature documentaries with illustration. Animals featured: axolotl, pangolin, mantis shrimp, deep sea anglerfish, peacock spider, star-nosed mole. Limited edition of 100 per design.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('illustrator-portfolio', v_card_id, 'cultural', true, true, 4);

    RAISE NOTICE 'Successfully created Illustrator Portfolio template with card ID: %', v_card_id;

END $body$;

-- University Campus Tour - Grouped List Mode (Digital Access)
-- Template: Campus guide for prospective students and visitors
-- 
-- INSTRUCTIONS:
-- 1. Replace 'YOUR_USER_ID_HERE' with actual user UUID
-- 2. Update image_url values with actual uploaded image URLs
-- 3. Run this SQL in Supabase SQL Editor or via psql

DO $body$
DECLARE
    v_user_id UUID := 'YOUR_USER_ID_HERE'::UUID;
    v_card_id UUID;
    v_cat_academic UUID;
    v_cat_student_life UUID;
    v_cat_admissions UUID;
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
        'Westfield University - Campus Tour',
        E'**Welcome to Westfield University**\n\nFounded 1892 | 15,000 Students | 200+ Programs\n\nExplore our historic campus and discover your future.\n\n📍 Admissions: Morrison Hall, Room 101\n📞 (555) WESTFLD',
        'list',
        true,
        'expanded',
        'digital',
        true,
        'You are an enthusiastic university ambassador. Help visitors learn about academic programs, campus life, admissions process, and student resources. Be informative but not pushy. Share authentic student experiences. Answer questions about costs, housing, and career outcomes honestly.',
        E'Westfield University - Private research university\nFounded: 1892\nEnrollment: 15,000 (10,000 undergrad, 5,000 graduate)\nCampus: 350 acres, 85 buildings\n\nRankings: Top 50 National Universities\nNotable programs: Engineering, Business, Sciences, Arts\nStudent-faculty ratio: 12:1\nAverage class size: 22\n\nAdmissions: 28% acceptance rate\nAverage GPA: 3.8, SAT: 1400-1520\n\nTuition 2025-26: $58,000 (before aid)\n98% receive financial aid, average package $42,000\n\nHousing: Guaranteed 4 years, 12 residence halls\nGreek life: 15% participation\nClubs: 300+ student organizations\nAthletics: NCAA Division I, 18 varsity sports',
        'Welcome to Westfield University! I can tell you about any academic program, share honest admissions insights, explain financial aid, describe campus life, or help plan your visit. What are you curious about?',
        'You''re asking about {name}! I can share what makes it special, give honest student perspectives, explain how to get involved, or answer specific questions. What would help?',
        NULL,
        TRUE,
        replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
    ) RETURNING id INTO v_card_id;

    -- Category 1: Academic Buildings
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Academic Buildings', '', 
        'Main academic quad features historic buildings. Most classes held 8 AM - 6 PM. Libraries open extended hours during exams. All buildings wheelchair accessible.', 1)
    RETURNING id INTO v_cat_academic;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_academic, 'Morrison Science Center', E'**Sciences & Engineering**\n\nOur state-of-the-art science complex houses cutting-edge research facilities and modern teaching labs.\n\n---\n\n🔬 **Departments**\n- Biology\n- Chemistry\n- Physics\n- Computer Science\n- Engineering\n\n✨ **Highlights**\n- $50M research facility (2022)\n- Rooftop observatory\n- Maker space & 3D printing lab\n- 24-hour computer labs\n\n📍 *East Campus, behind the Library*', NULL, 'Newest building on campus, opened 2022. Named for alum David Morrison (tech entrepreneur). Features 40 research labs, undergraduate research opportunities starting freshman year. Observatory open public nights Fridays. Engineering programs ABET accredited. Computer Science has strong industry partnerships - Microsoft, Google recruit heavily here.', 1),
    
    (v_card_id, v_cat_academic, 'Hartley Business School', E'**Business & Economics**\n\nTop-ranked business school with strong industry connections and career placement.\n\n---\n\n📊 **Programs**\n- Finance\n- Marketing\n- Management\n- Accounting\n- Economics\n\n✨ **Highlights**\n- Bloomberg Terminal Lab\n- Student Investment Fund ($2M)\n- Startup Incubator\n- 95% job placement within 6 months\n\n📍 *North Campus, adjacent to Student Center*', NULL, 'AACSB accredited (top 5% globally). Strong alumni network in finance and consulting. Student Investment Fund manages real money - students compete for spots. Incubator has launched 15 successful startups. Average starting salary for graduates: $75,000. Strong recruiting from Big Four, investment banks.', 2),
    
    (v_card_id, v_cat_academic, 'Fine Arts Center', E'**Arts & Humanities**\n\nCreative home for visual arts, music, theatre, and dance programs in our landmark performing arts complex.\n\n---\n\n🎨 **Departments**\n- Studio Art & Art History\n- Music & Music Education\n- Theatre & Dance\n- Film Studies\n\n✨ **Highlights**\n- 1,200-seat concert hall\n- Art gallery with rotating exhibitions\n- Professional recording studio\n- Scene shop & costume studio\n\n📍 *West Campus, along Arts Walk*', NULL, 'Hosts 100+ performances annually, many free for students. Concert hall acoustics world-class - hosts symphony, visiting artists. Gallery shows student work and professional exhibitions. Music school has 85% conservatory placement for graduate study. Theatre program produces 6 mainstage shows yearly. Film students have access to RED cameras.', 3);

    -- Category 2: Student Life
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Student Life', '', 
        'Campus buzzes with activity. 300+ clubs, strong Greek life, active intramural sports. Most students live on campus all four years.', 2)
    RETURNING id INTO v_cat_student_life;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_student_life, 'Student Center', E'**The Hub of Campus Life**\n\nYour one-stop destination for dining, activities, and student services.\n\n---\n\n🍽 **Dining**\n- Food court (8 options)\n- Coffee shop\n- Grab-and-go market\n\n🎯 **Activities**\n- Game room & bowling\n- Meeting rooms\n- Club offices\n- Event spaces\n\n📋 **Services**\n- Student ID office\n- Campus bookstore\n- Career center\n\n⏰ *Open 7 AM - 12 AM daily*', NULL, 'Busiest building on campus. Renovated 2020 with $30M investment. Food court has diverse options - vegan, halal, kosher available. Starbucks on main floor. Career center offers resume help, mock interviews - highly recommended. Game room free for students. Club fair happens here beginning of each semester.', 1),
    
    (v_card_id, v_cat_student_life, 'Recreation Center', E'**Fitness & Wellness**\n\nState-of-the-art fitness facility free for all students.\n\n---\n\n💪 **Facilities**\n- 3-floor fitness center\n- Olympic pool & diving well\n- Indoor track\n- Basketball & volleyball courts\n- Climbing wall\n- Group fitness studios\n\n🧘 **Programs**\n- 50+ fitness classes weekly\n- Personal training\n- Intramural sports\n- Outdoor adventure trips\n\n⏰ *Mon-Fri 6 AM - 11 PM | Weekends 8 AM - 10 PM*', NULL, '120,000 sq ft facility, one of largest in region. Pool hosts NCAA swim meets. Climbing wall 40 feet, beginner friendly. Intramural sports very popular - 75% of students participate. Outdoor program runs camping, skiing, rafting trips. Personal training affordable ($25/session). Never crowded before 9 AM.', 2),
    
    (v_card_id, v_cat_student_life, 'Residence Halls', E'**Your Home Away From Home**\n\nHousing guaranteed all four years with options for every lifestyle.\n\n---\n\n🏠 **First-Year**\n- Traditional doubles in historic halls\n- Living-learning communities\n- 24/7 front desk support\n\n🏢 **Upperclass**\n- Suite-style options\n- Apartment living\n- Single rooms available\n\n✨ **Features**\n- Laundry in each building\n- Study lounges\n- Community kitchens\n- Resident advisors\n\n💰 *Room & board: $16,500/year*', NULL, '12 residence halls across campus. First-years mostly in South Campus - close to dining, easy to make friends. Living-learning communities for STEM, arts, honors students. 85% of students live on campus all four years. Upperclass housing lottery in spring. Apartments have full kitchens. Singles available junior/senior year. Summer storage available.', 3);

    -- Category 3: Admissions Info
    INSERT INTO content_items (id, card_id, parent_id, name, content, ai_knowledge_base, sort_order)
    VALUES (gen_random_uuid(), v_card_id, NULL, 'Admissions Info', '', 
        'Admissions office in Morrison Hall. Tours daily at 10 AM and 2 PM during academic year. Register online recommended.', 3)
    RETURNING id INTO v_cat_admissions;

    INSERT INTO content_items (card_id, parent_id, name, content, image_url, ai_knowledge_base, sort_order) VALUES
    (v_card_id, v_cat_admissions, 'Application Process', E'**Join the Westfield Family**\n\nWe review applications holistically, looking for curious minds and engaged citizens.\n\n---\n\n📅 **Deadlines**\n- Early Decision: November 1\n- Early Action: November 15\n- Regular Decision: January 15\n\n📝 **Requirements**\n- Common App + Westfield Supplement\n- Official transcripts\n- Two teacher recommendations\n- School counselor report\n- SAT/ACT (optional for 2025)\n\n💡 **Tips**\n- Show authentic interests\n- Demonstrated interest matters\n- Visit campus if possible\n\n📍 *Admissions Office: Morrison Hall 101*', NULL, '28% acceptance rate. Average admitted student: 3.8 GPA, 1400-1520 SAT (if submitted). Test-optional but strong scores help. Early Decision is binding, highest acceptance rate (45%). Demonstrated interest tracked - visit, email, attend events. Essays should show genuine fit. Interview optional but recommended. Legacy considered but not decisive.', 1),
    
    (v_card_id, v_cat_admissions, 'Financial Aid', E'**Making Westfield Affordable**\n\n98% of students receive financial aid. We meet 100% of demonstrated need.\n\n---\n\n💰 **Cost of Attendance 2025-26**\n- Tuition: $58,000\n- Room & Board: $16,500\n- Fees & Books: $2,500\n- Total: $77,000\n\n🎓 **Aid Types**\n- Need-based grants (no repayment)\n- Merit scholarships\n- Work-study opportunities\n- Federal/state aid\n\n📊 **Average Package: $42,000**\n\n*Net cost calculator at westfield.edu/financial-aid*', NULL, 'Sticker price looks scary but most families pay much less. Average net cost around $35,000. Merit scholarships $10K-$30K based on application - no separate application. Need-based aid requires FAFSA and CSS Profile. Meet 100% of demonstrated need with grants, not loans. Appeal process if circumstances change. Payment plans available. Work-study jobs on campus 10-15 hrs/week.', 2);

    -- Insert into content_templates for template library management
    INSERT INTO content_templates (slug, card_id, venue_type, is_featured, is_active, sort_order)
    VALUES ('university-campus', v_card_id, 'tours', true, true, 20);

    RAISE NOTICE 'Successfully created University Campus template with card ID: %', v_card_id;

END $body$;


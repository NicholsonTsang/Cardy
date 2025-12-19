# University Campus Tour - Grouped List (Digital Access)

A campus guide for prospective students, visitors, and new students. Grouped list organizes locations by category for easy navigation during tours.

---

## Card Settings

```yaml
name: "Westfield University - Campus Tour"
description: |
  **Welcome to Westfield University**
  
  Founded 1892 | 15,000 Students | 200+ Programs
  
  Explore our historic campus and discover your future.
  
  📍 Admissions: Morrison Hall, Room 101
  📞 (555) WESTFLD

content_mode: list
is_grouped: true
group_display: expanded
billing_type: digital
image_url: "[Upload: Campus aerial view or iconic building]"

# AI Configuration
conversation_ai_enabled: true
ai_instruction: |
  You are an enthusiastic university ambassador. Help visitors 
  learn about academic programs, campus life, admissions process, 
  and student resources. Be informative but not pushy. Share 
  authentic student experiences. Answer questions about costs, 
  housing, and career outcomes honestly.

ai_knowledge_base: |
  Westfield University - Private research university
  Founded: 1892
  Enrollment: 15,000 (10,000 undergrad, 5,000 graduate)
  Campus: 350 acres, 85 buildings
  
  Rankings: Top 50 National Universities
  Notable programs: Engineering, Business, Sciences, Arts
  Student-faculty ratio: 12:1
  Average class size: 22
  
  Admissions: 28% acceptance rate
  Average GPA: 3.8, SAT: 1400-1520
  
  Tuition 2025-26: $58,000 (before aid)
  98% receive financial aid, average package $42,000
  
  Housing: Guaranteed 4 years, 12 residence halls
  Greek life: 15% participation
  Clubs: 300+ student organizations
  Athletics: NCAA Division I, 18 varsity sports

ai_welcome_general: "Welcome to Westfield University! I can tell you about any academic program, share honest admissions insights, explain financial aid, describe campus life, or help plan your visit. What are you curious about?"
ai_welcome_item: "You're asking about {name}! I can share what makes it special, give honest student perspectives, explain how to get involved, or answer specific questions. What would help?"
```

---

## Content Items

### Category 1: Academic Buildings
```yaml
name: "Academic Buildings"
content: ""
image_url: null
ai_knowledge_base: |
  Main academic quad features historic buildings. Most classes 
  held 8 AM - 6 PM. Libraries open extended hours during exams.
  All buildings wheelchair accessible.
sort_order: 1
parent_id: null
```

#### Morrison Science Center
```yaml
name: "Morrison Science Center"
content: |
  **Sciences & Engineering**
  
  Our state-of-the-art science complex houses cutting-edge 
  research facilities and modern teaching labs.
  
  ---
  
  🔬 **Departments**
  - Biology
  - Chemistry
  - Physics
  - Computer Science
  - Engineering
  
  ✨ **Highlights**
  - $50M research facility (2022)
  - Rooftop observatory
  - Maker space & 3D printing lab
  - 24-hour computer labs
  
  📍 *East Campus, behind the Library*

image_url: "[Upload: science_center.jpg]"
ai_knowledge_base: |
  Newest building on campus, opened 2022. Named for alum David 
  Morrison (tech entrepreneur). Features 40 research labs, 
  undergraduate research opportunities starting freshman year. 
  Observatory open public nights Fridays. Engineering programs 
  ABET accredited. Computer Science has strong industry 
  partnerships - Microsoft, Google recruit heavily here.
sort_order: 1
parent_id: "[Reference: Academic Buildings]"
```

#### Hartley Business School
```yaml
name: "Hartley Business School"
content: |
  **Business & Economics**
  
  Top-ranked business school with strong industry connections 
  and career placement.
  
  ---
  
  📊 **Programs**
  - Finance
  - Marketing
  - Management
  - Accounting
  - Economics
  
  ✨ **Highlights**
  - Bloomberg Terminal Lab
  - Student Investment Fund ($2M)
  - Startup Incubator
  - 95% job placement within 6 months
  
  📍 *North Campus, adjacent to Student Center*

image_url: "[Upload: business_school.jpg]"
ai_knowledge_base: |
  AACSB accredited (top 5% globally). Strong alumni network in 
  finance and consulting. Student Investment Fund manages real 
  money - students compete for spots. Incubator has launched 
  15 successful startups. Average starting salary for graduates: 
  $75,000. Strong recruiting from Big Four, investment banks.
sort_order: 2
parent_id: "[Reference: Academic Buildings]"
```

#### Fine Arts Center
```yaml
name: "Fine Arts Center"
content: |
  **Arts & Humanities**
  
  Creative home for visual arts, music, theatre, and dance 
  programs in our landmark performing arts complex.
  
  ---
  
  🎨 **Departments**
  - Studio Art & Art History
  - Music & Music Education
  - Theatre & Dance
  - Film Studies
  
  ✨ **Highlights**
  - 1,200-seat concert hall
  - Art gallery with rotating exhibitions
  - Professional recording studio
  - Scene shop & costume studio
  
  📍 *West Campus, along Arts Walk*

image_url: "[Upload: arts_center.jpg]"
ai_knowledge_base: |
  Hosts 100+ performances annually, many free for students. 
  Concert hall acoustics world-class - hosts symphony, visiting 
  artists. Gallery shows student work and professional 
  exhibitions. Music school has 85% conservatory placement for 
  graduate study. Theatre program produces 6 mainstage shows 
  yearly. Film students have access to RED cameras.
sort_order: 3
parent_id: "[Reference: Academic Buildings]"
```

---

### Category 2: Student Life
```yaml
name: "Student Life"
content: ""
image_url: null
ai_knowledge_base: |
  Campus buzzes with activity. 300+ clubs, strong Greek life, 
  active intramural sports. Most students live on campus all 
  four years.
sort_order: 2
parent_id: null
```

#### Student Center
```yaml
name: "Student Center"
content: |
  **The Hub of Campus Life**
  
  Your one-stop destination for dining, activities, and 
  student services.
  
  ---
  
  🍽 **Dining**
  - Food court (8 options)
  - Coffee shop
  - Grab-and-go market
  
  🎯 **Activities**
  - Game room & bowling
  - Meeting rooms
  - Club offices
  - Event spaces
  
  📋 **Services**
  - Student ID office
  - Campus bookstore
  - Career center
  
  ⏰ *Open 7 AM - 12 AM daily*

image_url: "[Upload: student_center.jpg]"
ai_knowledge_base: |
  Busiest building on campus. Renovated 2020 with $30M 
  investment. Food court has diverse options - vegan, halal, 
  kosher available. Starbucks on main floor. Career center 
  offers resume help, mock interviews - highly recommended. 
  Game room free for students. Club fair happens here 
  beginning of each semester.
sort_order: 1
parent_id: "[Reference: Student Life]"
```

#### Recreation Center
```yaml
name: "Recreation Center"
content: |
  **Fitness & Wellness**
  
  State-of-the-art fitness facility free for all students.
  
  ---
  
  💪 **Facilities**
  - 3-floor fitness center
  - Olympic pool & diving well
  - Indoor track
  - Basketball & volleyball courts
  - Climbing wall
  - Group fitness studios
  
  🧘 **Programs**
  - 50+ fitness classes weekly
  - Personal training
  - Intramural sports
  - Outdoor adventure trips
  
  ⏰ *Mon-Fri 6 AM - 11 PM | Weekends 8 AM - 10 PM*

image_url: "[Upload: rec_center.jpg]"
ai_knowledge_base: |
  120,000 sq ft facility, one of largest in region. Pool hosts 
  NCAA swim meets. Climbing wall 40 feet, beginner friendly. 
  Intramural sports very popular - 75% of students participate. 
  Outdoor program runs camping, skiing, rafting trips. Personal 
  training affordable ($25/session). Never crowded before 9 AM.
sort_order: 2
parent_id: "[Reference: Student Life]"
```

#### Residence Halls
```yaml
name: "Residence Halls"
content: |
  **Your Home Away From Home**
  
  Housing guaranteed all four years with options for every 
  lifestyle.
  
  ---
  
  🏠 **First-Year**
  - Traditional doubles in historic halls
  - Living-learning communities
  - 24/7 front desk support
  
  🏢 **Upperclass**
  - Suite-style options
  - Apartment living
  - Single rooms available
  
  ✨ **Features**
  - Laundry in each building
  - Study lounges
  - Community kitchens
  - Resident advisors
  
  💰 *Room & board: $16,500/year*

image_url: "[Upload: residence_hall.jpg]"
ai_knowledge_base: |
  12 residence halls across campus. First-years mostly in 
  South Campus - close to dining, easy to make friends. 
  Living-learning communities for STEM, arts, honors students. 
  85% of students live on campus all four years. Upperclass 
  housing lottery in spring. Apartments have full kitchens. 
  Singles available junior/senior year. Summer storage available.
sort_order: 3
parent_id: "[Reference: Student Life]"
```

---

### Category 3: Admissions Info
```yaml
name: "Admissions Info"
content: ""
image_url: null
ai_knowledge_base: |
  Admissions office in Morrison Hall. Tours daily at 10 AM 
  and 2 PM during academic year. Register online recommended.
sort_order: 3
parent_id: null
```

#### Application Process
```yaml
name: "Application Process"
content: |
  **Join the Westfield Family**
  
  We review applications holistically, looking for curious 
  minds and engaged citizens.
  
  ---
  
  📅 **Deadlines**
  - Early Decision: November 1
  - Early Action: November 15
  - Regular Decision: January 15
  
  📝 **Requirements**
  - Common App + Westfield Supplement
  - Official transcripts
  - Two teacher recommendations
  - School counselor report
  - SAT/ACT (optional for 2025)
  
  💡 **Tips**
  - Show authentic interests
  - Demonstrated interest matters
  - Visit campus if possible
  
  📍 *Admissions Office: Morrison Hall 101*

image_url: "[Upload: admissions_office.jpg]"
ai_knowledge_base: |
  28% acceptance rate. Average admitted student: 3.8 GPA, 
  1400-1520 SAT (if submitted). Test-optional but strong 
  scores help. Early Decision is binding, highest acceptance 
  rate (45%). Demonstrated interest tracked - visit, email, 
  attend events. Essays should show genuine fit. Interview 
  optional but recommended. Legacy considered but not decisive.
sort_order: 1
parent_id: "[Reference: Admissions Info]"
```

#### Financial Aid
```yaml
name: "Financial Aid"
content: |
  **Making Westfield Affordable**
  
  98% of students receive financial aid. We meet 100% of 
  demonstrated need.
  
  ---
  
  💰 **Cost of Attendance 2025-26**
  - Tuition: $58,000
  - Room & Board: $16,500
  - Fees & Books: $2,500
  - Total: $77,000
  
  🎓 **Aid Types**
  - Need-based grants (no repayment)
  - Merit scholarships
  - Work-study opportunities
  - Federal/state aid
  
  📊 **Average Package: $42,000**
  
  *Net cost calculator at westfield.edu/financial-aid*

image_url: "[Upload: financial_aid.jpg]"
ai_knowledge_base: |
  Sticker price looks scary but most families pay much less. 
  Average net cost around $35,000. Merit scholarships $10K-$30K 
  based on application - no separate application. Need-based 
  aid requires FAFSA and CSS Profile. Meet 100% of demonstrated 
  need with grants, not loans. Appeal process if circumstances 
  change. Payment plans available. Work-study jobs on campus 
  10-15 hrs/week.
sort_order: 2
parent_id: "[Reference: Admissions Info]"
```

---

## Notes for Implementation

1. **Grouped List** organizes by tour themes
2. **Digital Access** works for self-guided tours and event days
3. Include **practical details** (location, hours, costs)
4. AI knowledge should cover honest admissions insights
5. Keep tone enthusiastic but authentic
6. Update statistics annually
7. Consider seasonal variations (open house vs. regular tours)



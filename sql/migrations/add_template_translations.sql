-- =================================================================
-- ADD TRADITIONAL CHINESE (zh-Hant) TRANSLATIONS TO CONTENT TEMPLATES
-- =================================================================
-- This migration adds Traditional Chinese translations to all demo
-- templates displayed on the landing page.
-- 
-- Run this in Supabase Dashboard → SQL Editor
-- =================================================================

-- Template: Modern Visions: Contemporary Art Collection
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "當代視野：現代藝術收藏展",
    "description": "歡迎來到**當代視野**展覽，展出12件突破性的當代藝術作品，挑戰感知並頌揚人類創造力。\n\n本展覽匯集新興和成熟藝術家，透過繪畫、雕塑和混合媒體探索身份、科技和自然世界的主題。\n\n🎨 點擊任何作品了解更多，並與我們的AI藝術導覽互動。",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'art-gallery-grid');

-- Template: Heritage Auctions - Spring Fine Art Sale
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "傳承拍賣行 - 春季藝術品專場",
    "description": "**2025年春季藝術品拍賣**\n\n4月15-16日 | 現場及網上競投\n\n瀏覽180多件精選繪畫、雕塑和裝飾藝術品。\n\n📞 競投登記：+1 (555) 123-4567",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'auction-house');

-- Template: Premier Motors - Vehicle Showcase
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "卓越汽車 - 車輛展示廳",
    "description": "**駕馭卓越**\n\n您的授權豪華汽車經銷商。\n提供全新、認證二手車及維修服務。\n\n📍 500 Auto Drive, Motor Mile\n⏰ 週一至週六 9 AM - 8 PM | 週日 11 AM - 5 PM\n📞 (555) PREMIER",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'car-dealership');

-- Template: The Velvet Room - Cocktail Menu
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "絲絨雅室 - 雞尾酒菜單",
    "description": "**精緻調酒。經典永恆。嶄新發現。**\n\n我們的調酒師將藝術與傳統完美融合，打造既致敬經典又突破界限的雞尾酒。每杯調酒都訴說著一個故事。\n\n🥃 向調酒師詢問適合您心情的推薦。",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'cocktail-bar');

-- Template: TechSummit 2025 - Conference Guide
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "科技峰會 2025 - 會議指南",
    "description": "歡迎來到 **科技峰會 2025**！🚀\n\n12月10-12日 | 會議中心\n\n按日期、主題和講者瀏覽會議。使用我們的AI助手建立您的個人化日程。",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'conference');

-- Template: Majestic Theatre - Season Guide
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "皇家劇院 - 本季節目指南",
    "description": "**2025年演出季**\n\n在我們的歷史悠久場地體驗世界級演出。\n\n📍 250 Broadway, Downtown\n🎭 票務處：上午10時至晚上8時開放\n📞 (555) THEATRE",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'entertainment-venue');

-- Template: MAISON ÉLISE - Spring/Summer 2025
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "MAISON ÉLISE - 2025春夏系列",
    "description": "**2025春夏系列**\n\n*「蛻變」*\n\n一段關於轉化、重生與變化之美的旅程。\n\n巴黎時裝週 | 2025年3月",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'fashion-show');

-- Template: AURUM - Seasonal Tasting Menu
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "AURUM - 季節性品嚐菜單",
    "description": "歡迎來到 **AURUM**，在這裡烹飪藝術與季節精華相遇。\n\n我們的8道菜品嚐菜單慶祝當季最優質的食材，由行政總廚陳伊莎貝拉及其團隊精心打造。\n\n🍷 提供葡萄酒配對 · 🌿 可根據要求調整飲食",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'fine-dining');

-- Template: Pulse Fitness Studio - Class Guide
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "Pulse健身工作室 - 課程指南",
    "description": "**運動。揮汗。蛻變。**\n\n精品健身體驗，旨在挑戰和啟發您。\n\n📍 456 Health Street, Suite 200\n⏰ 週一至週五 6 AM - 9 PM | 週末 7 AM - 6 PM\n📞 (555) GETPULSE",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'fitness-studio');

-- Template: Match Day Guide - City FC vs United
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "比賽日指南 - 城市FC對聯合隊",
    "description": "🏟️ **歡迎來到城市體育場！**\n\n您今天英超聯賽對決的完整指南。\n\n點擊下方查看開球時間、球隊陣容、球場地圖等。",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'football-match');

-- Template: Journey Through Time: City Heritage Museum
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "穿越時空：城市歷史博物館",
    "description": "在城市歷史博物館探索**5000年歷史**。\n\n從古代文明到現代創新，探索文物、故事和互動展示，讓我們共同的過去栩栩如生。\n\n🏛️ 點擊任何類別瀏覽展品，或使用AI導覽獲得個人化導賞。",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'history-museum');

-- Template: Grand Plaza Hotel - Guest Services
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "君悅大酒店 - 賓客服務",
    "description": "歡迎來到 **君悅大酒店** ⭐⭐⭐⭐⭐\n\n您的酒店服務及設施完整指南。\n\n📞 前台：撥0 · 🛎️ 禮賓服務：撥1",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'hotel-services');

-- Template: Luna Chen - Illustration Portfolio
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "陳露娜 - 插畫作品集",
    "description": "✨ **你好，我是露娜！**\n\n自由插畫師，專精編輯插畫、書籍封面及品牌插畫。\n\n📧 hello@lunachen.art | 🌐 lunachen.art",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'illustrator-portfolio');

-- Template: The Horizon Residences - Available Homes
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "地平線豪庭 - 待售單位",
    "description": "**奢華生活新高度**\n\n城市生活的全新標準。42層卓越住宅，盡享城市及海景全景。\n\n📍 銷售展廳：100 Waterfront Drive\n⏰ 每日開放 10 AM - 6 PM\n📞 (555) HORIZON",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'real-estate-showroom');

-- Template: Central Plaza Mall - Store Directory
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "中央廣場購物中心 - 商店目錄",
    "description": "🛍️ 歡迎來到 **中央廣場購物中心**\n\n200多間商店分佈於4層。在下方找到您喜愛的品牌。\n\n📍 顧客服務：1樓主入口附近",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'shopping-mall');

-- Template: Serenity Spa & Wellness
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "寧靜水療養生中心",
    "description": "**您的寧靜聖地**\n\n體驗精心設計的護理療程，恢復身心平衡與活力。\n\n📍 君悅酒店，地庫1層\n⏰ 每日 9:00 AM - 9:00 PM\n📞 預約：分機8888",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'spa-wellness');

-- Template: Historic Harbor District - Walking Tour
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "歷史海港區 - 步行導覽",
    "description": "探索**歷史海港區**，沿著鵝卵石街道和海濱景色，感受數百年海事歷史的活力。\n\n🚶 自助導覽 · ⏱️ 2-3小時 · 📍 8個景點",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'tourist-landmark');

-- Template: Westfield University - Campus Tour
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "西田大學 - 校園導覽",
    "description": "**歡迎來到西田大學**\n\n創校於1892年 | 15,000名學生 | 200多個課程\n\n探索我們歷史悠久的校園，發現您的未來。\n\n📍 招生辦公室：Morrison Hall, 101室\n📞 (555) WESTFLD",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'university-campus');

-- Template: Vineyard Estate Winery - Tasting Experience
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "葡園莊園酒莊 - 品酒體驗",
    "description": "**歡迎來到葡園莊園**\n\n自1978年家族經營 | 屢獲殊榮的葡萄酒\n\n探索我們的莊園葡萄酒，在酒鄉中心感受釀酒藝術。\n\n📍 1200 Vineyard Road, Napa Valley\n⏰ 品酒：每日 10 AM - 5 PM\n📞 (555) WINERY1",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'winery-tour');

-- Template: City Zoo - Animal Explorer Card
UPDATE cards 
SET translations = jsonb_set(
  COALESCE(translations, '{}'::jsonb),
  '{zh-Hant}',
  '{
    "name": "城市動物園 - 動物探索卡",
    "description": "歡迎來到 **城市動物園**！擁有來自6大洲超過500種動物的家園。\n\n使用此卡了解我們神奇的動物。點擊任何照片發現有趣的事實、保育狀況和餵食時間。\n\n🦁 有任何動物問題可以詢問AI導覽！",
    "translated_at": "2025-12-20T00:00:00Z",
    "content_hash": ""
  }'::jsonb
)
WHERE id = (SELECT card_id FROM content_templates WHERE slug = 'zoo');

-- =================================================================
-- VERIFY TRANSLATIONS WERE APPLIED
-- =================================================================
SELECT 
  ct.slug,
  c.name AS original_name,
  c.translations->'zh-Hant'->>'name' AS zh_hant_name
FROM content_templates ct
JOIN cards c ON ct.card_id = c.id
WHERE ct.is_active = true
ORDER BY ct.slug;

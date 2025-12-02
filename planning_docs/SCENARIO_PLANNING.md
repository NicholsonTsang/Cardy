# Scenario Enrichment & Implementation Plan

This document outlines the strategic expansion of CardStudio's platform to support dual pricing models (Physical vs. Digital) across five distinct content modes.

## 1. Scenario Enrichment (The Strategy Matrix)

We have enriched the original matrix with specific, high-value use cases tailored to CardStudio's "Interactive Digital Souvenir" identity.

| Content Mode | Physical Strategy (Per Card/Unit) | Digital Strategy (Per Access/Traffic) |
| :--- | :--- | :--- |
| **1. SOLO**<br>*(Profile/Identity)* | **The "Living" Artist Bio**<br>An artist sells 500 physical postcards of their painting. The QR leads to their dynamic bio, portfolio, and "Upcoming Exhibitions" list. The card is a keepsake; the content evolves.<br>*Revenue: Markup on physical card sales.* | **The Conference Connector**<br>A speaker flashes a QR code on the big screen for 30 seconds: "Scan to get my slides and contact info." 500 people scan it instantly.<br>*Revenue: 10 credits for the traffic burst.* |
| **2. STACK**<br>*(Links/Resources)* | **Luxury Product Story**<br>A high-end handbag comes with a metal card. Scanning it reveals the "Making Of" video, care instructions, and authenticity certificate.<br>*Revenue: Included in product cost (Premium Asset).* | **Campaign Landing Page**<br>A subway ad for a museum exhibition. "Scan to see a preview video and buy tickets." High volume, low retention.<br>*Revenue: Pay-per-click (scan) marketing budget.* |
| **3. CATALOG**<br>*(Menu/Shop)* | **VIP Room Service**<br>A hotel places a permanent acrylic block in every room. Guests scan to view the room service menu, spa treatments, and local tours. High frequency, permanent placement.<br>*Revenue: Flat subscription or per-unit hardware fee.* | **Pop-Up Shop Flash Sale**<br>A food truck prints a QR on 1,000 disposable napkins: "Scan for 10% off your next order." One-time engagement per user.<br>*Revenue: Prepaid traffic pack (e.g., 5,000 scans).* |
| **4. GUIDE**<br>*(Tour/Manual)* | **Museum Audio Guide**<br>The core CardStudio use case. Visitors buy a physical souvenir card. It unlocks the full audio tour of the museum. They keep the card as a memory.<br>*Revenue: Retail sales to visitors ($2/card).* | **City Walking Tour**<br>Tourism board posters at bus stops: "Scan for a free 15-minute history of this street." Public access, widely distributed.<br>*Revenue: City pays monthly based on usage volume.* |
| **5. AGENT**<br>*(AI Chat)* | **The "Haunted" Object**<br>A special card sold at a ghost tour. Scanning it lets you "chat" with the ghost of the manor. The physical card is the "medium."<br>*Revenue: High-margin souvenir sales.* | **Customer Support Bot**<br>QR code on a rental bike handlebar. "Scan to report an issue or ask for help." purely functional, high utility.<br>*Revenue: Service contract (per active conversation).* |

---

## 2. Implementation Planning

To support this dual model, we will implement a "Gatekeeper" system that enforces billing logic before serving content.

### Phase 1: Database Schema Updates

We need to modify the `cards` table to support these new modes and billing constraints.

```sql
-- Add new columns to 'cards' table
ALTER TABLE cards 
ADD COLUMN content_mode TEXT DEFAULT 'solo' CHECK (content_mode IN ('solo', 'stack', 'catalog', 'guide', 'agent')),
ADD COLUMN billing_type TEXT DEFAULT 'physical' CHECK (billing_type IN ('physical', 'digital')),
ADD COLUMN max_scans INTEGER DEFAULT NULL, -- NULL = Unlimited (Physical default)
ADD COLUMN current_scans INTEGER DEFAULT 0,
ADD COLUMN expiry_date TIMESTAMPTZ DEFAULT NULL; -- Optional time-based limit
```

### Phase 2: The "Gatekeeper" Logic (Backend)

The Gatekeeper is a middleware or Edge Function that intercepts every request to `GET /c/:card_slug` or `GET /api/card/:id`.

**Logic Flow:**

1.  **Incoming Request:** User scans QR -> `GET /c/ancient-artifacts`
2.  **Lookup:** Fetch Card metadata (`billing_type`, `current_scans`, `max_scans`, `user_id` (owner)).
3.  **Branch:**
    *   **IF `billing_type == 'physical'`:**
        *   **Allow:** Serve content immediately.
        *   **Log:** Increment `analytics_views` (for stats only, no billing impact).
    *   **IF `billing_type == 'digital'`:**
        *   **Check Quota:** Is `current_scans < max_scans`?
            *   **YES:**
                *   Increment `current_scans`.
                *   **Allow:** Serve content.
            *   **NO (Quota Exceeded):**
                *   **Check Credits:** Does Owner (`user_id`) have auto-refill enabled and sufficient `user_credits`?
                    *   **YES:** Auto-purchase booster pack (e.g., 500 scans), increment `max_scans`, serve content.
                    *   **NO:** **Block:** Serve `402 Payment Required` / "Limit Reached" page.

### Phase 3: Frontend Updates (CMS)

1.  **Card Creation Flow:**
    *   **Step 1: Choose Mode:** Select from the 5 enriched modes (Solo, Stack, Catalog, Guide, Agent).
    *   **Step 2: Choose Distribution:**
        *   "I will print this on physical cards" -> Sets `billing_type = physical` ($2/card logic).
        *   "I will share this digitally/publicly" -> Sets `billing_type = digital` (Credit-based metering).
2.  **Dashboard Analytics:**
    *   Display "Traffic Usage" bar for Digital cards (e.g., "850 / 1000 scans used").
    *   Add "Refill Traffic" button for Digital cards using existing Stripe credits system.

### Phase 4: Integration with Credit System

We will leverage the existing `user_credits` table.

*   **Digital Billing Rates:**
    *   1 Credit ($1.00) = 1,000 Scans (Standard Traffic).
    *   1 Credit ($1.00) = 100 AI Interactions (Agent Mode Traffic).
*   **Refill Mechanism:**
    *   New Stored Procedure: `refill_card_traffic(card_id, credit_amount)`
    *   Deducts from `user_credits`.
    *   Increases `cards.max_scans`.
    *   Logs to `credit_transactions` with type `traffic_purchase`.

## 3. Technical Summary

| Feature | Physical (Asset-Based) | Digital (Traffic-Based) |
| :--- | :--- | :--- |
| **Billing Trigger** | **Creation/Printing** | **Consumption/Scanning** |
| **Database Flag** | `billing_type = 'physical'` | `billing_type = 'digital'` |
| **Limit Check** | `None` (Always Allow) | `current_scans < max_scans` |
| **Cost Basis** | Per Card (e.g., $2.00) | Per 1k Scans (e.g., $1.00) |
| **Gatekeeper Action** | Log Analytics Only | Log Billing & Enforce Limit |


## Project Settings Overview

Project settings allow you to customize how your digital experience looks and behaves. Access settings by clicking the gear icon on your project card.

## Basic Settings

### Project Information

- **Project Name** - Update your project's display name
- **Description** - Edit the overview text visitors see
- **Cover Image** - Change the main visual representation

![Basic Settings](/Image/docs/project-settings-basic.png "Basic Project Settings")

### Display Settings

- **Content Mode** - Change how content is displayed (Single, List, Grid, Grouped, or Inline)
- **Grouped Layout** - Enable/disable category grouping for applicable modes
- **Original Language** - Set the source language of your content

:::warning Changing Content Mode
Changing content mode may affect how your existing content is organized. Preview changes before saving.
:::

## Digital Access Settings

### Multi-QR Code Management

Each project can have **multiple QR codes** with independent settings. This allows you to:
- Track different locations or entry points
- Set different daily limits per QR code
- Enable/disable individual codes without affecting others

![QR Management](/Image/docs/qr-management.png "QR Code Management")

### Creating QR Codes

1. Go to the **Digital Access** tab
2. Click **Add QR Code**
3. Enter a descriptive name (e.g., "Main Entrance", "Table 5")
4. Configure daily limit if needed
5. Save

### Per-QR Code Settings

Each QR code has its own:

| Setting | Description |
|---------|-------------|
| **Name** | Descriptive label for identification |
| **Enable/Disable** | Control public access for this specific QR |
| **Daily Limit** | Maximum scans per day (optional) |
| **Access Token** | Unique URL identifier |

### Daily Access Limits

Protect your project from unexpected usage spikes by setting daily limits per QR code:

- **Daily Scan Limit** - Maximum scans allowed per day for each QR code
- Leave empty for unlimited daily access (still subject to monthly budget)
- Resets at midnight

:::tip When to Use Daily Limits
Daily limits are useful for:
- Preventing abuse or bot scanning
- Distributing usage evenly throughout the month
- Protecting against unexpected viral traffic
- Testing before full launch
:::

### Refreshing QR Code Tokens

If you need to invalidate an existing QR code:

1. Open the QR code settings
2. Click the refresh icon
3. Confirm the action
4. Download and redistribute the new QR code

:::warning Token Refresh Impact
When you refresh a token, all existing copies of that QR code will stop working. Other QR codes for the same project are not affected.
:::

### Monthly Session Budget

Your monthly budget is managed at the account level:

| Plan | Monthly Budget |
|------|---------------|
| Free | 50 sessions |
| Starter | $40 (~800-1,600 sessions) |
| Premium | $280 (~6,200-14,000 sessions) |

All QR code scans across all projects count toward your monthly budget.

## AI Configuration

Configure the AI assistant for your project:

- **Enable AI Assistant** - Toggle voice/text AI conversations
- **AI Instructions** - Define behavior, tone, and focus areas
- **Knowledge Base** - Background information for the AI
- **General Welcome Message** - Greeting for the project-level assistant
- **Item Welcome Message** - Template for content-item assistants

:::info Session Costs
Projects with AI enabled are charged at the AI session rate. Disable AI to use the lower non-AI session rate.
:::

See the [AI Configuration](/docs?category=project_management&article=ai_config) guide for detailed setup.

## Translation Settings

For paid subscribers (Starter and Premium):

- **Source Language** - The original language of your content
- **Translated Languages** - View and manage translations
- **Translation Status** - Check if translations are up-to-date

| Plan | Translation Languages |
|------|----------------------|
| Free | None |
| Starter | Up to 2 languages |
| Premium | Unlimited (all 10 languages) |

## Analytics & Statistics

Track engagement with your project:

### Per-QR Code Stats
- **Today's Sessions** - Scans today
- **Monthly Sessions** - Scans this billing period
- **Total Sessions** - All-time scan count

### Project-Level Stats
- **Total Scans** - Combined across all QR codes
- **Monthly Trends** - Usage patterns over time

## Danger Zone

Critical actions that affect your project:

### Archive Project
- Hides project from active list
- Can be restored later
- Content and settings preserved

### Delete Project
- **Permanently removes** project and all content
- Removes all translations
- Deletes all QR codes and analytics data
- **Cannot be undone**

:::important Deletion Warning
Deleting a project cannot be undone. All content, translations, QR codes, and analytics data will be permanently lost. If your project is linked to a template, the template will also be deleted.
:::

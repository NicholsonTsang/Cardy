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

## Access Control Settings

### QR Code Configuration

- **Access Token** - Unique identifier for your project's QR code
- **Regenerate Token** - Create a new access token (invalidates old QR codes)
- **Enable/Disable Access** - Control whether your project is publicly accessible

![QR Settings](/Image/docs/project-settings-qr.png "QR Code Settings")

### Daily Access Limits

Protect your project from unexpected usage spikes by setting daily limits:

- **Daily Scan Limit** - Maximum scans allowed per day for this project
- Leave empty for unlimited daily access (still subject to monthly pool)

:::tip When to Use Daily Limits
Daily limits are useful for:
- Preventing abuse or bot scanning
- Distributing usage evenly throughout the month
- Protecting against unexpected viral traffic
- Testing before full launch
:::

### Monthly Access Pool

Your monthly access is shared across all projects at the subscription level:
- **Free Tier**: 50 monthly access total
- **Premium Tier**: 3,000 monthly access total

Daily limits per project help you manage how this pool is consumed.

## AI Configuration

Configure the AI assistant for your project:

- **AI Instructions** - Define behavior, tone, and focus areas
- **Knowledge Base** - Background information for the AI
- **General Welcome Message** - Greeting for the project-level assistant
- **Item Welcome Message** - Template for content-item assistants

See the [AI Configuration](/docs?category=project_management&article=ai_config) guide for detailed setup.

## Translation Settings

For Premium subscribers:

- **Source Language** - The original language of your content
- **Translated Languages** - View and manage translations
- **Translation Status** - Check if translations are up-to-date

## Analytics Settings

Track engagement with your project:

- **Total Scans** - Overall QR code usage
- **Unique Visitors** - Individual users who accessed
- **Daily/Monthly Trends** - Usage patterns over time

## Danger Zone

Critical actions that affect your project:

### Archive Project
- Hides project from active list
- Can be restored later
- Content and settings preserved

### Delete Project
- **Permanently removes** project and all content
- Removes all translations
- Deletes all analytics data
- **Cannot be undone**

:::important Deletion Warning
Deleting a project cannot be undone. All content, translations, and analytics data will be permanently lost. If your project is linked to a template, the template will also be deleted.
:::

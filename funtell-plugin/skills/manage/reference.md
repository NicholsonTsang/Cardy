# FunTell MCP Tool Reference

Complete parameter reference for all FunTell MCP tools.

## Account Tools

### `login`
Authenticate with FunTell platform credentials. **Must be called first.**
- `email` (string, required): FunTell creator account email
- `password` (string, required): FunTell creator account password

### `get_workflow`
Get the complete project creation workflow guide. Call anytime for reference.
- No parameters

### `get_subscription`
Check current user's subscription tier, project limits, session budget, and translation permissions.
- No parameters

### `get_credit_balance`
Get current user's credit balance and usage statistics.
- No parameters

## Project Tools

### `list_projects`
List all projects owned by the current user with session statistics, QR code counts, and content mode.
- No parameters

### `get_project`
Get detailed information about a specific project.
- `card_id` (UUID, required): Project ID

### `create_project`
Create a new FunTell project. Returns the project ID.
- `name` (string, required): Project name
- `description` (string, optional): Project description (markdown supported)
- `billing_type` (enum, optional, default: "digital"): `digital` or `physical`
- `content_mode` (enum, optional, default: "list"): `single`, `list`, `grid`, or `cards`
- `is_grouped` (boolean, optional, default: false): Organize into named categories
- `group_display` (enum, optional, default: "expanded"): `expanded` or `collapsed`
- `original_language` (enum, optional, default: "en"): en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th
- `conversation_ai_enabled` (boolean, optional, default: false): Enable AI assistant
- `ai_instruction` (string, optional): AI persona instructions
- `ai_knowledge_base` (string, optional): AI background knowledge
- `ai_welcome_general` (string, optional): AI welcome message (general assistant)
- `ai_welcome_item` (string, optional): AI welcome message (item-level assistant)
- `default_daily_session_limit` (number, optional, default: 500): Daily session cap (digital only)

### `update_project`
Update existing project settings. Only provide fields to change.
- `card_id` (UUID, required): Project ID to update
- All fields from `create_project` are optional

### `delete_project`
Permanently delete a project and all its content, QR codes, and translations. Cannot be undone.
- `card_id` (UUID, required): Project ID to delete

## Content Tools

### `list_content_items`
Get all content items for a project. Items with `parent_id: null` are categories; items with a `parent_id` are children.
- `card_id` (UUID, required): Project ID

### `create_content_item`
Create a single content item.
- `card_id` (UUID, required): Project ID
- `name` (string, required): Item name/title
- `parent_id` (UUID, nullable, optional): Parent category ID (null to create a category)
- `description` (string, optional): Item description (markdown supported)
- `ai_knowledge_base` (string, optional): Additional facts for AI (max 500 words)

### `create_content_items_batch`
Create multiple content items organized by categories in one call.
- `card_id` (UUID, required): Project ID
- `categories` (array, required):
  - `name` (string): Category name (use "default" for non-grouped)
  - `items` (array):
    - `name` (string): Content item name
    - `description` (string): Item description (markdown, be detailed)
    - `ai_knowledge_base` (string, optional): Additional facts for AI

### `update_content_item`
Update existing content item properties. Only provide fields to change.
- `content_item_id` (UUID, required): Content item ID
- `name` (string, optional): New name
- `description` (string, optional): New description
- `image_url` (URL, nullable, optional): New image URL
- `ai_knowledge_base` (string, optional): New AI knowledge

### `delete_content_item`
Delete a content item. Deleting a category cascades to all children.
- `content_item_id` (UUID, required): Content item ID

### `reorder_content_item`
Change the display order of a content item.
- `content_item_id` (UUID, required): Content item ID
- `new_sort_order` (integer, required): New position (0-based)

### `move_content_item`
Move a content item to a different category.
- `content_item_id` (UUID, required): Content item ID
- `new_parent_id` (UUID, nullable, required): New parent category ID (null for top-level)
- `new_sort_order` (integer, nullable, optional): Position within new parent (null for end)

## AI Tools

### `generate_ai_settings`
Auto-generate AI assistant configuration by analyzing project content.
- `card_id` (UUID, required): Project ID
- `card_name` (string, required): Project name
- `card_description` (string, optional): Project description
- `original_language` (string, optional, default: "en"): Language for generated settings
- `content_mode` (string, optional, default: "list"): Content display mode
- `is_grouped` (boolean, optional, default: false): Whether content is grouped
- `billing_type` (string, optional, default: "digital"): Billing type

Returns: `ai_instruction`, `ai_knowledge_base`, `ai_welcome_general`, `ai_welcome_item`

### `optimize_description`
Use AI to polish and improve a description.
- `description` (string, required): Description text to optimize
- `card_id` (UUID, optional): Project ID for context
- `card_name` (string, optional): Project name for context
- `original_language` (string, optional, default: "en"): Language of description

## QR Code Tools

### `list_access_tokens`
Get all QR codes for a project with session statistics and daily limits.
- `card_id` (UUID, required): Project ID

### `create_access_token`
Create a new QR code for a project. A default one is auto-created with the project.
- `card_id` (UUID, required): Project ID
- `name` (string, optional, default: "Default"): Display name (e.g., "Main Entrance", "Table 5")
- `daily_session_limit` (number, nullable, optional): Max sessions per day (null for unlimited)

### `update_access_token`
Update a QR code's properties.
- `token_id` (UUID, required): Access token ID
- `name` (string, optional): New display name
- `is_enabled` (boolean, optional): Enable or disable
- `daily_session_limit` (number, nullable, optional): New daily limit (null for unlimited)

### `delete_access_token`
Delete a QR code. Visitors can no longer access through it.
- `token_id` (UUID, required): Access token ID

# ProjectArchive Format Reference

The generated ZIP follows FunTell's ProjectArchive format (version 1), compatible with `CardBulkImport.vue` in the web portal.

## ZIP Structure

```
output.zip
├── project.json
└── images/
    └── content/
        ├── 0-item-name.jpg
        ├── 1-item-name.png
        └── ...
```

## project.json Schema

```json
{
  "version": 1,
  "exportedAt": "ISO 8601 timestamp",
  "card": {
    "name": "string",
    "description": "string",
    "original_language": "en|zh-Hant|zh-Hans|ja|ko|es|fr|ru|ar|th",
    "content_mode": "single|list|grid|cards",
    "is_grouped": true/false,
    "group_display": "expanded|collapsed",
    "billing_type": "digital|physical",
    "default_daily_session_limit": null,
    "conversation_ai_enabled": false,
    "ai_instruction": "",
    "ai_knowledge_base": "",
    "ai_welcome_general": "",
    "ai_welcome_item": "",
    "qr_code_position": "BR",
    "image": null,
    "crop_parameters": null,
    "translations": null,
    "content_hash": null
  },
  "contentItems": [
    {
      "name": "Category Name",
      "content": "",
      "ai_knowledge_base": "",
      "sort_order": 0,
      "parent_name": null,
      "image": null,
      "crop_parameters": null,
      "translations": null,
      "content_hash": null
    },
    {
      "name": "Item Name",
      "content": "Markdown description",
      "ai_knowledge_base": "",
      "sort_order": 1,
      "parent_name": "Category Name",
      "image": "images/content/1-item-name.jpg",
      "crop_parameters": null,
      "translations": null,
      "content_hash": null
    }
  ]
}
```

## Key Rules

- `parent_name: null` = category (Layer 1)
- `parent_name: "Category Name"` = item under that category (Layer 2)
- `image` field is a relative path within the ZIP (or `null` for no image)
- `sort_order` determines display order (ascending)
- Content modes: `single`, `list`, `grid`, `cards` (no `grouped` or `inline`)
- Non-grouped projects still need one category (use `"default"`)

## Script CLI Options

### doc-to-archive.py (PDF/DOCX)

```
python doc-to-archive.py input.pdf [options]

Options:
  -o, --output    Output ZIP path (default: {input}_archive.zip)
  -n, --name      Project name (default: filename)
  -l, --language  Language code (default: en)
  -m, --mode      Content mode: single|list|grid|cards (default: list)
  -g, --grouped   Force grouped categories (default: auto-detect)
```

### web-to-archive.py (Website scraping)

```
python web-to-archive.py <url> [options]

Options:
  -o, --output         Output ZIP path (default: {domain}_archive.zip)
  -n, --name           Project name (default: page title or domain)
  -l, --language       Language code (default: en)
  -m, --mode           Content mode: single|list|grid|cards (default: list)
  -g, --grouped        Force grouped categories (default: auto-detect)
  --max-depth          Maximum link depth (default: 1, max: 3)
  --max-pages          Maximum pages to scrape (default: 20, max: 100)
  --same-domain-only   Only follow same-domain links (default: true)
  --delay              Delay between requests in seconds (default: 1.0)
```

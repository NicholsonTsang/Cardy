# QR Codes & Access Management

This guide covers generating QR codes, managing access points, and controlling how visitors access your projects.

## Understanding QR Codes

Each project can have **multiple QR codes**, each acting as a separate access point. This allows you to:

- Track which QR code visitors used
- Set different limits per location
- Enable/disable specific access points
- Name codes for easy identification

## Generating QR Codes

### Creating Your First QR Code

1. Open your project
2. Go to the **QR Codes** tab
3. Click **+ Generate QR Code**
4. Enter a name for this code
5. Download or print

### QR Code Properties

| Property | Description |
|----------|-------------|
| **Name** | Identifier (e.g., "Main Entrance", "Table 5") |
| **Access Token** | Unique 12-character code |
| **Status** | Enabled or Disabled |
| **Daily Limit** | Maximum sessions per day (optional) |

### Naming Best Practices

**Good names:**
- "Front Entrance"
- "Table 12"
- "Exhibit Hall A"
- "Conference Room - Floor 2"

**Why names matter:**
- Identify which code visitors used
- Track performance by location
- Quickly find codes to manage

## Multiple QR Codes

### Why Use Multiple Codes?

| Use Case | Example |
|----------|---------|
| **Different locations** | Entrance, exhibit, exit |
| **Individual items** | Each table in a restaurant |
| **Events** | Different booths at a trade show |
| **Testing** | Separate code for internal testing |

### Managing Multiple Codes

All codes for a project appear in the QR Codes tab:

| Column | Description |
|--------|-------------|
| **Name** | Your identifier |
| **Token** | The unique code |
| **Status** | Enabled/Disabled |
| **Sessions** | Total, daily, monthly counts |
| **Actions** | Edit, download, disable, delete |

## Downloading QR Codes

### Download Options

| Format | Best For |
|--------|----------|
| **PNG** | Digital use, screens |
| **SVG** | Print materials, scaling |
| **PDF** | Professional printing |

### Download Steps

1. Click the **Download** button next to a QR code
2. Choose your format
3. Select size if applicable
4. Save the file

### QR Code Sizes

| Size | Use Case |
|------|----------|
| **Small** (200px) | Business cards, small signs |
| **Medium** (400px) | Table tents, posters |
| **Large** (800px) | Banners, large displays |

## Physical Cards (Batch Printing)

### What Are Physical Cards?

Physical cards are printed materials with QR codes that you can distribute to visitors as souvenirs or keepsakes.

### Creating a Batch

1. Go to the **Physical Cards** section
2. Click **Create Batch**
3. Enter quantity
4. Confirm credit cost
5. Download print files

### Batch Properties

| Property | Description |
|----------|-------------|
| **Quantity** | Number of unique cards |
| **Credits** | Cost in credits (2 per card) |
| **Design** | Uses project cover image |
| **QR Position** | Where code appears on card |

### Physical vs Digital Access

| Aspect | Physical Cards | Digital QR Codes |
|--------|----------------|------------------|
| **Cost** | 2 credits per card | Free to generate |
| **Uniqueness** | Each card is unique | Reusable code |
| **Tracking** | Track individual cards | Track by access point |
| **Best for** | Souvenirs, collectibles | General access |

## Access Control

### Enabling/Disabling Codes

To temporarily disable a QR code:

1. Find the code in your list
2. Toggle the **Enabled** switch off
3. Visitors scanning will see "Access disabled"

**When to disable:**
- Seasonal closures
- Event ended
- Testing complete
- Replacing old signage

### Setting Daily Limits

Limit sessions per QR code per day:

1. Edit the QR code
2. Set **Daily Session Limit**
3. Save changes

**Example uses:**
- Prevent abuse (set reasonable limit)
- Capacity management (match physical capacity)
- Budget control (limit high-traffic locations)

### What Visitors See

| Scenario | Visitor Experience |
|----------|-------------------|
| **Code disabled** | Message: "This experience is currently unavailable" |
| **Limit reached** | Message: "Daily limit reached, try again tomorrow" |
| **Code deleted** | Message: "Experience not found" |

## Session Tracking

### What is a Session?

A **session** is one visitor accessing your project. Sessions are:

- Counted when visitor first accesses
- Deduplicated (same visitor within 5 minutes = 1 session)
- Billed based on your plan

### Session Metrics

| Metric | Description |
|--------|-------------|
| **Total Sessions** | All-time for this QR code |
| **Daily Sessions** | Today's count |
| **Monthly Sessions** | Current month's count |

### Viewing Session Data

1. Go to QR Codes tab
2. View counts in the table
3. Click a code for detailed analytics

## URLs and Sharing

### Direct URLs

Each QR code has a shareable URL:

```
https://yourdomain.com/c/abc123xyz456
```

### Sharing URLs

You can share the URL directly via:
- Email
- Social media
- Messaging apps
- Website links

**Note:** URLs are permanent unless you delete the QR code.

### Custom Short URLs

The access token (e.g., `abc123xyz456`) is auto-generated. Currently, custom URLs are not supported.

## QR Code Design Tips

### Placement Guidelines

| Location | Tip |
|----------|-----|
| **Eye level** | Visitors shouldn't bend or reach |
| **Good lighting** | Phones need light to scan |
| **Stable surface** | Avoid wobbly signs |
| **Clear space** | Don't crowd with other visuals |

### Signage Best Practices

Include with your QR code:
- Brief instruction: "Scan for digital guide"
- What visitors will get: "Audio tour & more"
- No app needed: "Opens in browser"
- Language note: "Available in 10 languages"

### Print Quality

- **Minimum size:** 2cm × 2cm (0.8in × 0.8in)
- **Recommended:** 4cm × 4cm (1.5in × 1.5in) or larger
- **Contrast:** Dark code on light background
- **Test print:** Always scan before mass printing

## Troubleshooting

### QR Code Won't Scan

**Check:**
- Print quality (not blurry)
- Size (not too small)
- Lighting (not too dark)
- Damage (not torn or dirty)
- Contrast (dark on light)

**Solutions:**
- Reprint at larger size
- Improve lighting
- Replace damaged signs
- Test with multiple phones

### Visitors Can't Access

**Possible causes:**
- QR code disabled
- Daily limit reached
- Internet connectivity issues
- Very old phones may have issues

**Solutions:**
- Check code status in dashboard
- Increase or remove daily limit
- Ensure visitors have internet
- Provide direct URL as backup

### Sessions Not Counting

**Possible reasons:**
- Same visitor, same session (deduplication)
- Analytics delay (up to a few minutes)
- Page didn't fully load

**Note:** Sessions deduplicate within 5 minutes to prevent double-counting.

## Best Practices

### Organization

- **Name codes descriptively** - You'll thank yourself later
- **Document locations** - Keep a record of where codes are placed
- **Regular audits** - Remove outdated codes

### Security

- **Monitor unusual activity** - Sudden spikes may indicate issues
- **Disable unused codes** - Don't leave old codes active
- **Set reasonable limits** - Prevent abuse

### Visitor Experience

- **Test before deploying** - Scan every code yourself
- **Provide alternatives** - Display URL for scanning issues
- **Update content** - Keep information current

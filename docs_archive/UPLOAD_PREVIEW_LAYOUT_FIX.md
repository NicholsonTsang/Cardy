# Upload/Preview Layout Fix - Card Create/Edit Form

## Problem

In the card create/edit form, both the **image preview section** and the **upload/actions section** were visible at the same time, creating a confusing and redundant UI where:

1. A large empty preview container was shown even when no image was uploaded
2. The upload drop zone appeared below the empty preview
3. Users saw two separate sections for what should be one unified workflow

## Root Cause

The layout had two separate, always-visible sections:

```vue
<!-- BEFORE (Incorrect Structure) -->
<div class="space-y-6">
    <!-- Image Preview Section - ALWAYS VISIBLE -->
    <div>
        <div class="card-artwork-container ...">
            <img v-if="previewImage" ... />
            <div v-else><!-- Empty placeholder --></div>
            <div v-if="qr_code_position && previewImage"><!-- QR Code --></div>
        </div>
    </div>
    
    <!-- Upload/Actions Section - ALWAYS VISIBLE -->
    <div class="space-y-4">
        <div v-if="!previewImage"><!-- Upload drop zone --></div>
        <div v-else><!-- Action buttons --></div>
    </div>
</div>
```

### Issues

1. **Preview container always rendered** - Even with no image, showing empty placeholder
2. **Upload section always rendered** - Always present, just toggling between upload/actions
3. **Redundant structure** - Two sections doing what should be one
4. **Poor UX** - Confusing to see both sections simultaneously

## Solution

Restructured to show **only one section at a time**:
- **No Image**: Show upload drop zone + requirements info
- **Has Image**: Show preview with QR code + action buttons

```vue
<!-- AFTER (Correct Structure) -->
<div class="space-y-6">
    <!-- Image Preview Section - ONLY when image exists -->
    <div v-if="previewImage">
        <div class="card-artwork-container ...">
            <img :src="previewImage" ... />
            <div v-if="formData.qr_code_position"><!-- QR Code --></div>
        </div>
    </div>
    
    <!-- Upload/Actions Section -->
    <div class="space-y-4">
        <!-- Requirements Info - Only when no image -->
        <div v-if="!previewImage" class="p-3 bg-blue-100 rounded-lg">
            <!-- Image requirements text -->
        </div>
        
        <!-- Upload drop zone - Only when no image -->
        <div v-if="!previewImage" class="upload-drop-zone">
            <!-- Upload interface -->
        </div>
        
        <!-- Action buttons - Only when image exists -->
        <div v-else class="image-actions-only">
            <!-- Change photo / Edit crop buttons -->
        </div>
    </div>
</div>
```

## Changes Made

### File: CardCreateEditForm.vue

**1. Made Preview Section Conditional** (Line 35):
```vue
<!-- BEFORE -->
<div>
    <div class="card-artwork-container ..." :class="{ ... }">

<!-- AFTER -->
<div v-if="previewImage">
    <div class="card-artwork-container ...">
```

**2. Simplified Preview Container**:
- Removed `:class` conditional bindings (always has image when visible)
- Removed `v-if="previewImage"` from `<img>` (parent already checks)
- Removed `v-else` placeholder (not needed, section hidden when no image)
- Changed QR code condition from `formData.qr_code_position && previewImage` to just `formData.qr_code_position`

**3. Made Requirements Info Conditional** (Line 64):
```vue
<!-- BEFORE -->
<div class="p-3 bg-blue-100 rounded-lg">

<!-- AFTER -->
<div v-if="!previewImage" class="p-3 bg-blue-100 rounded-lg">
```

**4. Updated Comments**:
- Added clarifying comments: "Only when image exists", "Only when no image"
- Improved code readability

## Visual Comparison

### Before (Incorrect)

```
╔══════════════════════════════════════╗
║  Card Artwork                        ║
╟──────────────────────────────────────╢
║  ┌────────────────────────────────┐ ║
║  │                                 │ ║
║  │   [Empty Preview Container]     │ ║
║  │   (with placeholder text)       │ ║
║  │                                 │ ║
║  └────────────────────────────────┘ ║
╟──────────────────────────────────────╢
║  📘 Image Requirements Info          ║
╟──────────────────────────────────────╢
║  ┌────────────────────────────────┐ ║
║  │   📷 Add a photo                │ ║
║  │   Drag and drop or upload       │ ║
║  │   [Upload photo button]         │ ║
║  └────────────────────────────────┘ ║
╟──────────────────────────────────────╢
║  QR Code Position Dropdown           ║
╚══════════════════════════════════════╝

❌ Two sections visible (redundant)
❌ Empty preview taking up space
❌ Confusing user experience
```

### After (Correct - No Image)

```
╔══════════════════════════════════════╗
║  Card Artwork                        ║
╟──────────────────────────────────────╢
║  📘 Image Requirements Info          ║
╟──────────────────────────────────────╢
║  ┌────────────────────────────────┐ ║
║  │   📷 Add a photo                │ ║
║  │   Drag and drop or upload       │ ║
║  │   [Upload photo button]         │ ║
║  └────────────────────────────────┘ ║
╟──────────────────────────────────────╢
║  QR Code Position Dropdown           ║
╚══════════════════════════════════════╝

✅ Single section visible
✅ Clean, focused interface
✅ Clear call-to-action
```

### After (Correct - With Image)

```
╔══════════════════════════════════════╗
║  Card Artwork                        ║
╟──────────────────────────────────────╢
║  ┌────────────────────────────────┐ ║
║  │  [QR]                           │ ║
║  │         Image Preview            │ ║
║  │                                 │ ║
║  └────────────────────────────────┘ ║
╟──────────────────────────────────────╢
║  [Change photo]  [Edit crop]         ║
╟──────────────────────────────────────╢
║  QR Code Position Dropdown           ║
╚══════════════════════════════════════╝

✅ Preview prominently displayed
✅ Clear action buttons
✅ QR code overlay visible
```

## Benefits

### 1. Cleaner UI ✅
- Only one section visible at a time
- No empty placeholder containers
- Reduced visual clutter
- More professional appearance

### 2. Better UX ✅
- Clear workflow: Upload → Preview → Edit
- Immediate visual feedback when image uploads
- Focused attention on relevant controls
- Less cognitive load

### 3. Improved Performance ✅
- Fewer DOM elements when no image
- No unnecessary renders
- Faster initial load
- Better memory usage

### 4. Consistent with Content Form ✅
- CardContentCreateEditForm already used this pattern
- Now both forms have matching structure
- Easier to maintain consistency
- Unified codebase patterns

## Testing Checklist

### Card Creation
- [x] No image - shows upload drop zone only
- [x] No image - requirements info visible
- [x] No image - no empty preview container
- [x] Upload image - preview appears, upload zone disappears
- [x] Upload image - requirements info disappears
- [x] Upload image - action buttons appear

### Card Editing
- [x] Open edit with image - preview shown immediately
- [x] Open edit with image - action buttons visible
- [x] Open edit with image - no upload zone visible
- [x] Change photo - can replace image
- [x] Edit crop - can re-crop image

### Visual Validation
- [x] No duplicate sections
- [x] Smooth transitions between states
- [x] QR code overlay positions correctly
- [x] Consistent spacing and layout
- [x] Professional appearance

## Content Item Form

**Note**: The content item form (`CardContentCreateEditForm.vue`) already had the correct structure and did not require changes. It properly shows:

- Upload zone when `v-if="!previewImage"`
- Preview + actions when `v-else`

Both forms now follow the same pattern.

## Code Reduction

**Lines Removed/Simplified**:
- Removed conditional `:class` bindings (5 lines)
- Removed `v-else` placeholder section (8 lines)
- Simplified conditional checks (3 instances)
- **Net**: ~15 lines removed/simplified

**Code Quality**:
- More readable structure
- Clearer intent
- Easier to debug
- Better maintainability

## Related Issues Fixed

This change also resolved:
- Empty preview container causing layout issues
- Confusion about which section to interact with
- Redundant DOM elements affecting performance
- Inconsistency between card and content item forms

## Architecture Note

### Conditional Rendering Best Practices

**✅ DO:**
```vue
<!-- Show entire section conditionally -->
<div v-if="hasImage">
    <img :src="image" />
</div>

<div v-else>
    <UploadForm />
</div>
```

**❌ DON'T:**
```vue
<!-- Always render container, conditionally show content -->
<div>
    <img v-if="hasImage" :src="image" />
    <div v-else>placeholder</div>
</div>

<div>
    <UploadForm v-if="!hasImage" />
    <Actions v-else />
</div>
```

### Why This Matters

1. **Performance**: Don't render containers you don't need
2. **Clarity**: One section = one purpose
3. **Maintenance**: Easier to understand at a glance
4. **Accessibility**: Screen readers navigate simpler structures better

## Status

✅ **FIXED** - Card create/edit form now shows only one section at a time: upload interface when no image, or preview with actions when image exists. Matches the already-correct content item form structure.


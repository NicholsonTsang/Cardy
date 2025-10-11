# Image Cropping & Stretching Feature

This document describes the image cropping and stretching functionality implemented for the CardCreateEditForm component.

## Overview

The image cropping feature automatically detects when uploaded images don't match the configured aspect ratio and provides a user-friendly interface with two modes:
1. **Fixed Aspect Ratio Cropping** - Traditional cropping that maintains proportions
2. **Stretch Mode** - Allows free resizing and stretches the result to fit the target aspect ratio

## How It Works

### 1. Automatic Detection
When a user uploads an image:
- The system calculates the image's aspect ratio
- Compares it with the configured card aspect ratio (from environment variables)
- If the difference exceeds a tolerance of 0.01, cropping is offered

### 2. Cropping Interface
If cropping is needed:
- A modal dialog opens with the Vue Advanced Cropper component
- Users can choose between two modes:
  - **Fixed Aspect Ratio**: Traditional cropping that maintains the target aspect ratio
  - **Stretch Mode**: Free resizing that stretches the final result to fit the target aspect ratio
- Visual indicators show which mode is active (blue for fixed, amber for stretch)
- Real-time preview shows the final result

### 3. Processing
After cropping or stretching:
- **Fixed Mode**: The cropped area is used directly
- **Stretch Mode**: The selected area is resized/stretched to match the target aspect ratio
- The result is converted to a File object (JPEG format, 90% quality)
- The original image upload workflow continues with the processed version
- The preview updates to show the final image

## Components

### ImageCropper.vue
A dedicated cropping component that:
- Uses Vue Advanced Cropper for the cropping interface
- Supports both fixed aspect ratio and stretch modes
- Radio button controls for mode selection
- Visual feedback with color-coded indicators (blue/amber)
- Real-time preview with mode-specific labels
- Canvas processing for stretch functionality
- Emits crop-applied and crop-cancelled events
- Converts processed data to File objects for upload

### Updated CardCreateEditForm.vue
Enhanced with:
- Aspect ratio validation logic
- Crop dialog integration
- Automatic workflow branching (crop vs. direct upload)
- Visual indicators for cropping availability

## Configuration

The cropping feature respects the same environment variables as the card display:
- `VITE_CARD_ASPECT_RATIO_WIDTH`: Width component (default: 2)
- `VITE_CARD_ASPECT_RATIO_HEIGHT`: Height component (default: 3)

## User Experience

### Visual Indicators
- Upload area shows "Auto-crop available for X:Y ratio" message
- Clear cropping interface with aspect ratio display
- Preview of final result before applying

### Workflow Options
1. **Image matches aspect ratio**: Direct upload, no cropping needed
2. **Image needs cropping**: Cropping dialog opens automatically with mode selection
3. **Fixed Aspect Ratio Mode**: Traditional crop-to-fit behavior
4. **Stretch Mode**: Free selection with stretching to target aspect ratio
5. **User cancels cropping**: Returns to upload state, original file discarded

## Technical Implementation

### Key Functions
- `imageNeedsCropping()`: Determines if cropping is required
- `getImageDimensions()`: Loads image dimensions from file
- `handleImageUpload()`: Main upload handler with cropping logic
- `handleCropApplied()`: Processes cropped image data
- `handleCropCancelled()`: Handles crop cancellation

### Dependencies
- `vue-advanced-cropper`: Core cropping functionality
- Custom utilities in `src/utils/cardConfig.ts`

### File Processing
- Original files are preserved during cropping
- Cropped images are converted to JPEG format with 90% quality
- File names are preserved with "cropped-" prefix for debugging

## Error Handling

The system gracefully handles:
- Invalid image files
- Cropping library errors
- File conversion failures
- Dialog state management

All errors are logged to console and fallback to original upload workflow where possible.

## Future Enhancements

Potential improvements:
- Multiple aspect ratio presets
- Crop position memory/preferences
- Batch cropping for multiple images
- Advanced cropping options (rotation, filters)
- Crop history/undo functionality

# Card Aspect Ratio Configuration

This document explains how to configure the card artwork aspect ratio through environment variables.

## Environment Variables

You can now configure the card aspect ratio using the following environment variables:

- `VITE_CARD_ASPECT_RATIO_WIDTH`: Width component of the aspect ratio (default: 2)
- `VITE_CARD_ASPECT_RATIO_HEIGHT`: Height component of the aspect ratio (default: 3)

## Setup

1. Create a `.env` file in the project root (if it doesn't exist):
```bash
# Card Configuration
VITE_CARD_ASPECT_RATIO_WIDTH=2
VITE_CARD_ASPECT_RATIO_HEIGHT=3
```

2. Restart your development server for changes to take effect:
```bash
npm run dev
```

## Examples

### Standard Card (2:3 ratio)
```env
VITE_CARD_ASPECT_RATIO_WIDTH=2
VITE_CARD_ASPECT_RATIO_HEIGHT=3
```

### Square Card (1:1 ratio)
```env
VITE_CARD_ASPECT_RATIO_WIDTH=1
VITE_CARD_ASPECT_RATIO_HEIGHT=1
```

### Wide Card (16:9 ratio)
```env
VITE_CARD_ASPECT_RATIO_WIDTH=16
VITE_CARD_ASPECT_RATIO_HEIGHT=9
```

### Portrait Card (3:4 ratio)
```env
VITE_CARD_ASPECT_RATIO_WIDTH=3
VITE_CARD_ASPECT_RATIO_HEIGHT=4
```

## Implementation Details

The aspect ratio configuration is handled by:

1. **Environment Variables**: `VITE_CARD_ASPECT_RATIO_WIDTH` and `VITE_CARD_ASPECT_RATIO_HEIGHT`
2. **Utility Function**: `src/utils/cardConfig.ts` provides helper functions
3. **CSS Custom Properties**: The ratio is applied via `--card-aspect-ratio` CSS variable
4. **Components**: Both `CardView.vue` and `CardCreateEditForm.vue` use the configurable ratio

## Files Modified

- `vite.config.ts`: Added environment variable definitions
- `src/utils/cardConfig.ts`: New utility for aspect ratio configuration
- `src/components/CardComponents/CardView.vue`: Updated to use configurable aspect ratio
- `src/components/CardComponents/CardCreateEditForm.vue`: Updated to use configurable aspect ratio
- `.env.example`: Template with default values

The implementation uses CSS custom properties with fallback values, so the cards will default to 2:3 ratio if no environment variables are set.

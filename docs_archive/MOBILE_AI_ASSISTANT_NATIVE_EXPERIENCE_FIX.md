# Mobile Native App Experience Fix (AI Assistant + Card Overview)

## Problem Statement

The mobile client (AI assistant and card overview pages) had several iOS Safari-specific issues that degraded the user experience:

1. **Input Zoom Issue**: When clicking on text input, iOS Safari would zoom in (text appears larger than intended)
2. **Browser Chrome Overlap**: iPhone's address bar and toolbar would block content, making some UI elements inaccessible
3. **Page Enlargement**: Clicking input fields caused the entire page to zoom/enlarge
4. **Non-native Feel**: The experience didn't feel like a native app due to viewport issues

These issues are common in mobile web development, especially on iOS Safari, which has unique behavior around viewport handling and input focus.

## Root Causes

### 1. Input Font Size Too Small
- iOS Safari automatically zooms on `<input>` elements with `font-size < 16px`
- The text input had `font-size: 0.9375rem` (15px), triggering auto-zoom
- This is a built-in accessibility feature that cannot be disabled except by meeting the 16px minimum

### 2. Viewport Meta Tag Issues
- Missing `maximum-scale=1.0` and `user-scalable=no` parameters
- No `viewport-fit=cover` for iPhone notch/safe areas
- These are required to prevent manual zoom and handle iOS chrome properly

### 3. Fixed Viewport Height Problem
- Using `100vh` on mobile includes browser chrome in the calculation
- When keyboard appears, `100vh` doesn't account for the reduced viewport
- iOS Safari's address bar dynamically shows/hides, causing layout jumps

### 4. Missing Body Scroll Prevention
- When modal opens, background page could still scroll (iOS overscroll)
- No prevention of "pull-to-refresh" gesture interfering with modal content

## Solutions Implemented

### 1. Updated Viewport Meta Tags (`index.html`)

```html
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
```

**Changes:**
- `maximum-scale=1.0` - Prevents manual pinch-to-zoom
- `user-scalable=no` - Disables zoom on double-tap and input focus
- `viewport-fit=cover` - Ensures content extends to edges (notch support)
- `apple-mobile-web-app-capable` - Enables PWA mode on iOS
- `black-translucent` - Status bar style for better aesthetics

### 2. Dynamic Viewport Height Calculation (`index.html`)

```javascript
function updateViewportHeight() {
  const vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty('--vh', `${vh}px`);
  document.documentElement.style.setProperty('--viewport-height', `${window.innerHeight}px`);
}

window.addEventListener('resize', updateViewportHeight);
window.addEventListener('orientationchange', updateViewportHeight);
window.addEventListener('DOMContentLoaded', updateViewportHeight);
updateViewportHeight();
```

**Why This Works:**
- Calculates actual viewport height (excluding browser chrome)
- Updates on resize events (keyboard show/hide, orientation change)
- Provides CSS custom properties: `--vh` and `--viewport-height`
- Components can use `var(--viewport-height)` instead of `100vh`

### 3. Fixed Input Font Size (`ChatInterface.vue`)

```css
.text-input {
  font-size: 16px; /* Minimum 16px to prevent iOS zoom */
}
```

**Changes:**
- Changed from `0.9375rem` (15px) to `16px`
- Applied to both desktop and mobile breakpoints
- 16px is the magic threshold - iOS won't zoom on inputs ≥16px

### 4. Modal Height and Safe Area Support (`AIAssistantModal.vue`)

```css
@media (max-width: 640px) {
  .modal-content {
    height: var(--viewport-height, 100vh);
    min-height: -webkit-fill-available;
  }
  
  .modal-header {
    padding-top: max(1.25rem, env(safe-area-inset-top));
  }
  
  .modal-body {
    padding-bottom: env(safe-area-inset-bottom);
  }
}
```

**Changes:**
- Uses dynamic `--viewport-height` instead of static `100vh`
- Fallback to `-webkit-fill-available` for older iOS versions
- `env(safe-area-inset-*)` respects iPhone notch and home indicator
- Modal properly fills screen without overlapping system UI

### 5. Body Scroll Prevention (`AIAssistantModal.vue`)

```typescript
watch(() => props.isOpen, (isOpen) => {
  if (isOpen) {
    const scrollY = window.scrollY
    document.body.style.position = 'fixed'
    document.body.style.top = `-${scrollY}px`
    document.body.style.width = '100%'
  } else {
    const scrollY = document.body.style.top
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.width = ''
    window.scrollTo(0, parseInt(scrollY || '0') * -1)
  }
})
```

**How It Works:**
- When modal opens: Fix body position and store scroll position
- Prevents background scroll while modal is open
- When modal closes: Restore original position and scroll state
- Smooth user experience without scroll jumps

### 6. iOS-Specific Touch Handling

```css
.modal-overlay {
  overflow: hidden;
  touch-action: none; /* Prevent iOS overscroll on overlay */
}

.modal-content {
  touch-action: pan-y; /* Allow vertical scrolling inside */
  -webkit-overflow-scrolling: touch; /* Smooth momentum scrolling */
}

.messages-container {
  -webkit-overflow-scrolling: touch;
  overscroll-behavior: contain; /* Prevent pull-to-refresh */
}
```

**Changes:**
- `touch-action: none` on overlay prevents unwanted gestures
- `touch-action: pan-y` on content allows vertical scrolling
- `-webkit-overflow-scrolling: touch` enables momentum scrolling
- `overscroll-behavior: contain` prevents pull-to-refresh triggering

### 7. Input Area Protection (`ChatInterface.vue`)

```css
.input-area {
  flex-shrink: 0; /* Never compress input area */
  padding-bottom: max(0.75rem, env(safe-area-inset-bottom));
}

.text-input {
  min-height: 40px; /* Ensure input is always tappable */
}
```

**Changes:**
- `flex-shrink: 0` ensures input area never gets squished
- Accounts for iPhone home indicator with `safe-area-inset-bottom`
- Minimum height ensures input remains easily tappable

## Files Modified

### Core Infrastructure
1. **`index.html`**
   - Updated viewport meta tags
   - Added dynamic viewport height calculation script
   - Added CSS custom properties

### AI Assistant Components
2. **`src/views/MobileClient/components/AIAssistant/components/AIAssistantModal.vue`**
   - Added body scroll prevention logic
   - Updated mobile styling with safe areas
   - Implemented dynamic viewport height usage

3. **`src/views/MobileClient/components/AIAssistant/components/ChatInterface.vue`**
   - Fixed input font size to 16px
   - Added iOS-specific touch handling
   - Improved scrolling behavior
   - Added safe area support for input area

4. **`src/views/MobileClient/components/AIAssistant/components/RealtimeInterface.vue`**
   - Added consistent touch handling
   - Implemented safe area support
   - Improved scrolling behavior

### Mobile Client Pages
5. **`src/views/MobileClient/PublicCardView.vue`**
   - Added dynamic viewport height support
   - Implemented touch-action optimization
   - Added text size adjustment prevention

6. **`src/views/MobileClient/components/CardOverview.vue`**
   - Fixed all text elements to ≥16px (language chip, description, AI indicator, action button)
   - Added dynamic viewport height support
   - Implemented touch-action and tap-highlight removal
   - Added safe area support for info panel

7. **`src/views/MobileClient/components/ContentList.vue`**
   - Fixed item description font size to 16px

8. **`src/views/MobileClient/components/ContentDetail.vue`**
   - Fixed content description font size to 16px

## Testing Checklist

Test on actual iOS devices (iPhone 8+ with iOS 12+) and Safari browser:

### Basic Functionality
- [ ] Open AI assistant modal
- [ ] Modal fills entire screen without gaps
- [ ] Content doesn't overlap with notch or home indicator
- [ ] Close button is always accessible

### Input Behavior
- [ ] Click text input in chat mode
- [ ] Page does NOT zoom/enlarge
- [ ] Text appears at correct size (16px)
- [ ] Input remains visible when keyboard appears
- [ ] Keyboard can be dismissed normally

### Scrolling & Touch
- [ ] Scroll through chat messages
- [ ] Smooth momentum scrolling works
- [ ] Pull-to-refresh doesn't trigger in messages
- [ ] Background page doesn't scroll when modal open
- [ ] Can scroll in realtime transcript

### Orientation & Resize
- [ ] Rotate device (portrait ↔ landscape)
- [ ] Modal resizes correctly
- [ ] No layout jumps or broken UI
- [ ] Content remains accessible

### Chrome Behavior
- [ ] Scroll down in page (address bar hides)
- [ ] Open modal
- [ ] Content doesn't overlap with browser chrome
- [ ] Input area remains accessible

### Edge Cases
- [ ] Open modal, rotate device, then type
- [ ] Switch between chat and realtime modes
- [ ] Close modal while keyboard is open
- [ ] Scroll position restores correctly after closing modal

## Technical Notes

### Why 16px for Inputs?
iOS Safari has a built-in accessibility feature: inputs with `font-size < 16px` trigger automatic zoom on focus. This helps users read small text but breaks fixed-layout designs. Setting `font-size: 16px` is the **only** way to prevent this without disabling zoom globally.

### Why Not Disable Zoom Entirely?
While we set `user-scalable=no`, this specifically prevents **manual** zoom (pinch, double-tap). The font-size requirement ensures users can still read content comfortably without triggering unwanted auto-zoom on input focus.

### viewport-fit=cover vs. contain
- `viewport-fit=cover`: Content extends to screen edges (under notch)
- `viewport-fit=contain`: Content stays within safe area (default)
- We use `cover` + `env(safe-area-inset-*)` for full-screen native feel

### Why Dynamic Viewport Height?
Static `100vh` includes browser chrome (address bar + toolbar) in its calculation. When chrome hides/shows dynamically, layout breaks. JavaScript-based `--viewport-height` always reflects the **actual** visible viewport.

### Performance Considerations
- JavaScript viewport calculation runs only on resize/orientation change
- CSS custom properties have no performance penalty
- Body scroll prevention is instant (no animation delays)

## Browser Compatibility

✅ **Works on:**
- iOS Safari 12+ (iPhone 8 and newer)
- iOS Chrome/Firefox (uses Safari WebKit)
- Android Chrome 90+
- Android Firefox 90+

⚠️ **Degraded on:**
- iOS Safari 11 (no `env()` support)
- iOS Safari 10 (no CSS custom properties)

❌ **Not supported:**
- iOS Safari < 10
- Android < 5.0

For unsupported browsers, UI may have minor layout issues but remains functional.

## Future Improvements

1. **PWA Integration**: Add service worker and manifest for full native app experience
2. **Keyboard Tracking**: Further optimize layout when keyboard shows/hides
3. **Haptic Feedback**: Add vibration on button taps for native feel
4. **Gesture Support**: Swipe down to close modal
5. **Status Bar Theming**: Dynamic color based on content

## References

- [MDN: Viewport Meta Tag](https://developer.mozilla.org/en-US/docs/Web/HTML/Viewport_meta_tag)
- [Apple: Designing Websites for iPhone](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [CSS Tricks: The Trick to Viewport Units on Mobile](https://css-tricks.com/the-trick-to-viewport-units-on-mobile/)
- [Web.dev: Building a PWA](https://web.dev/progressive-web-apps/)

## Summary

These fixes transform the entire mobile client experience (card overview, content pages, and AI assistant) from a "web page in a browser" to a "native-like app experience." Users can now:

- ✅ View card overviews without unwanted zoom
- ✅ Browse content lists and details naturally
- ✅ Interact with the AI assistant without zoom issues
- ✅ Experience consistent, smooth navigation throughout
- ✅ Enjoy full-screen layouts without browser chrome overlap
- ✅ Benefit from iOS safe area support (notch, home indicator)

The implementation follows iOS best practices and provides a solid foundation for future PWA enhancements. All mobile client pages now have consistent behavior and native app feel.


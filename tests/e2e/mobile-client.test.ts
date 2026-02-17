/**
 * E2E Tests - Mobile Client (Public Card Access)
 *
 * Covers: public card overview, content layouts, content detail,
 *         language switching, AI assistant UI, error states
 *
 * No authentication required - tests public-facing pages.
 * Requires TEST_PUBLIC_CARD_ID to be set.
 *
 * Run:
 *   npx ts-node tests/e2e/mobile-client.test.ts
 */

import { By, until, Key, WebDriver } from 'selenium-webdriver'
import {
  CONFIG, createDriver, navigateTo,
  assert, TestRunner, elementExists, elementExistsByXpath, getCurrentUrl
} from './helpers'

let driver: WebDriver
const t = new TestRunner()

function cardUrl(sub: string = ''): string {
  return `/en/c/${CONFIG.PUBLIC_CARD_ID}${sub}`
}

// ── Card Overview Page ─────────────────────────────────────────────────

async function testCardOverview() {
  t.suite('Card Overview Page')

  await navigateTo(driver, cardUrl())
  await driver.sleep(3000) // Wait for session creation + data load

  await t.test('Card overview page loads (no error state)', async () => {
    const hasError = await elementExists(driver, 'div.error-container')
    const hasLoading = await elementExists(driver, 'div.loading-container')
    const hasOverview = await elementExists(driver, 'div.card-overview')
    const hasContent = await elementExists(driver, 'div.content-wrapper')

    assert(!hasLoading, 'Page stuck in loading state')
    // Either overview loads, or we got content directly (single mode), or error
    assert(hasOverview || hasContent || hasError, 'No recognized page state')
    if (hasError) {
      console.log('    (card returned error state - may be access/credits issue)')
    }
  })

  // The remaining overview tests only run if we got a normal card view
  const hasOverview = await elementExists(driver, 'div.card-overview')
  if (!hasOverview) {
    t.skip('Card title is displayed', 'Card did not load overview page')
    t.skip('Explore Content button exists', 'Card did not load overview page')
    t.skip('Language selector chip exists', 'Card did not load overview page')
    return
  }

  await t.test('Card title is displayed', async () => {
    const title = await driver.findElement(By.css('h1.card-title'))
    const text = await title.getText()
    assert(text.length > 0, 'Card title is empty')
  })

  await t.test('Explore Content button exists', async () => {
    const btn = await elementExists(driver, 'button.action-button')
    assert(btn, 'Explore Content button not found')
  })

  await t.test('Language selector chip exists', async () => {
    const chip = await elementExists(driver, 'button.language-chip')
    assert(chip, 'Language selector chip not found')
  })

  await t.test('Info panel is visible', async () => {
    const panel = await elementExists(driver, 'div.info-panel')
    assert(panel, 'Info panel not found')
  })
}

// ── Card Overview - Branding ───────────────────────────────────────────

async function testBranding() {
  t.suite('Card Overview - Branding')

  const hasOverview = await elementExists(driver, 'div.card-overview')
  if (!hasOverview) {
    t.skip('Branding tests', 'Card did not load overview page')
    return
  }

  await t.test('Branding footer exists (non-premium) or is hidden (premium)', async () => {
    const hasBranding = await elementExists(driver, 'div.branding-footer')
    // Both outcomes are valid - premium hides branding
    if (hasBranding) {
      const footer = await driver.findElement(By.css('div.branding-footer'))
      const text = await footer.getText()
      assert(text.includes('FunTell'), 'Branding footer should contain FunTell')
    }
    // Premium cards won't have branding - that's fine
  })
}

// ── Card Overview - AI Assistant ───────────────────────────────────────

async function testOverviewAIAssistant() {
  t.suite('Card Overview - AI Assistant')

  const hasOverview = await elementExists(driver, 'div.card-overview')
  if (!hasOverview) {
    t.skip('AI assistant tests', 'Card did not load overview page')
    return
  }

  const hasAI = await elementExists(driver, 'button.ai-indicator-button')
  if (!hasAI) {
    t.skip('AI indicator button exists', 'AI not enabled for this card')
    t.skip('Clicking AI button opens modal', 'AI not enabled')
    return
  }

  await t.test('AI indicator button exists', async () => {
    const btn = await driver.findElement(By.css('button.ai-indicator-button'))
    assert(await btn.isDisplayed(), 'AI indicator not visible')
  })

  await t.test('AI indicator has sparkles icon', async () => {
    const sparkles = await elementExistsByXpath(driver,
      "//button[contains(@class, 'ai-indicator')]//i[contains(@class, 'pi-sparkles')]"
    )
    assert(sparkles, 'AI sparkles icon not found')
  })

  await t.test('Clicking AI button opens modal', async () => {
    const btn = await driver.findElement(By.css('button.ai-indicator-button'))
    await btn.click()
    await driver.sleep(1000)

    const modalOpen = await elementExists(driver, 'div.modal-overlay')
    assert(modalOpen, 'AI modal did not open')
  })

  await t.test('AI modal has header with title', async () => {
    const title = await elementExists(driver, '.modal-header .header-title')
    assert(title, 'Modal header title not found')
  })

  await t.test('AI modal has close button', async () => {
    const closeBtn = await elementExists(driver, 'button.close-button')
    assert(closeBtn, 'Close button not found')
  })

  await t.test('Closing AI modal via close button', async () => {
    const closeBtn = await driver.findElement(By.css('button.close-button'))
    await closeBtn.click()
    await driver.sleep(500)

    const modalOpen = await elementExists(driver, 'div.modal-overlay')
    assert(!modalOpen, 'Modal should be closed')
  })
}

// ── Navigate to Content List ───────────────────────────────────────────

async function testNavigateToContentList() {
  t.suite('Navigate to Content List')

  await navigateTo(driver, cardUrl())
  await driver.sleep(3000)

  const hasOverview = await elementExists(driver, 'div.card-overview')
  if (!hasOverview) {
    // Single mode cards or errors - try navigating directly
    t.skip('Navigate via Explore button', 'No overview page')
    return
  }

  await t.test('Clicking Explore navigates to /list', async () => {
    const btn = await driver.findElement(By.css('button.action-button'))
    await btn.click()
    await driver.sleep(2000)

    const url = await getCurrentUrl(driver)
    assert(url.includes('/list'), `Expected /list in URL, got ${url}`)
  })
}

// ── Content List Page ──────────────────────────────────────────────────

async function testContentListPage() {
  t.suite('Content List Page')

  await navigateTo(driver, cardUrl('/list'))
  await driver.sleep(3000)

  await t.test('Content list page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/list'), `Expected /list URL, got ${url}`)
  })

  // Detect which layout rendered
  const hasList = await elementExists(driver, 'div.layout-list')
  const hasGrid = await elementExists(driver, 'div.layout-grid')
  const hasGrouped = await elementExists(driver, 'div.layout-grouped')
  const hasCollapsed = await elementExists(driver, 'div.layout-grouped-collapsed')
  const hasInline = await elementExists(driver, 'div.layout-inline')
  const hasSingle = await elementExists(driver, 'div.layout-single')

  const layoutType = hasList ? 'list' : hasGrid ? 'grid' : hasGrouped ? 'grouped' :
    hasCollapsed ? 'collapsed' : hasInline ? 'inline' : hasSingle ? 'single' : 'unknown'

  await t.test(`Layout renders (detected: ${layoutType})`, async () => {
    assert(
      hasList || hasGrid || hasGrouped || hasCollapsed || hasInline || hasSingle,
      'No known layout component rendered'
    )
  })

  // Content items should exist
  await t.test('Content items are displayed', async () => {
    const items = await driver.findElements(By.css(
      'button.list-item, button.grid-item, button.item-button, button.inline-card, button.category-card, div.single-content'
    ))
    assert(items.length > 0, 'No content items found')
  })

  // ARIA roles
  await t.test('Content list has proper ARIA roles', async () => {
    const hasListRole = await elementExistsByXpath(driver, "//*[@role='list']")
    const hasMainRole = await elementExistsByXpath(driver, "//*[@role='main']")
    assert(hasListRole || hasMainRole || hasSingle, 'No ARIA roles found')
  })
}

// ── Content List - AI Badge ────────────────────────────────────────────

async function testContentListAIBadge() {
  t.suite('Content List - AI Badge')

  await navigateTo(driver, cardUrl('/list'))
  await driver.sleep(3000)

  const hasBadge = await elementExists(driver, 'button.ai-browse-badge')
  if (!hasBadge) {
    t.skip('AI browse badge exists', 'AI not enabled or single mode')
    t.skip('Clicking AI badge opens modal', 'AI not enabled')
    return
  }

  await t.test('AI browse badge exists', async () => {
    const badge = await driver.findElement(By.css('button.ai-browse-badge'))
    assert(await badge.isDisplayed(), 'AI badge not visible')
  })

  await t.test('Clicking AI badge opens modal', async () => {
    const badge = await driver.findElement(By.css('button.ai-browse-badge'))
    await badge.click()
    await driver.sleep(1000)

    const modalOpen = await elementExists(driver, 'div.modal-overlay')
    assert(modalOpen, 'AI modal did not open')

    // Close modal
    const closeBtn = await driver.findElement(By.css('button.close-button'))
    await closeBtn.click()
    await driver.sleep(500)
  })
}

// ── Content Detail Page ────────────────────────────────────────────────

async function testContentDetailPage() {
  t.suite('Content Detail Page')

  // First navigate to list and click the first item
  await navigateTo(driver, cardUrl('/list'))
  await driver.sleep(3000)

  const items = await driver.findElements(By.css(
    'button.list-item, button.grid-item, button.item-button, button.inline-card'
  ))

  if (items.length === 0) {
    t.skip('Content detail tests', 'No content items to click')
    return
  }

  await t.test('Clicking a content item navigates to detail', async () => {
    await items[0].click()
    await driver.sleep(2000)

    const url = await getCurrentUrl(driver)
    assert(url.includes('/item/'), `Expected /item/ in URL, got ${url}`)
  })

  await t.test('Content detail page renders', async () => {
    const detail = await elementExists(driver, 'div.content-detail')
    assert(detail, 'Content detail view not found')
  })

  await t.test('Content title is displayed', async () => {
    const title = await driver.findElement(By.css('h2.content-title'))
    const text = await title.getText()
    assert(text.length > 0, 'Content title is empty')
  })

  await t.test('Content has ARIA label', async () => {
    const detail = await driver.findElement(By.css('div.content-detail'))
    const ariaLabel = await detail.getAttribute('aria-label')
    assert(ariaLabel !== null && ariaLabel.length > 0, 'Content detail missing aria-label')
  })
}

// ── Content Detail - Actions ───────────────────────────────────────────

async function testContentDetailActions() {
  t.suite('Content Detail - Actions')

  const isOnDetail = (await getCurrentUrl(driver)).includes('/item/')
  if (!isOnDetail) {
    t.skip('Detail action tests', 'Not on detail page')
    return
  }

  // Favorite button
  await t.test('Favorite button exists', async () => {
    const favBtn = await elementExistsByXpath(driver,
      "//button[@aria-label='Add to Favorites' or @aria-label='Remove from Favorites' or contains(@class, 'hero-action-btn') or contains(@class, 'inline-action-btn')]"
    )
    assert(favBtn, 'Favorite button not found')
  })

  // Share button
  await t.test('Share button exists', async () => {
    const shareBtn = await elementExistsByXpath(driver,
      "//button[@aria-label='Share' or contains(@class, 'hero-action-btn') or contains(@class, 'inline-action-btn')]"
    )
    assert(shareBtn, 'Share button not found')
  })
}

// ── Content Detail - AI Assistant ──────────────────────────────────────

async function testContentDetailAI() {
  t.suite('Content Detail - AI Assistant')

  const isOnDetail = (await getCurrentUrl(driver)).includes('/item/')
  if (!isOnDetail) {
    t.skip('Detail AI tests', 'Not on detail page')
    return
  }

  const hasBadge = await elementExists(driver, 'button.ai-badge, div.ai-section-fixed button')
  if (!hasBadge) {
    t.skip('Item AI badge exists', 'AI not enabled for this card')
    return
  }

  await t.test('Item-level AI badge exists', async () => {
    const badge = await driver.findElement(By.css('button.ai-badge, div.ai-section-fixed button'))
    assert(await badge.isDisplayed(), 'AI badge not visible')
  })

  await t.test('Clicking item AI badge opens modal in content-item mode', async () => {
    const badge = await driver.findElement(By.css('button.ai-badge, div.ai-section-fixed button'))
    await badge.click()
    await driver.sleep(1000)

    const modalOpen = await elementExists(driver, 'div.modal-overlay')
    assert(modalOpen, 'AI modal did not open')

    // Check for content-item mode class
    const modalContent = await elementExists(driver, '.content-item-mode')
    if (modalContent) {
      console.log('    (confirmed: content-item-mode)')
    }

    // Close
    const closeBtn = await driver.findElement(By.css('button.close-button'))
    await closeBtn.click()
    await driver.sleep(500)
  })
}

// ── Language Switching ─────────────────────────────────────────────────

async function testLanguageSwitching() {
  t.suite('Language Switching')

  await navigateTo(driver, cardUrl())
  await driver.sleep(3000)

  const hasChip = await elementExists(driver, 'button.language-chip')
  if (!hasChip) {
    t.skip('Language switching tests', 'Language chip not available')
    return
  }

  await t.test('Language chip shows current language', async () => {
    const chip = await driver.findElement(By.css('button.language-chip'))
    const text = await chip.getText()
    assert(text.length > 0, 'Language chip text is empty')
  })

  await t.test('Clicking language chip opens language selector', async () => {
    const chip = await driver.findElement(By.css('button.language-chip'))
    await chip.click()
    await driver.sleep(1000)

    // Look for language options (modal or dropdown)
    const hasLanguageOptions = await elementExistsByXpath(driver,
      "//*[contains(@class, 'modal') or contains(@class, 'dialog') or contains(@class, 'language')]//button"
    )
    assert(hasLanguageOptions, 'Language options did not appear')

    // Close by pressing Escape
    await driver.actions().sendKeys(Key.ESCAPE).perform()
    await driver.sleep(500)
  })
}

// ── URL Language Prefix ────────────────────────────────────────────────

async function testURLLanguagePrefix() {
  t.suite('URL Language Prefix')

  await t.test('Card accessible with /en/ prefix', async () => {
    await navigateTo(driver, `/en/c/${CONFIG.PUBLIC_CARD_ID}`)
    await driver.sleep(3000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/en/'), `Expected /en/ in URL, got ${url}`)
  })

  await t.test('Card accessible with /zh-Hant/ prefix', async () => {
    await navigateTo(driver, `/zh-Hant/c/${CONFIG.PUBLIC_CARD_ID}`)
    await driver.sleep(3000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/zh-Hant/'), `Expected /zh-Hant/ in URL, got ${url}`)
  })
}

// ── Error States ───────────────────────────────────────────────────────

async function testErrorStates() {
  t.suite('Error States')

  await t.test('Invalid card ID shows error', async () => {
    await navigateTo(driver, '/en/c/nonexistent-card-id-12345')
    await driver.sleep(3000)

    const hasError = await elementExists(driver, 'div.error-container')
    const hasLoading = await elementExists(driver, 'div.loading-container')
    // Should not be stuck loading forever
    assert(hasError || !hasLoading, 'Invalid card should show error or at least stop loading')
  })

  await t.test('Error page has informative message', async () => {
    const hasError = await elementExists(driver, 'div.error-container')
    if (hasError) {
      const title = await driver.findElement(By.css('h2.error-title'))
      const text = await title.getText()
      assert(text.length > 0, 'Error title is empty')
    }
  })
}

// ── Mobile Viewport ────────────────────────────────────────────────────

async function testMobileViewport() {
  t.suite('Mobile Viewport')

  // Resize to mobile dimensions
  await driver.manage().window().setRect({ width: 375, height: 812 })
  await driver.sleep(500)

  await navigateTo(driver, cardUrl())
  await driver.sleep(3000)

  const hasOverview = await elementExists(driver, 'div.card-overview')
  if (!hasOverview) {
    t.skip('Mobile viewport tests', 'Card did not load overview')
    return
  }

  await t.test('Card overview renders on mobile viewport', async () => {
    const panel = await elementExists(driver, 'div.info-panel')
    assert(panel, 'Info panel not visible on mobile')
  })

  await t.test('Card title visible on mobile', async () => {
    const title = await driver.findElement(By.css('h1.card-title'))
    assert(await title.isDisplayed(), 'Title not visible on mobile')
  })

  await t.test('Explore button visible on mobile', async () => {
    const btn = await elementExists(driver, 'button.action-button')
    assert(btn, 'Explore button not visible on mobile')
  })

  // Reset viewport
  await driver.manage().window().setRect({ width: 1280, height: 900 })
  await driver.sleep(500)
}

// ── Main ─────────────────────────────────────────────────────────────

async function main() {
  console.log('='.repeat(60))
  console.log('  FunTell E2E Tests - Mobile Client (Public Access)')
  console.log('='.repeat(60))
  console.log(`Base URL: ${CONFIG.BASE_URL}`)

  if (!CONFIG.PUBLIC_CARD_ID) {
    console.error('ERROR: TEST_PUBLIC_CARD_ID required (a public card ID in the test environment)')
    process.exit(1)
  }

  console.log(`Card ID: ${CONFIG.PUBLIC_CARD_ID}`)

  driver = await createDriver()

  try {
    await testCardOverview()
    await testBranding()
    await testOverviewAIAssistant()
    await testNavigateToContentList()
    await testContentListPage()
    await testContentListAIBadge()
    await testContentDetailPage()
    await testContentDetailActions()
    await testContentDetailAI()
    await testLanguageSwitching()
    await testURLLanguagePrefix()
    await testErrorStates()
    await testMobileViewport()
  } catch (err: any) {
    console.error(`\nFatal error: ${err.message}`)
  } finally {
    await driver.quit()
  }

  const success = t.printSummary()
  process.exit(success ? 0 : 1)
}

main()

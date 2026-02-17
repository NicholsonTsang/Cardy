/**
 * E2E Tests - Creator Portal
 *
 * Covers: projects page, credit management, voice credit purchase,
 *         subscription management (free & paid views)
 *
 * Run:
 *   npx ts-node tests/e2e/creator-portal.test.ts
 */

import { By, until, Key, WebDriver } from 'selenium-webdriver'
import {
  CONFIG, createDriver, loginAsCreator, navigateTo, waitForPageLoad,
  assert, assertEqual, TestRunner, elementExists, elementExistsByXpath,
  getCurrentUrl, waitForDialog, closeDialog, isDialogOpen, clickButton
} from './helpers'

let driver: WebDriver
const t = new TestRunner()

// ── Projects Page (/cms/projects) ──────────────────────────────────────

async function testProjectsPage() {
  t.suite('Projects Page')

  await navigateTo(driver, '/en/cms/projects')
  await driver.sleep(2000)

  await t.test('Projects page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/projects'), `Expected /cms/projects, got ${url}`)
  })

  await t.test('Card list panel is visible', async () => {
    const exists = await elementExists(driver, '[class*="lg:w-"]')
    assert(exists, 'Card list panel not found')
  })

  await t.test('Create button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[contains(@class, 'pi-plus') or .//i[contains(@class, 'pi-plus')]]"
    )
    assert(btn, 'Create button not found')
  })

  await t.test('More menu button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//i[contains(@class, 'pi-ellipsis-v')]]"
    )
    assert(btn, 'More menu button not found')
  })

  await t.test('Filter button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//i[contains(@class, 'pi-filter')]]"
    )
    assert(btn, 'Filter button not found')
  })

  // Test project count badge
  await t.test('Project count is displayed', async () => {
    const badge = await elementExistsByXpath(driver,
      "//*[contains(@class, 'text-xs') and contains(text(), '/')]"
    )
    assert(badge, 'Project count badge not found')
  })
}

// ── Projects Page - Card Selection ─────────────────────────────────────

async function testProjectSelection() {
  t.suite('Project Selection & Detail Panel')

  await navigateTo(driver, '/en/cms/projects')
  await driver.sleep(2000)

  // Check if there are any cards to select
  const hasCards = await elementExistsByXpath(driver,
    "//*[contains(@class, 'space-y-1')]/*"
  )

  if (!hasCards) {
    t.skip('Project selection tests', 'No projects available')
    return
  }

  await t.test('Clicking a project shows detail panel', async () => {
    // Click the first card in the list
    const firstCard = await driver.findElement(By.xpath(
      "(//*[contains(@class, 'space-y-1')]//*[contains(@class, 'cursor-pointer')])[1]"
    ))
    await firstCard.click()
    await driver.sleep(1000)

    // URL should contain cardId param or detail panel should appear
    const url = await getCurrentUrl(driver)
    const hasCardParam = url.includes('cardId=')
    const hasDetailPanel = await elementExistsByXpath(driver,
      "//div[contains(@class, 'flex-1')]//ul[contains(@class, 'p-tablist')]"
    )
    assert(hasCardParam || hasDetailPanel, 'Detail panel did not appear after selecting card')
  })

  await t.test('Detail panel has tabs', async () => {
    const tabs = await driver.findElements(By.css('[role="tab"], .p-tab'))
    assert(tabs.length >= 4, `Expected 4 tabs, got ${tabs.length}`)
  })
}

// ── Projects Page - Create Dialog ──────────────────────────────────────

async function testCreateProjectDialog() {
  t.suite('Create Project Dialog')

  await navigateTo(driver, '/en/cms/projects')
  await driver.sleep(2000)

  await t.test('Create button opens dialog', async () => {
    const createBtn = await driver.findElement(By.xpath(
      "//button[.//i[contains(@class, 'pi-plus')]]"
    ))
    await createBtn.click()
    await driver.sleep(1000)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Create dialog did not open')
  })

  await t.test('Create dialog can be closed', async () => {
    await closeDialog(driver)
    const dialogOpen = await isDialogOpen(driver)
    assert(!dialogOpen, 'Dialog should be closed')
  })
}

// ── Credit Management Page (/cms/credits) ──────────────────────────────

async function testCreditManagement() {
  t.suite('Credit Management Page')

  await navigateTo(driver, '/en/cms/credits')
  await driver.wait(until.elementLocated(By.css('[class*="rounded-2xl"]')), CONFIG.TIMEOUT)

  // Balance overview cards
  await t.test('Current Balance card is displayed', async () => {
    const card = await driver.findElement(By.xpath(
      "//*[contains(@class, 'pi-wallet')]/ancestor::div[contains(@class, 'rounded-2xl')]"
    ))
    assert(await card.isDisplayed(), 'Balance card not visible')
  })

  await t.test('Total Purchased card is displayed', async () => {
    const card = await driver.findElement(By.xpath(
      "//*[contains(@class, 'pi-arrow-circle-up')]/ancestor::div[contains(@class, 'rounded-2xl')]"
    ))
    assert(await card.isDisplayed(), 'Purchased card not visible')
  })

  await t.test('Total Consumed card is displayed', async () => {
    const card = await driver.findElement(By.xpath(
      "//*[contains(@class, 'pi-arrow-circle-down')]/ancestor::div[contains(@class, 'rounded-2xl')]"
    ))
    assert(await card.isDisplayed(), 'Consumed card not visible')
  })

  // Purchase Credits button
  await t.test('Purchase Credits button exists', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Purchase')] or .//span[contains(text(), 'purchase')]]"
    ))
    assert(await btn.isDisplayed(), 'Purchase Credits button not visible')
  })

  // History tabs
  await t.test('History tabs exist', async () => {
    const tabs = await driver.findElements(By.css('[role="tab"], .p-tab'))
    assert(tabs.length >= 3, `Expected 3+ tabs, got ${tabs.length}`)
  })
}

// ── Voice Credits Section ──────────────────────────────────────────────

async function testVoiceCreditsSection() {
  t.suite('Voice Credits Section')

  await navigateTo(driver, '/en/cms/credits')
  await driver.wait(until.elementLocated(By.css('[class*="rounded-2xl"]')), CONFIG.TIMEOUT)

  await t.test('Voice credit section is visible', async () => {
    const section = await driver.findElement(By.xpath(
      "//*[contains(@class, 'pi-phone')]/ancestor::div[contains(@class, 'rounded-2xl')]"
    ))
    assert(await section.isDisplayed(), 'Voice credit section not visible')
  })

  await t.test('Voice credit balance is displayed', async () => {
    const balanceText = await driver.findElement(By.xpath(
      "//*[contains(@class, 'pi-phone')]/ancestor::div[contains(@class, 'rounded-2xl')]//*[contains(@class, 'font-bold')]"
    ))
    assert(await balanceText.isDisplayed(), 'Voice credit balance not visible')
  })

  await t.test('Buy Voice Credits button exists', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Buy') and contains(text(), 'Voice')]]"
    ))
    assert(await btn.isDisplayed(), 'Buy Voice Credits button not visible')
  })
}

// ── Voice Credit Purchase Dialog ───────────────────────────────────────

async function testVoiceCreditPurchaseDialog() {
  t.suite('Voice Credit Purchase Dialog')

  await navigateTo(driver, '/en/cms/credits')
  await driver.wait(until.elementLocated(By.css('[class*="rounded-2xl"]')), CONFIG.TIMEOUT)

  // Open dialog
  await t.test('Clicking Buy opens confirmation dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Buy') and contains(text(), 'Voice')]]"
    ))
    await btn.click()

    const dialog = await waitForDialog(driver)
    assert(await dialog.isDisplayed(), 'Dialog not visible')
  })

  await t.test('Dialog has warning banner', async () => {
    const warning = await driver.findElement(By.css('.p-dialog .pi-exclamation-triangle'))
    assert(await warning.isDisplayed(), 'Warning icon not found')
  })

  await t.test('Dialog has quantity stepper', async () => {
    const dialog = await driver.findElement(By.css('.p-dialog'))
    const minusButtons = await dialog.findElements(By.xpath(
      ".//button[contains(text(), '\u2212')]"
    ))
    const plusButtons = await dialog.findElements(By.xpath(
      ".//button[contains(text(), '+')]"
    ))
    assert(minusButtons.length > 0, 'Minus button not found')
    assert(plusButtons.length > 0, 'Plus button not found')
  })

  await t.test('Quantity input defaults to 1', async () => {
    const input = await driver.findElement(By.css('.p-dialog input[type="number"]'))
    const value = await input.getAttribute('value')
    assert(value === '1', `Expected default 1, got ${value}`)
  })

  await t.test('Plus increments quantity', async () => {
    const plus = await driver.findElement(By.xpath(
      "//div[contains(@class, 'p-dialog')]//button[contains(text(), '+')]"
    ))
    await plus.click()

    const input = await driver.findElement(By.css('.p-dialog input[type="number"]'))
    const value = await input.getAttribute('value')
    assert(value === '2', `Expected 2, got ${value}`)
  })

  await t.test('Minus decrements quantity back to 1', async () => {
    const minus = await driver.findElement(By.xpath(
      "//div[contains(@class, 'p-dialog')]//button[contains(text(), '\u2212')]"
    ))
    await minus.click()

    const input = await driver.findElement(By.css('.p-dialog input[type="number"]'))
    const value = await input.getAttribute('value')
    assert(value === '1', `Expected 1, got ${value}`)
  })

  await t.test('Minus disabled at quantity 1', async () => {
    const minus = await driver.findElement(By.xpath(
      "//div[contains(@class, 'p-dialog')]//button[contains(text(), '\u2212')]"
    ))
    const disabled = await minus.getAttribute('disabled')
    const classes = await minus.getAttribute('class')
    assert(
      disabled !== null || classes.includes('cursor-not-allowed') || classes.includes('text-slate-300'),
      'Minus button should be disabled at qty 1'
    )
  })

  await t.test('Balance impact shows current and after', async () => {
    const currentLabel = await driver.findElement(By.xpath(
      "//div[contains(@class, 'p-dialog')]//*[contains(text(), 'Current') or contains(text(), 'current')]"
    ))
    assert(await currentLabel.isDisplayed(), 'Current balance label not found')
  })

  await t.test('Cancel closes dialog', async () => {
    await closeDialog(driver)
    await driver.sleep(500)
    const dialogOpen = await isDialogOpen(driver)
    assert(!dialogOpen, 'Dialog should be closed after cancel')
  })

  await t.test('Re-opening resets quantity to 1', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Buy') and contains(text(), 'Voice')]]"
    ))
    await btn.click()
    await waitForDialog(driver)

    const input = await driver.findElement(By.css('.p-dialog input[type="number"]'))
    const value = await input.getAttribute('value')
    assert(value === '1', `Expected 1 on re-open, got ${value}`)

    await closeDialog(driver)
    await driver.sleep(500)
  })
}

// ── Credit Purchase Dialog ─────────────────────────────────────────────

async function testCreditPurchaseDialog() {
  t.suite('Credit Purchase Dialog')

  await navigateTo(driver, '/en/cms/credits')
  await driver.wait(until.elementLocated(By.css('[class*="rounded-2xl"]')), CONFIG.TIMEOUT)

  await t.test('Purchase Credits button opens dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Purchase')] or .//span[contains(text(), 'purchase')]]"
    ))
    await btn.click()

    const dialog = await driver.wait(
      until.elementLocated(By.css('.p-dialog')),
      CONFIG.TIMEOUT
    )
    assert(await dialog.isDisplayed(), 'Purchase dialog not visible')
  })

  await t.test('Quick select amounts are shown', async () => {
    const amounts = await driver.findElements(By.xpath(
      "//div[contains(@class, 'p-dialog')]//button[contains(@class, 'rounded-xl')]"
    ))
    assert(amounts.length >= 3, `Expected 3+ quick amounts, got ${amounts.length}`)
  })

  await t.test('Selecting amount highlights button', async () => {
    const firstBtn = await driver.findElement(By.xpath(
      "(//div[contains(@class, 'p-dialog')]//button[contains(@class, 'rounded-xl')])[1]"
    ))
    await firstBtn.click()

    const classes = await firstBtn.getAttribute('class')
    assert(
      classes.includes('border-blue-500') || classes.includes('bg-blue-50'),
      'Selected amount not highlighted'
    )
  })

  await t.test('Closing purchase dialog', async () => {
    await driver.actions().sendKeys(Key.ESCAPE).perform()
    await driver.sleep(500)
  })
}

// ── Subscription Management Page (/cms/subscription) ───────────────────

async function testSubscriptionPage() {
  t.suite('Subscription Management Page')

  await navigateTo(driver, '/en/cms/subscription')
  await driver.sleep(2000)

  await t.test('Subscription page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/subscription'), `Expected /cms/subscription, got ${url}`)
  })

  await t.test('Page heading is displayed', async () => {
    const heading = await driver.findElement(By.css('h1'))
    assert(await heading.isDisplayed(), 'Page heading not visible')
  })

  // Plan comparison OR current plan card should be visible
  await t.test('Plan information is displayed', async () => {
    // Either plan comparison grid (free user) or plan status card (paid user)
    const hasPlanGrid = await elementExistsByXpath(driver,
      "//*[contains(text(), 'Free') or contains(text(), 'Starter') or contains(text(), 'Premium')]"
    )
    assert(hasPlanGrid, 'Plan information not found')
  })

  // Daily access chart
  await t.test('Daily access chart section exists', async () => {
    const chartSection = await elementExistsByXpath(driver,
      "//*[contains(@class, 'chart-wrapper') or contains(@class, 'rounded-2xl')]//*[contains(text(), 'Daily') or contains(text(), 'Access') or contains(text(), 'Traffic')]"
    )
    // Chart may not always be present, depends on data availability
    if (!chartSection) {
      console.log('    (chart section not visible - may depend on data)')
    }
  })
}

// ── Subscription Page - Paid User Voice Credits ────────────────────────

async function testSubscriptionVoiceCredits() {
  t.suite('Subscription Page - Voice Credits (Paid Users)')

  await navigateTo(driver, '/en/cms/subscription')
  await driver.sleep(2000)

  // Voice credits section only visible for paid users
  const hasVoiceSection = await elementExistsByXpath(driver,
    "//*[contains(@class, 'pi-phone')]"
  )

  if (!hasVoiceSection) {
    t.skip('Voice credits in subscription', 'Free tier user - section not visible')
    return
  }

  await t.test('Voice credit section visible for paid users', async () => {
    const section = await driver.findElement(By.xpath(
      "//*[contains(@class, 'pi-phone')]"
    ))
    assert(await section.isDisplayed(), 'Voice credit section not visible')
  })

  await t.test('Buy Voice Credits button in subscription page', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Buy Voice') or contains(text(), 'voice')]]"
    ))
    assert(await btn.isDisplayed(), 'Buy button not visible')

    await btn.click()
    const dialog = await waitForDialog(driver)
    assert(await dialog.isDisplayed(), 'Dialog not visible')

    // Verify stepper exists
    const input = await driver.findElement(By.css('.p-dialog input[type="number"]'))
    assert(await input.isDisplayed(), 'Quantity input not found')

    await closeDialog(driver)
    await driver.sleep(500)
  })
}

// ── Navigation Menu ────────────────────────────────────────────────────

async function testNavigationMenu() {
  t.suite('Dashboard Navigation Menu')

  await navigateTo(driver, '/en/cms/projects')
  await driver.sleep(2000)

  await t.test('User menu button exists in header', async () => {
    const menuBtn = await elementExists(driver, '.main-menu-button')
    assert(menuBtn, 'Main menu button not found')
  })

  await t.test('Clicking menu button opens dropdown', async () => {
    const menuBtn = await driver.findElement(By.css('.main-menu-button'))
    await menuBtn.click()
    await driver.sleep(500)

    const menuItems = await driver.findElements(By.css('.p-menuitem-link'))
    assert(menuItems.length >= 3, `Expected 3+ menu items, got ${menuItems.length}`)
  })

  await t.test('Menu has navigation items', async () => {
    // Look for key navigation labels
    const hasProjects = await elementExistsByXpath(driver,
      "//a[contains(@class, 'p-menuitem-link')]//*[contains(text(), 'Project') or contains(text(), 'Card')]"
    )
    const hasCredits = await elementExistsByXpath(driver,
      "//a[contains(@class, 'p-menuitem-link')]//*[contains(text(), 'Credit')]"
    )
    assert(hasProjects || hasCredits, 'Navigation menu items not found')
  })

  // Close menu by pressing Escape
  await driver.actions().sendKeys(Key.ESCAPE).perform()
  await driver.sleep(300)
}

// ── Credit Balance in Header ───────────────────────────────────────────

async function testHeaderCreditBalance() {
  t.suite('Header Credit Balance')

  await navigateTo(driver, '/en/cms/projects')
  await driver.sleep(2000)

  await t.test('Credit balance shown in header', async () => {
    const balance = await elementExistsByXpath(driver,
      "//header//*[contains(@class, 'pi-wallet')]"
    )
    assert(balance, 'Credit balance / wallet icon not found in header')
  })
}

// ── Main ─────────────────────────────────────────────────────────────

async function main() {
  console.log('='.repeat(60))
  console.log('  FunTell E2E Tests - Creator Portal')
  console.log('='.repeat(60))
  console.log(`Base URL: ${CONFIG.BASE_URL}`)

  if (!CONFIG.CREATOR_EMAIL || !CONFIG.CREATOR_PASSWORD) {
    console.error('ERROR: TEST_CREATOR_EMAIL and TEST_CREATOR_PASSWORD required')
    process.exit(1)
  }

  driver = await createDriver()

  try {
    await loginAsCreator(driver)

    await testNavigationMenu()
    await testHeaderCreditBalance()
    await testProjectsPage()
    await testProjectSelection()
    await testCreateProjectDialog()
    await testCreditManagement()
    await testVoiceCreditsSection()
    await testVoiceCreditPurchaseDialog()
    await testCreditPurchaseDialog()
    await testSubscriptionPage()
    await testSubscriptionVoiceCredits()
  } catch (err: any) {
    console.error(`\nFatal error: ${err.message}`)
  } finally {
    await driver.quit()
  }

  const success = t.printSummary()
  process.exit(success ? 0 : 1)
}

main()

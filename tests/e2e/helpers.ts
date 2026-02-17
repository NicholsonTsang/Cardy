/**
 * Shared E2E Test Helpers
 *
 * Common setup, login, assertions, and utilities used across all test suites.
 */

import { Builder, By, Key, until, WebDriver, WebElement } from 'selenium-webdriver'
import chrome from 'selenium-webdriver/chrome'

// ── Configuration ────────────────────────────────────────────────────────

export const CONFIG = {
  BASE_URL: process.env.TEST_BASE_URL || 'http://localhost:5173',
  CREATOR_EMAIL: process.env.TEST_CREATOR_EMAIL || '',
  CREATOR_PASSWORD: process.env.TEST_CREATOR_PASSWORD || '',
  ADMIN_EMAIL: process.env.TEST_ADMIN_EMAIL || '',
  ADMIN_PASSWORD: process.env.TEST_ADMIN_PASSWORD || '',
  // A public card ID that exists in the test environment for mobile client tests
  PUBLIC_CARD_ID: process.env.TEST_PUBLIC_CARD_ID || '',
  TIMEOUT: 10_000,
  SHORT_WAIT: 500,
  HEADLESS: process.env.TEST_HEADLESS !== 'false', // default headless
}

// ── Driver Management ────────────────────────────────────────────────────

export async function createDriver(): Promise<WebDriver> {
  const options = new chrome.Options()
  if (CONFIG.HEADLESS) {
    options.addArguments('--headless=new')
  }
  options.addArguments(
    '--no-sandbox',
    '--disable-gpu',
    '--window-size=1280,900',
    '--disable-dev-shm-usage'
  )

  const driver = await new Builder()
    .forBrowser('chrome')
    .setChromeOptions(options)
    .build()

  await driver.manage().setTimeouts({ implicit: 3000 })
  return driver
}

// ── Authentication ───────────────────────────────────────────────────────

export async function loginAs(
  driver: WebDriver,
  email: string,
  password: string,
  expectedRedirect: string = '/cms'
) {
  if (!email || !password) {
    throw new Error(`Login credentials not provided (email: ${email ? 'set' : 'missing'})`)
  }

  await driver.get(`${CONFIG.BASE_URL}/en/login`)
  await driver.wait(until.elementLocated(By.css('input[type="email"]')), CONFIG.TIMEOUT)

  const emailInput = await driver.findElement(By.css('input[type="email"]'))
  await emailInput.clear()
  await emailInput.sendKeys(email)

  const passwordInput = await driver.findElement(By.css('input[type="password"]'))
  await passwordInput.clear()
  await passwordInput.sendKeys(password)

  const submitBtn = await driver.findElement(By.css('button[type="submit"]'))
  await submitBtn.click()

  await driver.wait(until.urlContains(expectedRedirect), CONFIG.TIMEOUT)
}

export async function loginAsCreator(driver: WebDriver) {
  await loginAs(driver, CONFIG.CREATOR_EMAIL, CONFIG.CREATOR_PASSWORD)
}

export async function loginAsAdmin(driver: WebDriver) {
  await loginAs(driver, CONFIG.ADMIN_EMAIL, CONFIG.ADMIN_PASSWORD)
}

export async function logout(driver: WebDriver) {
  // Navigate to a known dashboard page first
  await driver.get(`${CONFIG.BASE_URL}/en/cms/projects`)
  await driver.sleep(CONFIG.SHORT_WAIT)

  // Look for a logout / sign out button in the sidebar or menu
  try {
    const logoutBtn = await driver.findElement(By.xpath(
      "//button[contains(@class, 'pi-sign-out')] | //*[contains(@class, 'pi-sign-out')]/ancestor::button | //a[contains(@class, 'pi-sign-out')]"
    ))
    await logoutBtn.click()
    await driver.wait(until.urlContains('/login'), CONFIG.TIMEOUT)
  } catch {
    // Fallback: clear cookies to force logout
    await driver.manage().deleteAllCookies()
    await driver.get(`${CONFIG.BASE_URL}/en/login`)
  }
}

// ── Navigation ───────────────────────────────────────────────────────────

export async function navigateTo(driver: WebDriver, path: string) {
  await driver.get(`${CONFIG.BASE_URL}${path}`)
}

export async function waitForPageLoad(driver: WebDriver, selector: string = 'body') {
  await driver.wait(until.elementLocated(By.css(selector)), CONFIG.TIMEOUT)
}

// ── Dialog Helpers ───────────────────────────────────────────────────────

export async function waitForDialog(driver: WebDriver): Promise<WebElement> {
  return driver.wait(
    until.elementLocated(By.css('.p-dialog-mask .p-dialog')),
    CONFIG.TIMEOUT,
    'Dialog did not appear'
  )
}

export async function closeDialog(driver: WebDriver) {
  try {
    const cancelBtn = await driver.findElement(By.xpath(
      "//div[contains(@class, 'p-dialog')]//button[.//span[contains(text(), 'Cancel')] or contains(@class, 'p-dialog-header-close')]"
    ))
    await cancelBtn.click()
  } catch {
    await driver.actions().sendKeys(Key.ESCAPE).perform()
  }
  await driver.sleep(CONFIG.SHORT_WAIT)
}

export async function isDialogOpen(driver: WebDriver): Promise<boolean> {
  const masks = await driver.findElements(By.css('.p-dialog-mask'))
  return masks.length > 0
}

// ── Element Helpers ──────────────────────────────────────────────────────

export async function elementExists(driver: WebDriver, selector: string): Promise<boolean> {
  const elements = await driver.findElements(By.css(selector))
  return elements.length > 0
}

export async function elementExistsByXpath(driver: WebDriver, xpath: string): Promise<boolean> {
  const elements = await driver.findElements(By.xpath(xpath))
  return elements.length > 0
}

export async function getTextContent(driver: WebDriver, selector: string): Promise<string> {
  const el = await driver.wait(until.elementLocated(By.css(selector)), CONFIG.TIMEOUT)
  return el.getText()
}

export async function clickButton(driver: WebDriver, textOrXpath: string) {
  let btn: WebElement
  if (textOrXpath.startsWith('//')) {
    btn = await driver.findElement(By.xpath(textOrXpath))
  } else {
    btn = await driver.findElement(By.xpath(
      `//button[.//span[contains(text(), '${textOrXpath}')] or contains(text(), '${textOrXpath}')]`
    ))
  }
  await btn.click()
}

export async function getCurrentUrl(driver: WebDriver): Promise<string> {
  return driver.getCurrentUrl()
}

// ── Test Runner ──────────────────────────────────────────────────────────

export interface TestResult {
  suite: string
  name: string
  passed: boolean
  error?: string
  skipped?: boolean
}

export class TestRunner {
  results: TestResult[] = []
  currentSuite = ''

  suite(name: string) {
    this.currentSuite = name
    console.log(`\n── ${name} ──\n`)
  }

  async test(name: string, fn: () => Promise<void>) {
    try {
      await fn()
      this.results.push({ suite: this.currentSuite, name, passed: true })
      console.log(`  [PASS] ${name}`)
    } catch (err: any) {
      this.results.push({ suite: this.currentSuite, name, passed: false, error: err.message })
      console.log(`  [FAIL] ${name}`)
      console.log(`         ${err.message}`)
    }
  }

  skip(name: string, reason: string = '') {
    this.results.push({ suite: this.currentSuite, name, passed: true, skipped: true })
    console.log(`  [SKIP] ${name}${reason ? ` (${reason})` : ''}`)
  }

  printSummary() {
    const passed = this.results.filter(r => r.passed && !r.skipped).length
    const failed = this.results.filter(r => !r.passed).length
    const skipped = this.results.filter(r => r.skipped).length
    const total = this.results.length

    console.log('\n' + '='.repeat(60))
    console.log(`  RESULTS: ${passed} passed, ${failed} failed, ${skipped} skipped (${total} total)`)
    console.log('='.repeat(60))

    if (failed > 0) {
      console.log('\nFailed tests:')
      this.results.filter(r => !r.passed).forEach(r => {
        console.log(`  [FAIL] [${r.suite}] ${r.name}`)
        console.log(`         ${r.error}`)
      })
    }

    return failed === 0
  }
}

// ── Assertion ────────────────────────────────────────────────────────────

export function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(message)
}

export function assertEqual(actual: any, expected: any, label: string = '') {
  if (actual !== expected) {
    throw new Error(`${label ? label + ': ' : ''}Expected "${expected}", got "${actual}"`)
  }
}

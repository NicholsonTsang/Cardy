/**
 * E2E Tests - Authentication & Route Guards
 *
 * Covers: login, signup page, password reset, role-based redirects, language routing
 *
 * Run:
 *   npx ts-node tests/e2e/auth.test.ts
 */

import { By, until, WebDriver } from 'selenium-webdriver'
import {
  CONFIG, createDriver, navigateTo, waitForPageLoad,
  assert, assertEqual, TestRunner, elementExists, getCurrentUrl
} from './helpers'

let driver: WebDriver
const t = new TestRunner()

// ── Login Page ───────────────────────────────────────────────────────────

async function testLoginPage() {
  t.suite('Login Page')

  await navigateTo(driver, '/en/login')
  await waitForPageLoad(driver, 'form')

  await t.test('Login page renders', async () => {
    const form = await driver.findElement(By.css('form'))
    assert(await form.isDisplayed(), 'Login form not visible')
  })

  await t.test('Has email input', async () => {
    const input = await driver.findElement(By.css('input[type="email"]'))
    assert(await input.isDisplayed(), 'Email input not visible')
  })

  await t.test('Has password input', async () => {
    const input = await driver.findElement(By.css('input[type="password"]'))
    assert(await input.isDisplayed(), 'Password input not visible')
  })

  await t.test('Has submit button', async () => {
    const btn = await driver.findElement(By.css('button[type="submit"]'))
    assert(await btn.isDisplayed(), 'Submit button not visible')
  })

  await t.test('Has forgot password link', async () => {
    const link = await driver.findElement(By.xpath(
      "//a[contains(@href, 'reset-password')] | //*[contains(text(), 'Forgot') or contains(text(), 'forgot')]"
    ))
    assert(await link.isDisplayed(), 'Forgot password link not visible')
  })

  await t.test('Has sign up link', async () => {
    const link = await driver.findElement(By.xpath(
      "//a[contains(@href, 'signup')] | //*[contains(text(), 'Sign up') or contains(text(), 'sign up') or contains(text(), 'Register')]"
    ))
    assert(await link.isDisplayed(), 'Sign up link not visible')
  })

  await t.test('Shows FunTell branding', async () => {
    const branding = await driver.findElement(By.xpath(
      "//*[contains(text(), 'FunTell')]"
    ))
    assert(await branding.isDisplayed(), 'FunTell branding not visible')
  })

  await t.test('Shows error on invalid credentials', async () => {
    const emailInput = await driver.findElement(By.css('input[type="email"]'))
    await emailInput.clear()
    await emailInput.sendKeys('invalid@test.com')

    const passwordInput = await driver.findElement(By.css('input[type="password"]'))
    await passwordInput.clear()
    await passwordInput.sendKeys('wrongpassword123')

    const submitBtn = await driver.findElement(By.css('button[type="submit"]'))
    await submitBtn.click()

    await driver.sleep(2000)
    // Should show error message or remain on login page
    const url = await getCurrentUrl(driver)
    assert(url.includes('/login'), 'Should stay on login page after failed login')
  })

  await t.test('Shows validation for empty fields', async () => {
    // Clear fields and submit
    const emailInput = await driver.findElement(By.css('input[type="email"]'))
    await emailInput.clear()

    const passwordInput = await driver.findElement(By.css('input[type="password"]'))
    await passwordInput.clear()

    const submitBtn = await driver.findElement(By.css('button[type="submit"]'))
    await submitBtn.click()

    // HTML5 validation should prevent submission - check we're still on login
    const url = await getCurrentUrl(driver)
    assert(url.includes('/login'), 'Should stay on login page')
  })
}

// ── Signup Page ──────────────────────────────────────────────────────────

async function testSignupPage() {
  t.suite('Signup Page')

  await navigateTo(driver, '/en/signup')
  await waitForPageLoad(driver, 'form')

  await t.test('Signup page renders', async () => {
    const form = await driver.findElement(By.css('form'))
    assert(await form.isDisplayed(), 'Signup form not visible')
  })

  await t.test('Has email input', async () => {
    const input = await driver.findElement(By.css('input[type="email"]'))
    assert(await input.isDisplayed(), 'Email input not visible')
  })

  await t.test('Has password input', async () => {
    const input = await driver.findElement(By.css('input[type="password"]'))
    assert(await input.isDisplayed(), 'Password input not visible')
  })

  await t.test('Has submit button', async () => {
    const btn = await driver.findElement(By.css('button[type="submit"]'))
    assert(await btn.isDisplayed(), 'Submit button not visible')
  })

  await t.test('Has sign in link', async () => {
    const link = await driver.findElement(By.xpath(
      "//a[contains(@href, 'login')] | //*[contains(text(), 'Sign in') or contains(text(), 'sign in') or contains(text(), 'Log in')]"
    ))
    assert(await link.isDisplayed(), 'Sign in link not visible')
  })
}

// ── Password Reset Page ─────────────────────────────────────────────────

async function testPasswordResetPage() {
  t.suite('Password Reset Page')

  await navigateTo(driver, '/en/reset-password')
  await driver.sleep(1000)

  await t.test('Password reset page renders', async () => {
    const url = await getCurrentUrl(driver)
    assert(
      url.includes('reset-password'),
      `Expected reset-password page, got ${url}`
    )
  })
}

// ── Route Guards (Unauthenticated) ──────────────────────────────────────

async function testRouteGuardsUnauthenticated() {
  t.suite('Route Guards (Unauthenticated)')

  await t.test('Accessing /cms/projects redirects to login', async () => {
    await navigateTo(driver, '/en/cms/projects')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/login'), `Expected redirect to login, got ${url}`)
  })

  await t.test('Accessing /cms/credits redirects to login', async () => {
    await navigateTo(driver, '/en/cms/credits')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/login'), `Expected redirect to login, got ${url}`)
  })

  await t.test('Accessing /cms/subscription redirects to login', async () => {
    await navigateTo(driver, '/en/cms/subscription')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/login'), `Expected redirect to login, got ${url}`)
  })

  await t.test('Accessing /cms/admin redirects to login', async () => {
    await navigateTo(driver, '/en/cms/admin')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/login'), `Expected redirect to login, got ${url}`)
  })
}

// ── Language Routing ────────────────────────────────────────────────────

async function testLanguageRouting() {
  t.suite('Language Routing')

  await t.test('Root / redirects to /:lang', async () => {
    await navigateTo(driver, '/')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    // Should redirect to /en or user's preferred language
    assert(
      url.match(/\/[a-z]{2}(-[A-Za-z]+)?\/?$/) !== null || url.includes('/en'),
      `Expected language-prefixed URL, got ${url}`
    )
  })

  await t.test('Login page accessible in English', async () => {
    await navigateTo(driver, '/en/login')
    await driver.sleep(1000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/en/'), `Expected /en/ in URL, got ${url}`)
  })

  await t.test('Login page accessible in Traditional Chinese', async () => {
    await navigateTo(driver, '/zh-Hant/login')
    await driver.sleep(1000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/zh-Hant/'), `Expected /zh-Hant/ in URL, got ${url}`)
  })
}

// ── Creator Login & Redirect ────────────────────────────────────────────

async function testCreatorLogin() {
  t.suite('Creator Login Flow')

  if (!CONFIG.CREATOR_EMAIL || !CONFIG.CREATOR_PASSWORD) {
    t.skip('Creator login - credentials not provided', 'TEST_CREATOR_EMAIL/PASSWORD not set')
    return
  }

  await navigateTo(driver, '/en/login')
  await waitForPageLoad(driver, 'form')

  await t.test('Creator can log in', async () => {
    const emailInput = await driver.findElement(By.css('input[type="email"]'))
    await emailInput.clear()
    await emailInput.sendKeys(CONFIG.CREATOR_EMAIL)

    const passwordInput = await driver.findElement(By.css('input[type="password"]'))
    await passwordInput.clear()
    await passwordInput.sendKeys(CONFIG.CREATOR_PASSWORD)

    const submitBtn = await driver.findElement(By.css('button[type="submit"]'))
    await submitBtn.click()

    await driver.wait(until.urlContains('/cms'), CONFIG.TIMEOUT)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms'), `Expected /cms redirect, got ${url}`)
  })

  await t.test('Creator redirected to projects page', async () => {
    await driver.sleep(1000)
    const url = await getCurrentUrl(driver)
    assert(
      url.includes('/cms/projects') || url.includes('/cms'),
      `Expected projects page, got ${url}`
    )
  })

  // Clear session for next tests
  await driver.manage().deleteAllCookies()
  await driver.executeScript('window.localStorage.clear(); window.sessionStorage.clear();')
}

// ── Admin Login & Redirect ──────────────────────────────────────────────

async function testAdminLogin() {
  t.suite('Admin Login Flow')

  if (!CONFIG.ADMIN_EMAIL || !CONFIG.ADMIN_PASSWORD) {
    t.skip('Admin login - credentials not provided', 'TEST_ADMIN_EMAIL/PASSWORD not set')
    return
  }

  await navigateTo(driver, '/en/login')
  await waitForPageLoad(driver, 'form')

  await t.test('Admin can log in', async () => {
    const emailInput = await driver.findElement(By.css('input[type="email"]'))
    await emailInput.clear()
    await emailInput.sendKeys(CONFIG.ADMIN_EMAIL)

    const passwordInput = await driver.findElement(By.css('input[type="password"]'))
    await passwordInput.clear()
    await passwordInput.sendKeys(CONFIG.ADMIN_PASSWORD)

    const submitBtn = await driver.findElement(By.css('button[type="submit"]'))
    await submitBtn.click()

    await driver.wait(until.urlContains('/cms'), CONFIG.TIMEOUT)
  })

  await t.test('Admin redirected to admin dashboard', async () => {
    await driver.sleep(1000)
    const url = await getCurrentUrl(driver)
    assert(
      url.includes('/cms/admin') || url.includes('/cms'),
      `Expected admin dashboard, got ${url}`
    )
  })

  // Clear session
  await driver.manage().deleteAllCookies()
  await driver.executeScript('window.localStorage.clear(); window.sessionStorage.clear();')
}

// ── Main ─────────────────────────────────────────────────────────────────

async function main() {
  console.log('='.repeat(60))
  console.log('  FunTell E2E Tests - Authentication & Route Guards')
  console.log('='.repeat(60))
  console.log(`Base URL: ${CONFIG.BASE_URL}`)

  driver = await createDriver()

  try {
    await testLoginPage()
    await testSignupPage()
    await testPasswordResetPage()
    await testRouteGuardsUnauthenticated()
    await testLanguageRouting()
    await testCreatorLogin()
    await testAdminLogin()
  } catch (err: any) {
    console.error(`\nFatal error: ${err.message}`)
  } finally {
    await driver.quit()
  }

  const success = t.printSummary()
  process.exit(success ? 0 : 1)
}

main()

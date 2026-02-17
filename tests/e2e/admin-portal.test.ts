/**
 * E2E Tests - Admin Portal
 *
 * Covers: admin dashboard, user management, admin credit management,
 *         history logs, user projects viewer, template management
 *
 * Run:
 *   npx ts-node tests/e2e/admin-portal.test.ts
 */

import { By, until, Key, WebDriver } from 'selenium-webdriver'
import {
  CONFIG, createDriver, loginAsAdmin, navigateTo, waitForPageLoad,
  assert, assertEqual, TestRunner, elementExists, elementExistsByXpath,
  getCurrentUrl, waitForDialog, closeDialog, isDialogOpen
} from './helpers'

let driver: WebDriver
const t = new TestRunner()

// ── Admin Dashboard ────────────────────────────────────────────────────

async function testAdminDashboard() {
  t.suite('Admin Dashboard')

  await navigateTo(driver, '/en/cms/admin')
  await driver.sleep(2000)

  await t.test('Admin dashboard loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin'), `Expected /cms/admin, got ${url}`)
  })

  await t.test('Refresh Data button exists', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Refresh')] or .//i[contains(@class, 'pi-refresh')]]"
    ))
    assert(await btn.isDisplayed(), 'Refresh button not visible')
  })

  // User stats section
  await t.test('Total Users metric is displayed', async () => {
    const metric = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-users')]"
    )
    assert(metric, 'Total Users metric not found')
  })

  await t.test('Premium Users metric is displayed', async () => {
    const metric = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-star')]"
    )
    assert(metric, 'Premium Users metric not found')
  })

  // Revenue section
  await t.test('Revenue metrics are displayed', async () => {
    const revenue = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-dollar') or contains(@class, 'pi-wallet')]"
    )
    assert(revenue, 'Revenue metrics not found')
  })

  // Card growth section
  await t.test('Card growth metrics are displayed', async () => {
    const cards = await elementExistsByXpath(driver,
      "//*[contains(text(), 'Cards') or contains(text(), 'cards')]"
    )
    assert(cards, 'Card growth metrics not found')
  })

  // Digital access section
  await t.test('Digital access analytics are displayed', async () => {
    const scans = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-qrcode') or contains(text(), 'Digital') or contains(text(), 'Scan')]"
    )
    assert(scans, 'Digital access analytics not found')
  })

  // Quick actions
  await t.test('View History Logs link exists', async () => {
    const link = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-history')]"
    )
    assert(link, 'History Logs link not found')
  })
}

// ── User Management ────────────────────────────────────────────────────

async function testUserManagement() {
  t.suite('User Management')

  await navigateTo(driver, '/en/cms/admin/users')
  await driver.sleep(2000)

  await t.test('User management page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/users'), `Expected /cms/admin/users, got ${url}`)
  })

  // Stats cards
  await t.test('User stats cards are displayed', async () => {
    const statsCards = await driver.findElements(By.xpath(
      "//*[contains(@class, 'pi-users') or contains(@class, 'pi-id-card') or contains(@class, 'pi-shield') or contains(@class, 'pi-star-fill')]"
    ))
    assert(statsCards.length >= 3, `Expected 3+ stat icons, got ${statsCards.length}`)
  })

  // Search
  await t.test('Email search input exists', async () => {
    const search = await driver.findElement(By.css('input[type="text"]'))
    assert(await search.isDisplayed(), 'Search input not visible')
  })

  // DataTable
  await t.test('Users table is displayed', async () => {
    const table = await driver.findElement(By.css('.p-datatable'))
    assert(await table.isDisplayed(), 'Users table not visible')
  })

  await t.test('Table has user rows', async () => {
    const rows = await driver.findElements(By.css('.p-datatable tbody tr'))
    assert(rows.length > 0, 'No user rows found')
  })

  // Paginator
  await t.test('Paginator exists', async () => {
    const paginator = await elementExists(driver, '.p-paginator')
    assert(paginator, 'Paginator not found')
  })
}

// ── User Management - Filters ──────────────────────────────────────────

async function testUserManagementFilters() {
  t.suite('User Management - Filters')

  await navigateTo(driver, '/en/cms/admin/users')
  await driver.sleep(2000)

  await t.test('Role filter dropdown exists', async () => {
    const dropdowns = await driver.findElements(By.css('.p-select, .p-dropdown'))
    assert(dropdowns.length >= 1, 'Role filter dropdown not found')
  })

  await t.test('Tier filter dropdown exists', async () => {
    const dropdowns = await driver.findElements(By.css('.p-select, .p-dropdown'))
    assert(dropdowns.length >= 2, 'Tier filter dropdown not found')
  })

  await t.test('Search filters the table', async () => {
    const search = await driver.findElement(By.css('input[type="text"]'))
    await search.clear()
    await search.sendKeys('test@')
    await driver.sleep(1000) // debounce

    // Table should still be present (may show filtered results or empty state)
    const tableExists = await elementExists(driver, '.p-datatable')
    assert(tableExists, 'Table should remain visible after filtering')

    // Clear search
    await search.clear()
    await driver.sleep(1000)
  })

  await t.test('Export CSV button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//span[contains(text(), 'Export')] or .//i[contains(@class, 'pi-download')]]"
    )
    assert(btn, 'Export CSV button not found')
  })
}

// ── User Management - Role Dialog ──────────────────────────────────────

async function testRoleManagementDialog() {
  t.suite('User Management - Role Dialog')

  await navigateTo(driver, '/en/cms/admin/users')
  await driver.sleep(2000)

  await t.test('Manage Role button exists in table', async () => {
    const cogBtn = await driver.findElement(By.xpath(
      "//button[.//i[contains(@class, 'pi-cog')]]"
    ))
    assert(await cogBtn.isDisplayed(), 'Manage Role button not found')
  })

  await t.test('Clicking Manage Role opens dialog', async () => {
    const cogBtn = await driver.findElement(By.xpath(
      "(//button[.//i[contains(@class, 'pi-cog')]])[1]"
    ))
    await cogBtn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Role management dialog did not open')
  })

  await t.test('Role dialog has role selector', async () => {
    const roleSelect = await driver.findElement(By.css('.p-dialog .p-select, .p-dialog .p-dropdown'))
    assert(await roleSelect.isDisplayed(), 'Role selector not found')
  })

  await t.test('Role dialog has reason textarea', async () => {
    const textarea = await driver.findElement(By.css('.p-dialog textarea'))
    assert(await textarea.isDisplayed(), 'Reason textarea not found')
  })

  await t.test('Closing role dialog', async () => {
    await closeDialog(driver)
    await driver.sleep(500)
    const dialogOpen = await isDialogOpen(driver)
    assert(!dialogOpen, 'Dialog should be closed')
  })
}

// ── User Management - Subscription Dialog ──────────────────────────────

async function testSubscriptionManagementDialog() {
  t.suite('User Management - Subscription Dialog')

  await navigateTo(driver, '/en/cms/admin/users')
  await driver.sleep(2000)

  await t.test('Manage Subscription button exists', async () => {
    const starBtn = await driver.findElement(By.xpath(
      "//button[.//i[contains(@class, 'pi-star')]]"
    ))
    assert(await starBtn.isDisplayed(), 'Manage Subscription button not found')
  })

  await t.test('Clicking Manage Subscription opens dialog', async () => {
    const starBtn = await driver.findElement(By.xpath(
      "(//button[.//i[contains(@class, 'pi-star')]])[1]"
    ))
    await starBtn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Subscription dialog did not open')
  })

  await t.test('Subscription dialog has tier selection cards', async () => {
    const dialog = await driver.findElement(By.css('.p-dialog'))
    const tierOptions = await dialog.findElements(By.xpath(
      ".//*[contains(text(), 'Free') or contains(text(), 'Starter') or contains(text(), 'Premium')]"
    ))
    assert(tierOptions.length >= 3, `Expected 3 tier options, got ${tierOptions.length}`)
  })

  await t.test('Subscription dialog has reason textarea', async () => {
    const textarea = await driver.findElement(By.css('.p-dialog textarea'))
    assert(await textarea.isDisplayed(), 'Reason textarea not found')
  })

  await t.test('Closing subscription dialog', async () => {
    await closeDialog(driver)
    await driver.sleep(500)
  })
}

// ── Admin Credit Management ────────────────────────────────────────────

async function testAdminCreditManagement() {
  t.suite('Admin Credit Management')

  await navigateTo(driver, '/en/cms/admin/credits')
  await driver.sleep(2000)

  await t.test('Credit management page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/credits'), `Expected /cms/admin/credits, got ${url}`)
  })

  // System stats cards
  await t.test('System stats cards are displayed', async () => {
    const cards = await driver.findElements(By.xpath(
      "//*[contains(@class, 'pi-bolt') or contains(@class, 'pi-dollar') or contains(@class, 'pi-shopping-cart') or contains(@class, 'pi-chart-line')]"
    ))
    assert(cards.length >= 3, `Expected 3+ stat cards, got ${cards.length}`)
  })

  // DataTable
  await t.test('User credits table is displayed', async () => {
    const table = await elementExists(driver, '.p-datatable')
    assert(table, 'User credits table not found')
  })

  // Email search
  await t.test('Email search filter exists', async () => {
    const search = await driver.findElement(By.css('input[type="text"]'))
    assert(await search.isDisplayed(), 'Email search not found')
  })

  // Action buttons in table rows
  await t.test('Table has action buttons per row', async () => {
    const actionBtns = await driver.findElements(By.xpath(
      "//button[.//i[contains(@class, 'pi-shopping-cart') or contains(@class, 'pi-chart-line') or contains(@class, 'pi-list') or contains(@class, 'pi-pencil')]]"
    ))
    assert(actionBtns.length >= 1, 'No action buttons found in table')
  })
}

// ── Admin Credit Management - Dialogs ──────────────────────────────────

async function testAdminCreditDialogs() {
  t.suite('Admin Credit Management - Dialogs')

  await navigateTo(driver, '/en/cms/admin/credits')
  await driver.sleep(2000)

  // Purchases dialog
  await t.test('View Purchases button opens dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "(//button[.//i[contains(@class, 'pi-shopping-cart')]])[1]"
    ))
    await btn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Purchases dialog did not open')

    await closeDialog(driver)
    await driver.sleep(500)
  })

  // Consumptions dialog
  await t.test('View Consumptions button opens dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "(//button[.//i[contains(@class, 'pi-chart-line')]])[1]"
    ))
    await btn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Consumptions dialog did not open')

    await closeDialog(driver)
    await driver.sleep(500)
  })

  // Transactions dialog
  await t.test('View Transactions button opens dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "(//button[.//i[contains(@class, 'pi-list')]])[1]"
    ))
    await btn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Transactions dialog did not open')

    await closeDialog(driver)
    await driver.sleep(500)
  })

  // Adjust Credits dialog
  await t.test('Adjust Balance button opens dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "(//button[.//i[contains(@class, 'pi-pencil')]])[1]"
    ))
    await btn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Adjust dialog did not open')
  })

  await t.test('Adjust dialog has amount input', async () => {
    const input = await elementExists(driver, '.p-dialog .p-inputnumber, .p-dialog input[type="text"]')
    assert(input, 'Amount input not found in adjust dialog')
  })

  await t.test('Adjust dialog has reason textarea', async () => {
    const textarea = await driver.findElement(By.css('.p-dialog textarea'))
    assert(await textarea.isDisplayed(), 'Reason textarea not found')
  })

  await t.test('Closing adjust dialog', async () => {
    await closeDialog(driver)
    await driver.sleep(500)
  })
}

// ── History Logs ───────────────────────────────────────────────────────

async function testHistoryLogs() {
  t.suite('History Logs')

  await navigateTo(driver, '/en/cms/admin/history')
  await driver.sleep(2000)

  await t.test('History logs page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/history'), `Expected /cms/admin/history, got ${url}`)
  })

  await t.test('Refresh button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//i[contains(@class, 'pi-refresh')]]"
    )
    assert(btn, 'Refresh button not found')
  })

  await t.test('Export CSV button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//i[contains(@class, 'pi-file-export') or contains(@class, 'pi-download')]]"
    )
    assert(btn, 'Export CSV button not found')
  })

  // Filters
  await t.test('Search input exists', async () => {
    const search = await elementExists(driver, 'input[type="text"]')
    assert(search, 'Search input not found')
  })

  await t.test('Type filter dropdown exists', async () => {
    const dropdown = await elementExists(driver, '.p-select, .p-dropdown')
    assert(dropdown, 'Type filter dropdown not found')
  })

  await t.test('Date range filters exist', async () => {
    const calendars = await driver.findElements(By.css('.p-datepicker-input, .p-calendar input'))
    assert(calendars.length >= 2, `Expected 2 date inputs, got ${calendars.length}`)
  })

  // Activity list or paginator
  await t.test('Activity list or empty state is shown', async () => {
    const hasActivities = await elementExistsByXpath(driver,
      "//*[contains(@class, 'divide-y')]"
    )
    const hasEmpty = await elementExistsByXpath(driver,
      "//*[contains(text(), 'No activities') or contains(text(), 'no activities')]"
    )
    assert(hasActivities || hasEmpty, 'Neither activity list nor empty state found')
  })

  await t.test('Paginator exists', async () => {
    const paginator = await elementExists(driver, '.p-paginator')
    assert(paginator, 'Paginator not found')
  })
}

// ── User Projects Viewer ───────────────────────────────────────────────

async function testUserProjectsViewer() {
  t.suite('User Projects Viewer')

  await navigateTo(driver, '/en/cms/admin/user-projects')
  await driver.sleep(2000)

  await t.test('User projects page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(
      url.includes('/cms/admin/user-projects') || url.includes('/cms/admin/user-cards'),
      `Expected user projects page, got ${url}`
    )
  })

  await t.test('Email search input exists', async () => {
    const search = await driver.findElement(By.css('input[type="text"]'))
    assert(await search.isDisplayed(), 'Email search input not found')
  })

  await t.test('Search button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//i[contains(@class, 'pi-search')] or .//span[contains(text(), 'Search')]]"
    )
    assert(btn, 'Search button not found')
  })

  await t.test('Empty state shown before search', async () => {
    const emptyState = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-search')]"
    )
    assert(emptyState, 'Empty state not shown')
  })

  // Test search with admin's email (should find themselves)
  if (CONFIG.ADMIN_EMAIL) {
    await t.test('Searching for a user shows their info', async () => {
      const search = await driver.findElement(By.css('input[type="text"]'))
      await search.clear()
      await search.sendKeys(CONFIG.ADMIN_EMAIL)

      const searchBtn = await driver.findElement(By.xpath(
        "//button[.//i[contains(@class, 'pi-search')] or .//span[contains(text(), 'Search')]]"
      ))
      await searchBtn.click()
      await driver.sleep(2000)

      // Should show user info banner or error
      const hasUserInfo = await elementExistsByXpath(driver,
        "//*[contains(@class, 'pi-user')]"
      )
      const hasError = await elementExistsByXpath(driver,
        "//*[contains(@class, 'bg-red-50')]"
      )
      assert(hasUserInfo || hasError, 'Neither user info nor error shown after search')
    })
  }
}

// ── Template Management ────────────────────────────────────────────────

async function testTemplateManagement() {
  t.suite('Template Management')

  await navigateTo(driver, '/en/cms/admin/templates')
  await driver.sleep(2000)

  await t.test('Template management page loads', async () => {
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/templates'), `Expected /cms/admin/templates, got ${url}`)
  })

  await t.test('Create Template button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//span[contains(text(), 'Create')] or .//i[contains(@class, 'pi-plus')]]"
    )
    assert(btn, 'Create Template button not found')
  })

  await t.test('Import button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//span[contains(text(), 'Import')] or .//i[contains(@class, 'pi-upload')]]"
    )
    assert(btn, 'Import button not found')
  })

  await t.test('Refresh button exists', async () => {
    const btn = await elementExistsByXpath(driver,
      "//button[.//i[contains(@class, 'pi-refresh')]]"
    )
    assert(btn, 'Refresh button not found')
  })

  // Search and filters
  await t.test('Search filter exists', async () => {
    const search = await elementExists(driver, 'input[type="text"]')
    assert(search, 'Search filter not found')
  })

  await t.test('Venue type filter exists', async () => {
    const dropdowns = await driver.findElements(By.css('.p-select, .p-dropdown'))
    assert(dropdowns.length >= 1, 'Venue type filter not found')
  })

  // Template table or empty state
  await t.test('Templates table or empty state is shown', async () => {
    const hasTable = await elementExists(driver, '.p-datatable')
    const hasEmpty = await elementExistsByXpath(driver,
      "//*[contains(@class, 'pi-folder-open')]"
    )
    assert(hasTable || hasEmpty, 'Neither table nor empty state found')
  })
}

// ── Template Management - Create Dialog ────────────────────────────────

async function testTemplateCreateDialog() {
  t.suite('Template Management - Create Dialog')

  await navigateTo(driver, '/en/cms/admin/templates')
  await driver.sleep(2000)

  await t.test('Create Template opens dialog', async () => {
    const btn = await driver.findElement(By.xpath(
      "//button[.//span[contains(text(), 'Create')] or .//i[contains(@class, 'pi-plus')]]"
    ))
    await btn.click()
    await driver.sleep(500)

    const dialogOpen = await isDialogOpen(driver)
    assert(dialogOpen, 'Create dialog did not open')
  })

  await t.test('Dialog has card selector', async () => {
    const select = await elementExists(driver, '.p-dialog .p-select, .p-dialog .p-dropdown')
    assert(select, 'Card selector not found')
  })

  await t.test('Dialog has slug input', async () => {
    const input = await elementExists(driver, '.p-dialog input[type="text"], .p-dialog .p-inputtext')
    assert(input, 'Slug input not found')
  })

  await t.test('Closing create dialog', async () => {
    await closeDialog(driver)
    await driver.sleep(500)
  })
}

// ── Admin Route Guards ─────────────────────────────────────────────────

async function testAdminRouteAccess() {
  t.suite('Admin Route Access')

  await t.test('Admin can access /cms/admin', async () => {
    await navigateTo(driver, '/en/cms/admin')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin'), `Admin should access admin dashboard, got ${url}`)
  })

  await t.test('Admin can access /cms/admin/users', async () => {
    await navigateTo(driver, '/en/cms/admin/users')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/users'), `Admin should access user management, got ${url}`)
  })

  await t.test('Admin can access /cms/admin/credits', async () => {
    await navigateTo(driver, '/en/cms/admin/credits')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/credits'), `Admin should access credit management, got ${url}`)
  })

  await t.test('Admin can access /cms/admin/history', async () => {
    await navigateTo(driver, '/en/cms/admin/history')
    await driver.sleep(2000)
    const url = await getCurrentUrl(driver)
    assert(url.includes('/cms/admin/history'), `Admin should access history logs, got ${url}`)
  })
}

// ── Main ─────────────────────────────────────────────────────────────

async function main() {
  console.log('='.repeat(60))
  console.log('  FunTell E2E Tests - Admin Portal')
  console.log('='.repeat(60))
  console.log(`Base URL: ${CONFIG.BASE_URL}`)

  if (!CONFIG.ADMIN_EMAIL || !CONFIG.ADMIN_PASSWORD) {
    console.error('ERROR: TEST_ADMIN_EMAIL and TEST_ADMIN_PASSWORD required')
    process.exit(1)
  }

  driver = await createDriver()

  try {
    await loginAsAdmin(driver)

    await testAdminRouteAccess()
    await testAdminDashboard()
    await testUserManagement()
    await testUserManagementFilters()
    await testRoleManagementDialog()
    await testSubscriptionManagementDialog()
    await testAdminCreditManagement()
    await testAdminCreditDialogs()
    await testHistoryLogs()
    await testUserProjectsViewer()
    await testTemplateManagement()
    await testTemplateCreateDialog()
  } catch (err: any) {
    console.error(`\nFatal error: ${err.message}`)
  } finally {
    await driver.quit()
  }

  const success = t.printSummary()
  process.exit(success ? 0 : 1)
}

main()

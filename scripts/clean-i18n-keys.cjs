#!/usr/bin/env node
/**
 * Script to remove physical card, batch management, print request related
 * translation keys from i18n locale files.
 *
 * Usage: node scripts/clean-i18n-keys.js
 */

const fs = require('fs');
const path = require('path');

const LOCALE_DIR = path.join(__dirname, '..', 'src', 'i18n', 'locales');

const localeFiles = [
  'en.json', 'zh-Hant.json', 'zh-Hans.json', 'ko.json',
  'ja.json', 'es.json', 'fr.json', 'ru.json', 'ar.json', 'th.json'
];

// Keys to keep even if they match patterns
const KEEP_KEYS = new Set([
  'subscription_overage_batch',
  'digital_access',       // keep digital access keys
  'billing_digital',
]);

// Specific top-level sections to remove entirely
const REMOVE_SECTIONS = new Set([
  'batches',  // entire "batches" section
  'batch',    // entire "batch" section
  'print',    // entire "print" section
]);

// Individual keys to remove at various nesting levels
// These are checked by key name matching patterns
function shouldRemoveKey(key, parentKeys) {
  const fullPath = [...parentKeys, key].join('.');

  // Always keep these specific keys
  if (key === 'subscription_overage_batch') return false;
  if (key === 'digital_access' && !parentKeys.includes('mode_toggle')) return false;
  if (key === 'digital') return false; // Keep "digital" label

  // Remove entire top-level sections
  if (parentKeys.length === 0 && REMOVE_SECTIONS.has(key)) return true;

  // Remove keys containing "physical" (physical_card, physical_cards, physicalCards, etc.)
  if (/physical/i.test(key)) return true;

  // Remove keys containing "batch" (but not subscription_overage_batch)
  if (/batch/i.test(key) && key !== 'subscription_overage_batch') return true;

  // Remove keys containing "print_request" or "print_request_*"
  if (/print_request/i.test(key)) return true;

  // Remove "print_requests" key
  if (key === 'print_requests') return true;

  // Remove "print_completed", "print_submitted", "print_processing", "print_shipping" keys
  if (/^print_(completed|submitted|processing|shipping|status)$/.test(key)) return true;

  // Remove specific keys in checkout section that relate to batches
  if (parentKeys.includes('checkout')) {
    if (/batch/i.test(key)) return true;
  }

  // Remove dead "Card Issuance Trends" admin dashboard keys
  if (key === 'card_issuance_trends') return true;
  if (key === 'daily_issued_cards') return true;
  if (key === 'weekly_issued_cards') return true;
  if (key === 'monthly_issued_cards') return true;

  return false;
}

function cleanObject(obj, parentKeys = []) {
  if (typeof obj !== 'object' || obj === null || Array.isArray(obj)) {
    return obj;
  }

  const cleaned = {};

  for (const [key, value] of Object.entries(obj)) {
    if (shouldRemoveKey(key, parentKeys)) {
      console.log(`  Removing: ${[...parentKeys, key].join('.')}`);
      continue;
    }

    if (typeof value === 'object' && !Array.isArray(value) && value !== null) {
      const cleanedChild = cleanObject(value, [...parentKeys, key]);
      // Only include if the cleaned child still has keys
      if (Object.keys(cleanedChild).length > 0) {
        cleaned[key] = cleanedChild;
      } else {
        console.log(`  Removing empty section: ${[...parentKeys, key].join('.')}`);
      }
    } else {
      cleaned[key] = value;
    }
  }

  return cleaned;
}

// Also handle specific keys that need removal based on context
function additionalCleanup(obj) {
  // Remove from common section
  if (obj.common) {
    delete obj.common.batch_prefix;
    if (obj.common.batch_prefix === undefined) {
      console.log('  Removing: common.batch_prefix');
    }
  }

  // Remove from header section
  if (obj.header) {
    if (obj.header.batch_management) {
      delete obj.header.batch_management;
      console.log('  Removing: header.batch_management');
    }
    if (obj.header.issue_free_batch) {
      delete obj.header.issue_free_batch;
      console.log('  Removing: header.issue_free_batch');
    }
  }

  // Clean admin section specific keys
  if (obj.admin) {
    const adminKeysToRemove = [
      'print_requests', 'physical_card_management', 'physical_card_management_desc',
      'physical_card_management_notice', 'batch_management_desc', 'physical_cards_only',
      'batch_management_physical_only_desc', 'no_physical_cards_available',
      'choose_which_card_physical_only', 'user_has_no_physical_cards',
      'total_batches', 'pending_print_requests', 'issue_free_batch',
      'print_status', 'view_all_batches', 'issue_free_batch_desc',
      'about_free_batch_issuance', 'about_free_batch_text',
      'batch_configuration', 'fill_details_to_issue', 'batch_quantity',
      'enter_batch_quantity', 'batch_name', 'batch_name_auto_generated',
      'batch_issued_successfully', 'failed_to_issue_batch',
      'print_request_management', 'print_request_management_desc',
      'print_request_details', 'no_requests_found', 'no_requests_match_filters',
      'no_batches_match_filters', 'search_by_user_card_batch',
      'issue_free_batch_button', 'recent_free_batch_issuances',
      'latest_batches_issued', 'issuing_batch', 'batch_information',
      'batch_number', 'print_completed', 'failed_to_load_requests',
      'select_card_to_issue', 'choose_which_card',
      // Dead "Card Issuance Trends" section (data no longer returned by stored procedure)
      'card_issuance_trends', 'daily_issued_cards', 'weekly_issued_cards', 'monthly_issued_cards',
      // Dead print/shipping related keys
      'manage_print_requests', 'manage_batches', 'print_request_pipeline',
      'print_submitted', 'print_processing', 'print_shipping',
      'shipping_address', 'shipping_info', 'recipient_name',
      'address_line_1', 'address_line_2', 'city', 'state_province',
      'postal_code', 'country', 'phone_number',
      'issuance_reason', 'issuance_summary', 'free_issuance',
      'cards_issued_to', 'issuing_batch', 'cards_created',
      'search_user_first', 'min_1_max_10000', 'enter_batch_quantity',
      'explain_why_issuing', 'auto_generated', 'regular_cost',
      'request_id', 'requested_by', 'requested_at', 'request_status',
      'request_details', 'admin_feedbacks', 'internal_note',
      'status_updated_successfully', 'failed_to_update_status',
      'no_requests_match_filters', 'search_by_user_card_batch',
      'unnamed_user', 'user_information', 'contact_email', 'whatsapp',
      'filter_by_status', 'view_card_details', 'please_enter_email',
      'loaded_cards', 'search_user', 'select_card',
      'issue_free_batch_button', 'physical_cards', 'issued'
    ];

    for (const key of adminKeysToRemove) {
      if (obj.admin[key] !== undefined) {
        delete obj.admin[key];
        console.log(`  Removing: admin.${key}`);
      }
    }

    // Clean activity_types
    if (obj.admin.activity_types) {
      const activityKeysToRemove = [
        'batch_issuance', 'batch_status_changes', 'free_batch_issuance',
        'print_request_submissions', 'print_request_updates', 'print_request_withdrawals'
      ];
      for (const key of activityKeysToRemove) {
        if (obj.admin.activity_types[key] !== undefined) {
          delete obj.admin.activity_types[key];
          console.log(`  Removing: admin.activity_types.${key}`);
        }
      }
    }
  }

  // Clean dashboard section
  if (obj.dashboard) {
    const dashboardKeysToRemove = [
      'physical_card', 'physical_card_desc', 'physical_card_full_desc',
      'physical_mode_title', 'physical_mode_hint',
      'issuance', 'card_issuance', 'access_physical',
      'tab_hint_issuance'
    ];
    for (const key of dashboardKeysToRemove) {
      if (obj.dashboard[key] !== undefined) {
        delete obj.dashboard[key];
        console.log(`  Removing: dashboard.${key}`);
      }
    }
  }

  // Clean credits section - remove physicalCards and physicalCardsDesc
  if (obj.credits) {
    if (obj.credits.physicalCards !== undefined) {
      delete obj.credits.physicalCards;
      console.log('  Removing: credits.physicalCards');
    }
    if (obj.credits.physicalCardsDesc !== undefined) {
      delete obj.credits.physicalCardsDesc;
      console.log('  Removing: credits.physicalCardsDesc');
    }
    // Clean consumptionType
    if (obj.credits.consumptionType) {
      if (obj.credits.consumptionType.batch_issuance !== undefined) {
        delete obj.credits.consumptionType.batch_issuance;
        console.log('  Removing: credits.consumptionType.batch_issuance');
      }
      if (obj.credits.consumptionType.physical_card_order !== undefined) {
        delete obj.credits.consumptionType.physical_card_order;
        console.log('  Removing: credits.consumptionType.physical_card_order');
      }
    }
  }

  // Clean checkout section
  if (obj.checkout) {
    const checkoutKeysToRemove = [
      'batch_checkout', 'batch_quantity'
    ];
    for (const key of checkoutKeysToRemove) {
      if (obj.checkout[key] !== undefined) {
        delete obj.checkout[key];
        console.log(`  Removing: checkout.${key}`);
      }
    }
  }

  // Clean landing page sections
  if (obj.landing) {
    // Clean demo section mode_toggle and physical_card
    if (obj.landing.demo) {
      if (obj.landing.demo.mode_toggle) {
        if (obj.landing.demo.mode_toggle.physical_card !== undefined) {
          delete obj.landing.demo.mode_toggle.physical_card;
          console.log('  Removing: landing.demo.mode_toggle.physical_card');
        }
      }
      if (obj.landing.demo.physical_card !== undefined) {
        delete obj.landing.demo.physical_card;
        console.log('  Removing: landing.demo.physical_card');
      }
    }

    // Clean pricing section - physical_cards subsection
    if (obj.landing.pricing) {
      if (obj.landing.pricing.physical_cards !== undefined) {
        delete obj.landing.pricing.physical_cards;
        console.log('  Removing: landing.pricing.physical_cards');
      }
    }
  }

  return obj;
}

// Process each file
for (const file of localeFiles) {
  const filePath = path.join(LOCALE_DIR, file);

  if (!fs.existsSync(filePath)) {
    console.log(`Skipping ${file} (not found)`);
    continue;
  }

  console.log(`\nProcessing ${file}...`);

  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    let json = JSON.parse(content);

    // First pass: general pattern-based cleanup
    json = cleanObject(json);

    // Second pass: specific contextual cleanup
    json = additionalCleanup(json);

    // Write back with same formatting
    const output = JSON.stringify(json, null, 2) + '\n';
    fs.writeFileSync(filePath, output, 'utf-8');

    console.log(`  Done: ${file}`);
  } catch (err) {
    console.error(`  Error processing ${file}:`, err.message);
  }
}

console.log('\nCleanup complete!');

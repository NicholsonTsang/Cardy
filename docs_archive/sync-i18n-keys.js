#!/usr/bin/env node

/**
 * I18n Translation Key Sync Script
 * 
 * This script compares en.json with other language files and:
 * 1. Reports missing keys
 * 2. Optionally adds missing keys with English fallbacks
 * 
 * Usage:
 *   node scripts/sync-i18n-keys.js                  # Report missing keys
 *   node scripts/sync-i18n-keys.js --fix            # Add missing keys with English fallbacks
 *   node scripts/sync-i18n-keys.js --lang ko --fix  # Fix specific language
 */

const fs = require('fs');
const path = require('path');

const LOCALES_DIR = path.join(__dirname, '../src/i18n/locales');
const BASE_LOCALE = 'en';

// Parse command line arguments
const args = process.argv.slice(2);
const shouldFix = args.includes('--fix');
const targetLang = args.find(arg => arg.startsWith('--lang'))?.split('=')[1] || null;

// Get all keys from an object recursively
function getAllKeys(obj, prefix = '') {
  let keys = [];
  for (const [key, value] of Object.entries(obj)) {
    const fullKey = prefix ? `${prefix}.${key}` : key;
    if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      keys = keys.concat(getAllKeys(value, fullKey));
    } else {
      keys.push(fullKey);
    }
  }
  return keys;
}

// Get nested value from object using dot notation
function getNestedValue(obj, path) {
  return path.split('.').reduce((current, key) => current?.[key], obj);
}

// Set nested value in object using dot notation
function setNestedValue(obj, path, value) {
  const keys = path.split('.');
  const lastKey = keys.pop();
  const target = keys.reduce((current, key) => {
    if (!current[key]) current[key] = {};
    return current[key];
  }, obj);
  target[lastKey] = value;
}

// Load base locale (English)
const baseLocaleFile = path.join(LOCALES_DIR, `${BASE_LOCALE}.json`);
const baseTranslations = JSON.parse(fs.readFileSync(baseLocaleFile, 'utf8'));
const baseKeys = getAllKeys(baseTranslations);

console.log(`📚 Base locale (${BASE_LOCALE}): ${baseKeys.length} keys\n`);

// Get all language files
const languageFiles = fs.readdirSync(LOCALES_DIR)
  .filter(file => file.endsWith('.json') && file !== `${BASE_LOCALE}.json`)
  .map(file => file.replace('.json', ''));

// Filter by target language if specified
const languagesToCheck = targetLang 
  ? languageFiles.filter(lang => lang === targetLang)
  : languageFiles;

if (targetLang && languagesToCheck.length === 0) {
  console.error(`❌ Language '${targetLang}' not found`);
  process.exit(1);
}

let totalMissing = 0;
let totalFixed = 0;

// Check each language
for (const lang of languagesToCheck) {
  const langFile = path.join(LOCALES_DIR, `${lang}.json`);
  const langTranslations = JSON.parse(fs.readFileSync(langFile, 'utf8'));
  const langKeys = getAllKeys(langTranslations);
  
  // Find missing keys
  const missingKeys = baseKeys.filter(key => !langKeys.includes(key));
  
  if (missingKeys.length === 0) {
    console.log(`✅ ${lang}.json - Complete! (${langKeys.length}/${baseKeys.length} keys)`);
    continue;
  }
  
  totalMissing += missingKeys.length;
  const coverage = ((langKeys.length / baseKeys.length) * 100).toFixed(1);
  
  console.log(`⚠️  ${lang}.json - ${missingKeys.length} missing keys (${coverage}% coverage)`);
  
  if (shouldFix) {
    // Add missing keys with English fallbacks
    for (const key of missingKeys) {
      const englishValue = getNestedValue(baseTranslations, key);
      setNestedValue(langTranslations, key, englishValue);
    }
    
    // Write updated file with proper formatting
    fs.writeFileSync(
      langFile,
      JSON.stringify(langTranslations, null, 2) + '\n',
      'utf8'
    );
    
    totalFixed += missingKeys.length;
    console.log(`   ✅ Added ${missingKeys.length} keys with English fallbacks`);
  } else {
    // Just show first 10 missing keys as examples
    console.log(`   Missing keys (showing first 10):`);
    missingKeys.slice(0, 10).forEach(key => {
      console.log(`     - ${key}`);
    });
    if (missingKeys.length > 10) {
      console.log(`     ... and ${missingKeys.length - 10} more`);
    }
  }
  
  console.log('');
}

// Summary
console.log('─'.repeat(60));
if (shouldFix) {
  console.log(`✅ Fixed ${totalFixed} missing keys across ${languagesToCheck.length} language(s)`);
  console.log('');
  console.log('📝 Next steps:');
  console.log('   1. Review the updated files');
  console.log('   2. Replace English fallbacks with proper translations');
  console.log('   3. Test the application in different languages');
} else {
  console.log(`📊 Summary: ${totalMissing} total missing keys across ${languagesToCheck.length} language(s)`);
  console.log('');
  console.log('💡 To automatically add missing keys with English fallbacks:');
  console.log('   node scripts/sync-i18n-keys.js --fix');
  console.log('');
  console.log('💡 To fix a specific language:');
  console.log('   node scripts/sync-i18n-keys.js --lang=ko --fix');
}
console.log('─'.repeat(60));

process.exit(totalMissing > 0 && !shouldFix ? 1 : 0);


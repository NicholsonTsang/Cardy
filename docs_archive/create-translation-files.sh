#!/bin/bash

# Create placeholder translation files for all languages
# These should be professionally translated before production use

cd src/i18n/locales

# Copy English as template for remaining languages
for lang in zh-Hans ja ko es fr ru ar th; do
  echo "Creating $lang.json..."
  cp en.json $lang.json
done

echo "✅ Translation files created!"
echo "⚠️  IMPORTANT: These files contain English text as placeholders."
echo "📝 Please have them professionally translated before deployment."
echo ""
echo "Files created:"
ls -1 *.json


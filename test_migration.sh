#!/bin/bash

# GeNews Migration Test Script
echo "🚀 GeNews Migration Test Script"
echo "================================"

# Check Flutter installation
echo "📱 Checking Flutter installation..."
flutter --version

# Navigate to project directory
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Run code analysis
echo "🔍 Running code analysis..."
flutter analyze

# Check for any compilation errors
echo "🔧 Checking for compilation errors..."
flutter build apk --debug --target-platform android-arm64 --no-shrink

# Run tests if available
echo "🧪 Running tests..."
flutter test

echo "✅ Migration test completed!"
echo ""
echo "🎯 Next steps:"
echo "1. Run the app: flutter run"
echo "2. Test Firestore connectivity"
echo "3. Verify data is loading from Firestore"
echo "4. Test all app features (search, categories, bookmarks, AI analysis)"
echo ""
echo "🛠️ Debug tools:"
echo "- Use MigrationTestService.testMigration() to test Firestore"
echo "- Add MigrationTestWidget to debug UI issues"
echo "- Check Firebase Console for Firestore data"

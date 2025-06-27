@echo off
REM GeNews Migration Test Script for Windows
echo 🚀 GeNews Migration Test Script
echo ================================

REM Check Flutter installation
echo 📱 Checking Flutter installation...
flutter --version

REM Navigate to project directory
cd /d "%~dp0"

REM Install dependencies
echo 📦 Installing Flutter dependencies...
flutter pub get

REM Run code analysis
echo 🔍 Running code analysis...
flutter analyze

REM Check for any compilation errors (using web for faster testing)
echo 🔧 Checking for compilation errors...
flutter build web --no-tree-shake-icons

REM Run tests if available
echo 🧪 Running tests...
flutter test

echo ✅ Migration test completed!
echo.
echo 🎯 Next steps:
echo 1. Run the app: flutter run
echo 2. Test Firestore connectivity
echo 3. Verify data is loading from Firestore
echo 4. Test all app features (search, categories, bookmarks, AI analysis)
echo.
echo 🛠️ Debug tools:
echo - Use MigrationTestService.testMigration() to test Firestore
echo - Add MigrationTestWidget to debug UI issues
echo - Check Firebase Console for Firestore data
echo.
pause

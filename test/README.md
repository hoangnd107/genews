# 🧪 Test Utilities

Thư mục này chứa các utilities và tools để test ứng dụng GeNews.

## 📁 Cấu trúc

```
test/
├── screens/           # Test screens & debug tools
│   └── debug_screen.dart
├── widgets/           # Test widgets
│   ├── firestore_category_test_widget.dart
│   └── category_mapping_test_widget.dart
├── services/          # Test services & helpers
│   ├── firestore_test_service.dart
│   └── firestore_permission_helper.dart
├── test_utils.dart    # Export file cho tất cả test utilities
├── widget_test.dart   # Flutter default widget test
└── README.md         # File này
```

## 🔧 Sử dụng

### 1. Import Test Utils

```dart
import 'package:genews/test/test_utils.dart';
```

### 2. Debug Screen

Screen debug với các tools để test Firestore:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DebugScreen()),
);
```

### 3. Test Services

```dart
// Test Firestore connection
final result = await FirestoreTestService.testFirestoreConnection();

// Diagnose permissions
final diagnosis = await FirestorePermissionHelper.diagnosePermissions();
```

## 🚨 Chú ý

- Các file trong thư mục này CHỈ dành cho development/testing
- KHÔNG import vào production code
- Đảm bảo remove debug code trước khi release

## 🎯 Mục đích

1. **Debug Tools**: Kiểm tra connectivity, permissions
2. **Test Widgets**: Test UI components riêng lẻ
3. **Test Services**: Test business logic và data layer
4. **Development Helpers**: Tools hỗ trợ development

---

**⚠️ Development Only - Do not include in production builds!**

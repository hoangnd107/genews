import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genews/core/constants.dart';

/// Service to troubleshoot and fix common Firestore permission issues
class FirestorePermissionHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test Firestore permissions and provide detailed diagnostics
  static Future<Map<String, dynamic>> diagnosePermissions() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'recommendations': <String>[],
      'status': 'unknown',
    };

    try {
      // Test 1: Basic connection
      results['tests']['connection'] = await _testConnection();

      // Test 2: Read permissions on articles collection
      results['tests']['articles_read'] = await _testArticlesRead();

      // Test 3: Count documents
      results['tests']['count_articles'] = await _testCountArticles();

      // Test 4: Query with orderBy (this often fails with permissions)
      results['tests']['ordered_query'] = await _testOrderedQuery();

      // Analyze results and provide recommendations
      _analyzeResults(results);
    } catch (e) {
      results['error'] = e.toString();
      results['status'] = 'failed';
      results['recommendations'].add('Critical error occurred during testing');
    }

    return results;
  }

  static Future<Map<String, dynamic>> _testConnection() async {
    try {
      // Try to access Firestore settings (this tests basic connection)
      final settings = _firestore.settings;
      return {
        'status': 'success',
        'message': 'Firestore connection established',
        'details': {
          'host': settings.host,
          'ssl_enabled': settings.sslEnabled,
          'persistence_enabled': settings.persistenceEnabled,
        },
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'Failed to establish Firestore connection',
      };
    }
  }

  static Future<Map<String, dynamic>> _testArticlesRead() async {
    try {
      final snapshot = await _firestore
          .collection(articlesCollectionName)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      return {
        'status': 'success',
        'message': 'Successfully read from articles collection',
        'doc_count': snapshot.docs.length,
      };
    } catch (e) {
      final errorMessage = e.toString();
      return {
        'status': 'failed',
        'error': errorMessage,
        'message': 'Failed to read articles collection',
        'is_permission_error': errorMessage.contains('PERMISSION_DENIED'),
      };
    }
  }

  static Future<Map<String, dynamic>> _testCountArticles() async {
    try {
      final snapshot =
          await _firestore.collection(articlesCollectionName).count().get();

      return {
        'status': 'success',
        'message': 'Successfully counted articles',
        'total_count': snapshot.count,
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'Failed to count articles',
      };
    }
  }

  static Future<Map<String, dynamic>> _testOrderedQuery() async {
    try {
      final snapshot =
          await _firestore
              .collection(articlesCollectionName)
              .orderBy('pubDate', descending: true)
              .limit(1)
              .get();

      return {
        'status': 'success',
        'message': 'Successfully executed ordered query',
        'doc_count': snapshot.docs.length,
      };
    } catch (e) {
      final errorMessage = e.toString();
      return {
        'status': 'failed',
        'error': errorMessage,
        'message': 'Failed to execute ordered query',
        'is_permission_error': errorMessage.contains('PERMISSION_DENIED'),
        'needs_index': errorMessage.contains('index'),
      };
    }
  }

  static void _analyzeResults(Map<String, dynamic> results) {
    final tests = results['tests'] as Map<String, dynamic>;
    final recommendations = results['recommendations'] as List<String>;

    // Check connection
    if (tests['connection']['status'] != 'success') {
      results['status'] = 'critical';
      recommendations.add(
        '❌ Firestore connection failed - check Firebase configuration',
      );
      recommendations.add('  → Verify firebase_options.dart exists');
      recommendations.add(
        '  → Check google-services.json (Android) or GoogleService-Info.plist (iOS)',
      );
      return;
    }

    // Check read permissions
    if (tests['articles_read']['status'] != 'success') {
      if (tests['articles_read']['is_permission_error'] == true) {
        results['status'] = 'permission_denied';
        recommendations.add('🚨 PERMISSION DENIED - Update Firestore Rules');
        recommendations.add('  → Go to Firebase Console → Firestore → Rules');
        recommendations.add(
          '  → Add rule: match /articles/{document} { allow read: if true; }',
        );
        recommendations.add('  → Click Publish and restart app');
      } else {
        results['status'] = 'read_error';
        recommendations.add('❌ Cannot read articles collection');
        recommendations.add('  → Check if articles collection exists');
        recommendations.add('  → Run Python scripts to populate data');
      }
      return;
    }

    // Check if collection is empty
    if (tests['count_articles']['total_count'] == 0) {
      results['status'] = 'empty_collection';
      recommendations.add('⚠️ Articles collection is empty');
      recommendations.add(
        '  → Run Python scripts: cd python && python main.py',
      );
      recommendations.add('  → Check Firebase Console for data');
      return;
    }

    // Check ordered query (this is what the app uses)
    if (tests['ordered_query']['status'] != 'success') {
      if (tests['ordered_query']['is_permission_error'] == true) {
        results['status'] = 'query_permission_denied';
        recommendations.add('🚨 Ordered query permission denied');
        recommendations.add('  → Update Firestore rules to allow queries');
        recommendations.add(
          '  → Rule: match /articles/{document} { allow read: if true; }',
        );
      } else if (tests['ordered_query']['needs_index'] == true) {
        results['status'] = 'missing_index';
        recommendations.add('📊 Missing Firestore index');
        recommendations.add(
          '  → Firebase will auto-create index on first query',
        );
        recommendations.add('  → Or manually create index in Firebase Console');
      } else {
        results['status'] = 'query_error';
        recommendations.add('❌ Query execution failed');
      }
      return;
    }

    // If all tests pass
    results['status'] = 'success';
    recommendations.add('✅ All Firestore permissions working correctly');
    recommendations.add(
      '✅ Articles collection has ${tests['count_articles']['total_count']} documents',
    );
    recommendations.add('✅ App should work properly now');
  }

  /// Generate Firestore rules for common scenarios
  static String generateFirestoreRules({
    bool allowRead = true,
    bool allowWrite = false,
    bool developmentMode = false,
  }) {
    if (developmentMode) {
      return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // DEVELOPMENT MODE - Allow all reads, no writes
    match /{document=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}''';
    }

    return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Articles collection - News data
    match /articles/{document} {
      allow read: if $allowRead;
      allow write: if $allowWrite;
    }
    
    // News data collection (legacy)
    match /news_data/{document} {
      allow read: if $allowRead;
      allow write: if $allowWrite;
    }
    
    // User-specific data (bookmarks, preferences)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Block everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}''';
  }

  /// Print detailed diagnosis report
  static void printDiagnosisReport(Map<String, dynamic> results) {
    print('\n🔍 FIRESTORE PERMISSION DIAGNOSIS REPORT');
    print('=' * 50);
    print('Timestamp: ${results['timestamp']}');
    print('Status: ${results['status']?.toString().toUpperCase()}');

    if (results['error'] != null) {
      print('\n❌ CRITICAL ERROR:');
      print(results['error']);
      return;
    }

    print('\n📊 TEST RESULTS:');
    final tests = results['tests'] as Map<String, dynamic>;
    tests.forEach((testName, testResult) {
      final status = testResult['status'] == 'success' ? '✅' : '❌';
      print('  $status $testName: ${testResult['message']}');
      if (testResult['error'] != null) {
        print('    Error: ${testResult['error']}');
      }
    });

    print('\n💡 RECOMMENDATIONS:');
    final recommendations = results['recommendations'] as List<String>;
    for (final rec in recommendations) {
      print('  $rec');
    }

    if (results['status'] == 'permission_denied') {
      print('\n🚨 URGENT: FIRESTORE RULES NEEDED');
      print('Copy this rule to Firebase Console → Firestore → Rules:');
      print('-' * 50);
      print(generateFirestoreRules(developmentMode: true));
      print('-' * 50);
    }

    print('\n');
  }
}

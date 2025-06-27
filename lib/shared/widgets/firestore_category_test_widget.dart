import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genews/core/constants.dart';
import 'package:genews/shared/services/category_mapping_service.dart';

class FirestoreCategoryTestWidget extends StatefulWidget {
  const FirestoreCategoryTestWidget({super.key});

  @override
  State<FirestoreCategoryTestWidget> createState() =>
      _FirestoreCategoryTestWidgetState();
}

class _FirestoreCategoryTestWidgetState
    extends State<FirestoreCategoryTestWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _testResult = "";

  @override
  void initState() {
    super.initState();
    _testFirestoreCategories();
  }

  Future<void> _testFirestoreCategories() async {
    setState(() {
      _isLoading = true;
      _testResult = "Đang kiểm tra Firestore category structure...\\n";
    });

    try {
      // Get first 10 articles to check category structure
      final querySnapshot =
          await _firestore.collection(articlesCollectionName).limit(10).get();

      setState(() {
        _testResult += "\\n🎯 CATEGORY STRUCTURE ANALYSIS:\\n";
        _testResult += "=====================================\\n";
        _testResult += "✅ Connected to Firestore successfully\\n";
        _testResult += "📄 Found ${querySnapshot.docs.length} articles\\n\\n";
      });

      List<Map<String, dynamic>> articles = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        articles.add({
          'id': doc.id,
          'title': data['title']?.toString() ?? 'No title',
          'category': data['category'],
          'source_name': data['source_name']?.toString() ?? 'Unknown source',
        });

        // Log category structure
        final category = data['category'];
        setState(() {
          _testResult +=
              "📰 Article: ${data['title']?.toString().substring(0, 30)}...\\n";
          _testResult += "   Category type: ${category.runtimeType}\\n";
          _testResult += "   Category value: $category\\n";

          if (category is List) {
            _testResult += "   Array length: ${category.length}\\n";
            for (int i = 0; i < category.length; i++) {
              final cat = category[i].toString();
              final isViet = _isVietnamese(cat);
              final translated = CategoryMappingService.toVietnamese(cat);
              _testResult +=
                  "   [$i] $cat (${isViet ? 'VN' : 'EN'}) -> $translated\\n";
            }
          } else if (category != null) {
            final cat = category.toString();
            final isViet = _isVietnamese(cat);
            final translated = CategoryMappingService.toVietnamese(cat);
            _testResult +=
                "   String: $cat (${isViet ? 'VN' : 'EN'}) -> $translated\\n";
          }
          _testResult += "\\n";
        });
      }

      setState(() {
        _testResult += "🔍 Testing array-contains query with 'education'...\\n";
      });

      // Test array-contains query
      try {
        final testQuery =
            await _firestore
                .collection(articlesCollectionName)
                .where('category', arrayContains: 'education')
                .limit(5)
                .get();

        setState(() {
          _testResult +=
              "✅ Array-contains 'education': ${testQuery.docs.length} results\\n";
        });
      } catch (e) {
        setState(() {
          _testResult += "❌ Array-contains 'education' failed: $e\\n";
        });
      }

      // Test array-contains query with Vietnamese
      try {
        final testQueryVN =
            await _firestore
                .collection(articlesCollectionName)
                .where('category', arrayContains: 'Giáo dục')
                .limit(5)
                .get();

        setState(() {
          _testResult +=
              "✅ Array-contains 'Giáo dục': ${testQueryVN.docs.length} results\\n";
        });
      } catch (e) {
        setState(() {
          _testResult += "❌ Array-contains 'Giáo dục' failed: $e\\n";
        });
      }
    } catch (e) {
      setState(() {
        _testResult += "❌ Error testing Firestore: $e\\n";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isVietnamese(String text) {
    final vietnameseRegex = RegExp(
      r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]',
    );
    return vietnameseRegex.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Category Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kiểm tra cấu trúc Category trong Firestore',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang kiểm tra dữ liệu...'),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test Results
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _testResult.isEmpty
                            ? 'Chưa có kết quả test...'
                            : _testResult,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : _testFirestoreCategories,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Test lại'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _testSpecificCategory('education'),
                          icon: const Icon(Icons.search),
                          label: const Text('Test Education'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _testSpecificCategory('Giáo dục'),
                          icon: const Icon(Icons.search),
                          label: const Text('Test Giáo dục'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSpecificCategory(String category) async {
    setState(() {
      _testResult += "\\n🔍 Testing specific category: $category\\n";
    });

    try {
      final querySnapshot =
          await _firestore
              .collection(articlesCollectionName)
              .where('category', arrayContains: category)
              .limit(10)
              .get();

      setState(() {
        _testResult +=
            "✅ Found ${querySnapshot.docs.length} articles for '$category'\\n";
      });

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        setState(() {
          _testResult +=
              "   - ${data['title']?.toString().substring(0, 50)}...\\n";
          _testResult += "     Category: ${data['category']}\\n";
        });
      }
    } catch (e) {
      setState(() {
        _testResult += "❌ Error testing category '$category': $e\\n";
      });
    }
  }
}

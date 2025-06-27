import 'package:flutter/material.dart';
import 'package:genews/shared/services/category_mapping_service.dart';
import 'package:genews/shared/styles/colors.dart';

/// Widget để test category mapping trong development
class CategoryMappingTestWidget extends StatefulWidget {
  const CategoryMappingTestWidget({super.key});

  @override
  State<CategoryMappingTestWidget> createState() =>
      _CategoryMappingTestWidgetState();
}

class _CategoryMappingTestWidgetState extends State<CategoryMappingTestWidget> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';

  // Test categories that might be in Firestore
  final List<String> _testCategories = [
    'business',
    'Kinh doanh',
    'technology',
    'Công nghệ',
    'sports',
    'Thể thao',
    'education',
    'Giáo dục',
    'entertainment',
    'Giải trí',
    'health',
    'Sức khỏe',
    'politics',
    'Chính trị',
    'world',
    'Thế giới',
    'food',
    'Ẩm thực',
    'lifestyle',
    'Đời sống',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 Category Mapping Test'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Manual Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Enter category (EN or VI)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _testMapping(_controller.text),
                          child: const Text('Test Mapping'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _controller.clear(),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    if (_result.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_result),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📊 Pre-defined Categories Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _testCategories.length,
                itemBuilder: (context, index) {
                  final category = _testCategories[index];
                  final toVietnamese = CategoryMappingService.toVietnamese(
                    category,
                  );
                  final toEnglish = CategoryMappingService.toEnglish(category);
                  final isValid = CategoryMappingService.isValidCategory(
                    category,
                  );

                  return Card(
                    child: ListTile(
                      title: Text(category),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('→ Vietnamese: $toVietnamese'),
                          Text('→ English: $toEnglish'),
                          Text('→ Valid: $isValid'),
                        ],
                      ),
                      leading: Icon(
                        isValid ? Icons.check_circle : Icons.error,
                        color: isValid ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runAllTests,
        child: const Icon(Icons.play_arrow),
        tooltip: 'Run All Tests',
      ),
    );
  }

  void _testMapping(String input) {
    if (input.isEmpty) return;

    final toVi = CategoryMappingService.toVietnamese(input);
    final toEn = CategoryMappingService.toEnglish(input);
    final isValid = CategoryMappingService.isValidCategory(input);
    final key = CategoryMappingService.getCategoryKey(input);

    setState(() {
      _result = '''
Input: "$input"
→ Vietnamese: "$toVi"
→ English: "$toEn"
→ Query Key: "$key"
→ Valid: $isValid
''';
    });
  }

  void _runAllTests() {
    debugPrint('\n🧪 CATEGORY MAPPING TEST RESULTS');
    debugPrint('=' * 50);

    for (final category in _testCategories) {
      final toVi = CategoryMappingService.toVietnamese(category);
      final toEn = CategoryMappingService.toEnglish(category);
      final isValid = CategoryMappingService.isValidCategory(category);
      final key = CategoryMappingService.getCategoryKey(category);

      debugPrint('Input: "$category"');
      debugPrint('  → Vietnamese: "$toVi"');
      debugPrint('  → English: "$toEn"');
      debugPrint('  → Query Key: "$key"');
      debugPrint('  → Valid: $isValid');
      debugPrint('');
    }

    debugPrint('📊 AVAILABLE CATEGORIES:');
    debugPrint(
      'Vietnamese: ${CategoryMappingService.getAllVietnameseCategories()}',
    );
    debugPrint('English: ${CategoryMappingService.getAllEnglishCategories()}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ All tests completed - check console output'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

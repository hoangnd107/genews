import 'package:flutter/material.dart';
import 'package:genews/shared/services/migration_test_service.dart';
import 'package:genews/shared/styles/colors.dart';

/// Debug widget để test migration trong development
class MigrationTestWidget extends StatefulWidget {
  const MigrationTestWidget({super.key});

  @override
  State<MigrationTestWidget> createState() => _MigrationTestWidgetState();
}

class _MigrationTestWidgetState extends State<MigrationTestWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migration Test'),
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
                      '🚀 Migration Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test the migration from newsdata.io API to Firestore',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runMigrationTest,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : 'Run Migration Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (_testResults != null) ...[
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _testResults!['success'] == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  _testResults!['success'] == true
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _testResults!['success'] == true
                                  ? 'Migration Successful'
                                  : 'Migration Failed',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildTestResults(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runMigrationTest() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
    });

    try {
      final results = await MigrationTestService.testMigration();
      final freshness = await MigrationTestService.checkDataFreshness();

      setState(() {
        _testResults = {...results, 'freshness': freshness};
      });

      // Print summary to console
      MigrationTestService.printMigrationSummary();
    } catch (e) {
      setState(() {
        _testResults = {'success': false, 'error': e.toString()};
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTestResults() {
    if (_testResults == null) return const SizedBox.shrink();

    if (_testResults!['success'] != true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error Details:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            _testResults!['error'] ?? 'Unknown error',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            _testResults!['message'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultItem(
          '📊',
          'Total Articles',
          _testResults!['total_articles']?.toString() ?? '0',
        ),
        _buildResultItem(
          '📈',
          'Trending Sample',
          _testResults!['trending_sample']?.toString() ?? '0',
        ),
        _buildResultItem(
          '🔍',
          'Search Results',
          _testResults!['search_results']?.toString() ?? '0',
        ),
        _buildResultItem(
          '📂',
          'Categories',
          (_testResults!['categories'] as List?)?.length.toString() ?? '0',
        ),
        _buildResultItem(
          '🏷️',
          'Category Sample',
          _testResults!['category_sample']?.toString() ?? '0',
        ),

        const SizedBox(height: 16),
        const Text(
          'Data Freshness:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_testResults!['freshness'] != null) ...[
          _buildResultItem(
            '🕒',
            'Recent Articles (24h)',
            _testResults!['freshness']['recent_articles']?.toString() ?? '0',
          ),
          _buildResultItem(
            _testResults!['freshness']['is_fresh'] == true ? '✅' : '⚠️',
            'Data Status',
            _testResults!['freshness']['is_fresh'] == true ? 'Fresh' : 'Stale',
          ),
        ],

        const SizedBox(height: 16),
        const Text(
          'Available Categories:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_testResults!['categories'] != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                (_testResults!['categories'] as List).map<Widget>((category) {
                  return Chip(
                    label: Text(
                      category.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
          ),
        ],

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Migration Complete!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _testResults!['message'] ?? 'Migration successful',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

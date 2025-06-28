import 'package:flutter/material.dart';
import '../widgets/firestore_category_test_widget.dart';
import '../services/firestore_test_service.dart';
import '../services/firestore_permission_helper.dart';
import 'package:genews/shared/styles/colors.dart';

/// Debug screen để test Firestore connectivity
/// Chỉ sử dụng trong development
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Debug Tools'),
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
                      'Test the migration from API to Firestore',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Test Buttons
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final result =
                      await FirestoreTestService.testFirestoreConnection();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['success'] == true
                              ? '✅ Firestore connection OK'
                              : '❌ Firestore connection failed',
                        ),
                        backgroundColor:
                            result['success'] == true
                                ? Colors.green
                                : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.cloud_done),
              label: const Text('Test Firestore Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final results =
                      await FirestorePermissionHelper.diagnosePermissions();
                  FirestorePermissionHelper.printDiagnosisReport(results);

                  if (mounted) {
                    final status = results['status'];
                    final isSuccess = status == 'success';
                    final message =
                        isSuccess
                            ? '✅ All permissions OK'
                            : '🚨 Permission issues found - check console';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor:
                            isSuccess ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Diagnosis failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.security),
              label: const Text('Diagnose Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirestoreCategoryTestWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.category),
              label: const Text('Test Firestore Categories'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Run "Quick Migration Test" first\n'
                      '2. If it fails, check Firestore connection\n'
                      '3. Ensure Python scripts have populated data\n'
                      '4. Use "Detailed Test" for comprehensive analysis\n'
                      '5. Check console logs for detailed information',
                      style: TextStyle(color: Colors.blue),
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
}

import 'package:flutter/material.dart';
import 'package:genews/shared/widgets/paginated_list_view.dart';

class PaginationDemoScreen extends StatelessWidget {
  const PaginationDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tạo demo data với 100 items
    final List<String> demoItems = List.generate(
      100,
      (index) => 'Item ${index + 1}',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Pagination UI'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: PaginatedListView<String>(
        items: demoItems,
        itemsPerPage: 10,
        emptyMessage: 'Không có dữ liệu demo',
        itemBuilder: (context, item, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Demo item với pagination hiện đại - Page ${(index ~/ 10) + 1}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tapped on $item'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

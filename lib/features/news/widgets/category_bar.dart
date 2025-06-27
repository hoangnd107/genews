import 'package:flutter/material.dart';
import 'package:genews/shared/services/category_mapping_service.dart';

class CategoryBar extends StatefulWidget {
  final Function(String) onCategorySelected;
  final String? selectedCategory;
  final List<String>? availableCategories;

  const CategoryBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.availableCategories,
  });

  @override
  State<CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  final List<String> _categories = [
    'top',
    'business',
    'sports',
    'education',
    'entertainment',
    'environment',
    'food',
    'health',
    'lifestyle',
    'politics',
    'science',
    'technology',
    'tourism',
    'world',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.brightness == Brightness.light
            ? Colors.grey.shade200
            : Colors.grey.shade800;

    // Use provided categories or fall back to default list
    final categories = widget.availableCategories ?? _categories;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = widget.selectedCategory == category;
          return CategoryItem(
            label: CategoryMappingService.toVietnamese(category),
            isSelected: isSelected,
            onTap: () => widget.onCategorySelected(category),
          );
        },
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

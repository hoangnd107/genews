import 'package:flutter/material.dart';
import 'package:genews/shared/styles/colors.dart';

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

  Widget build(BuildContext context) {
    // Use provided categories or fall back to default list
    final categories = availableCategories ?? [
      'Thời sự', 'Thế giới', 'Kinh doanh', 'Giải trí',
      'Thể thao', 'Pháp luật', 'Giáo dục', 'Sức khỏe',
      'Đời sống', 'Du lịch', 'Khoa học', 'Số hóa', 'Xe'
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
              backgroundColor: Colors.grey.shade200,
              selectedColor: AppColors.primaryColor.withOpacity(0.2),
              checkmarkColor: AppColors.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryBarState extends State<CategoryBar> {
  // Map of English categories to Vietnamese translations
  final Map<String, String> _categoryTranslations = {
    'business': 'Kinh doanh',
    'crime': 'Tội phạm',
    'domestic': 'Trong nước',
    'education': 'Giáo dục',
    'entertainment': 'Giải trí',
    'environment': 'Môi trường',
    'food': 'Ẩm thực',
    'health': 'Sức khỏe',
    'lifestyle': 'Đời sống',
    'politics': 'Chính trị',
    'science': 'Khoa học',
    'sports': 'Thể thao',
    'technology': 'Công nghệ',
    'top': 'Nổi bật',
    'tourism': 'Du lịch',
    'world': 'Thế giới',
    'other': 'Khác',
  };

  final List<String> _categories = [
    'top', 'business', 'sports', 'education', 'entertainment',
    'environment', 'food', 'health', 'lifestyle', 'politics',
    'science', 'sports', 'technology', 'tourism',
    'world', 'other'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.light
        ? Colors.grey.shade200
        : Colors.grey.shade800;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = widget.selectedCategory == category;
          return CategoryItem(
            label: _categoryTranslations[category] ?? category,
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
            color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:genews/shared/services/category_mapping_service.dart';

class CategoryBar extends StatefulWidget {
  final Function(String) onCategorySelected;
  final String? selectedCategory;
  final List<String>? availableCategories;
  final IconData Function(String)? getCategoryIcon;
  final List<Color> Function(String)? getCategoryColors;
  final bool enableAutoScroll; // NEW

  const CategoryBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.availableCategories,
    this.getCategoryIcon,
    this.getCategoryColors,
    this.enableAutoScroll = true, // default: true
  });

  @override
  State<CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  final List<String> _categories = [
    'Tất cả',
    'top',
    'world',
    'politics',
    'business',
    'startup',
    'technology',
    'science',
    'education',
    'health',
    'sports',
    'entertainment',
    'lifestyle',
    'food',
    'environment',
    'society',
    'law',
    'crime',
    'opinion',
    'current',
    'most-viewed',
    'funny',
    'confession',
    'auto',
    'job',
    'real-estate',
    'tourism',
    'homepage',
    'domestic',
    'digital',
    'other',
  ];

  ScrollController? _scrollController;
  Map<String, GlobalKey> _itemKeys = {};
  List<String> _lastCategories = [];

  List<String> get _currentCategories =>
      widget.availableCategories ?? _categories;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initItemKeys();
    if (widget.enableAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _initItemKeys() {
    final categories = _currentCategories;
    if (_lastCategories.length != categories.length ||
        !_lastCategories.asMap().entries.every(
          (e) => e.value == categories[e.key],
        )) {
      // Danh sách category đã thay đổi, reset lại key
      _itemKeys = {for (final cat in categories) cat: GlobalKey()};
      _lastCategories = List<String>.from(categories);
    }
  }

  @override
  void didUpdateWidget(covariant CategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initItemKeys();
    if (widget.enableAutoScroll &&
        (oldWidget.selectedCategory != widget.selectedCategory ||
            oldWidget.availableCategories != widget.availableCategories)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initItemKeys();
    if (widget.enableAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    final categories = _currentCategories;
    final selected = widget.selectedCategory ?? 'Tất cả';
    final index = categories.indexOf(selected);

    if (_scrollController == null || !_scrollController!.hasClients) return;

    // Nếu không tìm thấy (thường là 'Tất cả'), hoặc chọn 'Tất cả', cuộn về đầu
    if (index < 0 || selected == 'Tất cả') {
      _scrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Lấy key của item được chọn
    final key = _itemKeys[selected];
    if (key == null) return;
    final contextItem = key.currentContext;
    if (contextItem == null) return;

    // Lấy RenderBox của item và của ListView
    final box = contextItem.findRenderObject() as RenderBox?;
    final listBox = context.findRenderObject() as RenderBox?;
    if (box == null || listBox == null) return;

    final itemOffset = box.localToGlobal(Offset.zero, ancestor: listBox).dx;
    final itemWidth = box.size.width;
    final listWidth = listBox.size.width;

    // Tính toán offset để item nằm giữa
    final targetOffset =
        _scrollController!.offset + itemOffset - (listWidth - itemWidth) / 2;

    _scrollController!.animateTo(
      targetOffset.clamp(0.0, _scrollController!.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.brightness == Brightness.light
            ? Colors.grey.shade200
            : Colors.grey.shade800;

    final categories = _currentCategories;
    final getCategoryIcon =
        widget.getCategoryIcon ?? CategoryMappingService.getCategoryIcon;
    final getCategoryColors =
        widget.getCategoryColors ?? CategoryMappingService.getCategoryColors;

    _initItemKeys();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              widget.selectedCategory == category ||
              (widget.selectedCategory == null && category == 'Tất cả');
          return Container(
            key: _itemKeys[category],
            child: CategoryItem(
              label: CategoryMappingService.toVietnamese(category),
              isSelected: isSelected,
              onTap: () {
                if (isSelected && category != 'Tất cả') {
                  widget.onCategorySelected('Tất cả');
                } else {
                  widget.onCategorySelected(category);
                }
              },
              icon: getCategoryIcon(category),
              colors: getCategoryColors(category),
            ),
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
  final IconData icon;
  final List<Color> colors;

  const CategoryItem({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final Color iconColor =
        isSelected
            ? (colors.isNotEmpty ? colors[0] : primaryColor)
            : theme.iconTheme.color ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isSelected
                      ? (colors.isNotEmpty ? colors[0] : primaryColor)
                      : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? (colors.isNotEmpty ? colors[0] : primaryColor)
                        : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

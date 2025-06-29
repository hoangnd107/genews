import 'package:flutter/material.dart';
import 'package:genews/app/themes/colors.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int itemsPerPage;
  final EdgeInsetsGeometry? padding;
  final String emptyMessage;
  final Widget? header;
  final ScrollController? scrollController;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemsPerPage = 5,
    this.padding,
    this.emptyMessage = 'Không có dữ liệu',
    this.header,
    this.scrollController,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  int _currentPage = 0;
  late ScrollController _scrollController;
  final ScrollController _pageNumberController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _pageNumberController.dispose();
    super.dispose();
  }

  int get _totalPages => (widget.items.length / widget.itemsPerPage).ceil();

  List<T> get _currentPageItems {
    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(
      0,
      widget.items.length,
    );
    return widget.items.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    final newPage = page.clamp(0, _totalPages - 1);
    if (newPage == _currentPage) return;

    setState(() {
      _currentPage = newPage;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_pageNumberController.hasClients) {
      final targetOffset =
          (newPage * 48.0) -
          (_pageNumberController.position.viewportDimension / 2) +
          24.0;
      _pageNumberController.animateTo(
        targetOffset.clamp(0.0, _pageNumberController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.header != null) widget.header!,
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: widget.padding,
            itemCount: _currentPageItems.length,
            itemBuilder: (context, index) {
              final item = _currentPageItems[index];
              return widget.itemBuilder(context, item, index);
            },
          ),
        ),
        if (_totalPages > 1) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryColor;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Trang ${_currentPage + 1} / $_totalPages',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                // SỬA ĐỔI: Luôn sử dụng primaryColor từ theme sáng
                color: primaryColor,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Nút "Trước"
              _buildPaginationButton(
                icon: Icons.arrow_back_ios_new,
                isEnabled: _currentPage > 0,
                onPressed: () => _goToPage(_currentPage - 1),
              ),
              // 2. Tăng khoảng cách
              const SizedBox(width: 12),
              // Danh sách số trang có thể cuộn
              Expanded(
                child: SingleChildScrollView(
                  controller: _pageNumberController,
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildPageNumbers()),
                ),
              ),
              // 2. Tăng khoảng cách
              const SizedBox(width: 12),
              // Nút "Sau"
              _buildPaginationButton(
                icon: Icons.arrow_forward_ios,
                isEnabled: _currentPage < _totalPages - 1,
                onPressed: () => _goToPage(_currentPage + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
                    : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color:
                isEnabled
                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                    : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
            size: 16,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];

    if (_totalPages <= 7) {
      for (int i = 0; i < _totalPages; i++) {
        pageNumbers.add(_buildPageNumber(i));
      }
    } else {
      if (_currentPage <= 3) {
        for (int i = 0; i < 5; i++) {
          pageNumbers.add(_buildPageNumber(i));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(_buildPageNumber(_totalPages - 1));
      } else if (_currentPage >= _totalPages - 4) {
        pageNumbers.add(_buildPageNumber(0));
        pageNumbers.add(_buildEllipsis());
        for (int i = _totalPages - 5; i < _totalPages; i++) {
          pageNumbers.add(_buildPageNumber(i));
        }
      } else {
        pageNumbers.add(_buildPageNumber(0));
        pageNumbers.add(_buildEllipsis());
        for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
          pageNumbers.add(_buildPageNumber(i));
        }
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(_buildPageNumber(_totalPages - 1));
      }
    }

    return pageNumbers;
  }

  // SỬA ĐỔI: Tùy chỉnh màu sắc số trang active theo yêu cầu
  Widget _buildPageNumber(int pageIndex) {
    final isActive = pageIndex == _currentPage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _goToPage(pageIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          // SỬA ĐỔI: Sử dụng gradient màu xanh cho trang active
          gradient: isActive
              ? LinearGradient(
                  colors: [Colors.blue, Colors.blue.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            // SỬA ĐỔI: Sử dụng màu xanh cho viền khi active
            color: isActive ? Colors.blue : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '${pageIndex + 1}',
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black54),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // SỬA ĐỔI: Tùy chỉnh màu sắc dấu "..." cho dark mode
  Widget _buildEllipsis() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

class PaginationInfo extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  const PaginationInfo({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = currentPage * itemsPerPage + 1;
    final endItem = ((currentPage + 1) * itemsPerPage).clamp(0, totalItems);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        'Hiển thị $startItem-$endItem trong tổng số $totalItems mục',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }
}

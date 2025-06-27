import 'package:flutter/material.dart';

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
    this.itemsPerPage = 10,
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
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });

    // Scroll to top when changing page
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          // Pagination info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trang ${_currentPage + 1} / $_totalPages',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              _buildPaginationButton(
                icon: Icons.chevron_left,
                label: 'Trước',
                isEnabled: _currentPage > 0,
                onPressed:
                    _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
              ),

              const SizedBox(width: 16),

              // Page numbers
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageNumbers(),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Next button
              _buildPaginationButton(
                icon: Icons.chevron_right,
                label: 'Sau',
                isEnabled: _currentPage < _totalPages - 1,
                onPressed:
                    _currentPage < _totalPages - 1
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                isIconRight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback? onPressed,
    bool isIconRight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient:
                isEnabled
                    ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isEnabled ? null : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isEnabled
                    ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
                isIconRight
                    ? [
                      Text(
                        label,
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        color: isEnabled ? Colors.white : Colors.grey,
                        size: 18,
                      ),
                    ]
                    : [
                      Icon(
                        icon,
                        color: isEnabled ? Colors.white : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: isEnabled ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];

    if (_totalPages <= 7) {
      // Show all pages if total pages <= 7
      for (int i = 0; i < _totalPages; i++) {
        pageNumbers.add(_buildPageNumber(i));
        if (i < _totalPages - 1) {
          pageNumbers.add(const SizedBox(width: 8));
        }
      }
    } else {
      // Smart pagination for many pages
      if (_currentPage <= 3) {
        // Show first 5 pages + ellipsis + last page
        for (int i = 0; i < 5; i++) {
          pageNumbers.add(_buildPageNumber(i));
          if (i < 4) pageNumbers.add(const SizedBox(width: 8));
        }
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildPageNumber(_totalPages - 1));
      } else if (_currentPage >= _totalPages - 4) {
        // Show first page + ellipsis + last 5 pages
        pageNumbers.add(_buildPageNumber(0));
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 8));
        for (int i = _totalPages - 5; i < _totalPages; i++) {
          pageNumbers.add(_buildPageNumber(i));
          if (i < _totalPages - 1) pageNumbers.add(const SizedBox(width: 8));
        }
      } else {
        // Show first page + ellipsis + current ±2 + ellipsis + last page
        pageNumbers.add(_buildPageNumber(0));
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 8));

        for (int i = _currentPage - 2; i <= _currentPage + 2; i++) {
          pageNumbers.add(_buildPageNumber(i));
          if (i < _currentPage + 2) pageNumbers.add(const SizedBox(width: 8));
        }

        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildEllipsis());
        pageNumbers.add(const SizedBox(width: 8));
        pageNumbers.add(_buildPageNumber(_totalPages - 1));
      }
    }

    return pageNumbers;
  }

  Widget _buildPageNumber(int pageIndex) {
    final isActive = pageIndex == _currentPage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _goToPage(pageIndex),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient:
                isActive
                    ? LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Text(
              '${pageIndex + 1}',
              style: TextStyle(
                color:
                    isActive
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: const Center(
        child: Text(
          '...',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
            fontSize: 16,
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

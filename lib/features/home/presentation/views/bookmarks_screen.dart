// import 'package:flutter/material.dart';
// import 'package:genews/features/home/data/models/news_data_model.dart';
// import 'package:genews/features/home/data/services/bookmarks_service.dart';
// import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
// import 'package:genews/features/home/presentation/widgets/news_card.dart';
// import 'package:genews/features/shared/widgets/search_bar_widget.dart';
//
// class BookmarksScreen extends StatefulWidget {
//   const BookmarksScreen({super.key});
//
//   @override
//   State<BookmarksScreen> createState() => _BookmarksScreenState();
// }
//
// class _BookmarksScreenState extends State<BookmarksScreen> {
//   final BookmarksService _bookmarksService = BookmarksService();
//   List<Result> _bookmarkedArticles = [];
//   bool _isLoading = true;
//   bool _isSearchActive = false;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadBookmarks();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadBookmarks() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final bookmarks = await _bookmarksService.getSavedArticles();
//       setState(() {
//         _bookmarkedArticles = bookmarks;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _bookmarkedArticles = [];
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _removeBookmark(Result article) async {
//     await _bookmarksService.removeArticle(article);
//     _loadBookmarks();
//   }
//
//   void _toggleSearch() {
//     setState(() {
//       _isSearchActive = !_isSearchActive;
//       if (!_isSearchActive) {
//         _searchController.clear();
//         _searchQuery = '';
//       }
//     });
//   }
//
//   void _onSearchChanged(String query) {
//     setState(() {
//       _searchQuery = query;
//     });
//   }
//
//   void _clearSearch() {
//     setState(() {
//       _searchController.clear();
//       _searchQuery = '';
//     });
//   }
//
//   List<Result> _getFilteredBookmarks() {
//     if (_searchQuery.isEmpty) {
//       return _bookmarkedArticles;
//     }
//
//     final query = _searchQuery.toLowerCase();
//     return _bookmarkedArticles.where((article) {
//       final titleMatch = article.title?.toLowerCase().contains(query) ?? false;
//       final descMatch = article.description?.toLowerCase().contains(query) ?? false;
//       final sourceMatch = article.sourceName?.toLowerCase().contains(query) ?? false;
//
//       return titleMatch || descMatch || sourceMatch;
//     }).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Tin đã lưu'),
//         actions: [
//           IconButton(
//             icon: Icon(_isSearchActive ? Icons.search_off : Icons.search),
//             onPressed: _toggleSearch,
//           ),
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadBookmarks,
//             tooltip: 'Làm mới danh sách',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_isSearchActive)
//             NewsSearchBar(
//               controller: _searchController,
//               onChanged: _onSearchChanged,
//               onClear: _clearSearch,
//               hintText: 'Tìm kiếm trong tin đã lưu...',
//             ),
//
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _buildBookmarksList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBookmarksList() {
//     final filteredBookmarks = _getFilteredBookmarks();
//
//     if (filteredBookmarks.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
//             SizedBox(height: 10),
//             Text(
//               _searchQuery.isNotEmpty
//                   ? "Không tìm thấy tin phù hợp với tìm kiếm"
//                   : "Bạn chưa lưu tin tức nào",
//               style: TextStyle(fontSize: 18),
//             ),
//             if (_bookmarkedArticles.isEmpty && _searchQuery.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 10),
//                 child: Text(
//                   "Lưu tin tức để đọc sau bằng cách nhấn vào biểu tượng bookmark",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ),
//           ],
//         ),
//       );
//     }
//
//     return Padding(
//       padding: const EdgeInsets.all(10),
//       child: ListView.builder(
//         itemCount: filteredBookmarks.length,
//         itemBuilder: (context, index) {
//           final article = filteredBookmarks[index];
//           return NewsCard(
//             newsData: article,
//             onViewAnalysis: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NewsAnalysisScreen(newsData: article)),
//               );
//             },
//             onSave: () => _removeBookmark(article),
//             isSaved: true,
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/features/home/presentation/widgets/category_bar.dart';
import 'package:genews/features/shared/widgets/search_bar_widget.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarksService _bookmarksService = BookmarksService();
  List<Result> _bookmarkedArticles = [];
  bool _isLoading = true;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? selectedCategory;
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookmarks = await _bookmarksService.getSavedArticles();

      // Extract unique categories from bookmarked articles
      final categorySet = <String>{};
      for (var article in bookmarks) {
        if (article.category != null && article.category.toString().isNotEmpty) {
          categorySet.add(article.category.toString());
        }
      }

      setState(() {
        _bookmarkedArticles = bookmarks;
        _availableCategories = categorySet.toList()..sort();
        _isLoading = false;
        // Reset category selection when reloading
        selectedCategory = null;
      });
    } catch (e) {
      setState(() {
        _bookmarkedArticles = [];
        _availableCategories = [];
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (selectedCategory == category) {
        selectedCategory = null;
      } else {
        selectedCategory = category;
      }
    });
  }

  void _removeBookmark(Result article) async {
    await _bookmarksService.removeArticle(article);
    _loadBookmarks();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<Result> _getFilteredBookmarks() {
    // First filter by category
    List<Result> categoryFiltered = selectedCategory == null
        ? _bookmarkedArticles
        : _bookmarkedArticles.where((article) {
            String articleCategory = (article.category ?? '').toString().toLowerCase();
            return articleCategory.contains(selectedCategory!.toLowerCase());
          }).toList();

    // Then filter by search query
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    final query = _searchQuery.toLowerCase();
    return categoryFiltered.where((article) {
      final titleMatch = article.title?.toLowerCase().contains(query) ?? false;
      final descMatch = article.description?.toLowerCase().contains(query) ?? false;
      final sourceMatch = article.sourceName?.toLowerCase().contains(query) ?? false;

      return titleMatch || descMatch || sourceMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin đã lưu'),
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBookmarks,
            tooltip: 'Làm mới danh sách',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchActive)
            NewsSearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              hintText: 'Tìm kiếm trong tin đã lưu...',
            ),

          // Add CategoryBar with available categories from bookmarks
          if (_availableCategories.isNotEmpty)
            CategoryBar(
              availableCategories: _availableCategories, // Pass available categories from bookmarks
              selectedCategory: selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildBookmarksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    final filteredBookmarks = _getFilteredBookmarks();

    if (filteredBookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? "Không tìm thấy tin phù hợp với tìm kiếm"
                  : selectedCategory != null
                      ? "Không có tin tức nào trong chuyên mục này"
                      : "Bạn chưa lưu tin tức nào",
              style: TextStyle(fontSize: 18),
            ),
            if (_bookmarkedArticles.isEmpty && _searchQuery.isEmpty && selectedCategory == null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  "Lưu tin tức để đọc sau bằng cách nhấn vào biểu tượng bookmark",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListView.builder(
        itemCount: filteredBookmarks.length,
        itemBuilder: (context, index) {
          final article = filteredBookmarks[index];
          return NewsCard(
            newsData: article,
            onViewAnalysis: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewsAnalysisScreen(newsData: article)),
              );
            },
            onSave: () => _removeBookmark(article),
            isSaved: true,
          );
        },
      ),
    );
  }
}
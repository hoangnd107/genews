import 'dart:convert';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksService {
  static const String _bookmarksKey = 'saved_bookmarks';

  Future<List<Result>> getSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];

    return savedArticlesJson
        .map((json) => Result.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<bool> toggleSave(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    final articleJson = jsonEncode(article.toJson());

    // Check if article is already saved
    if (savedArticlesJson.contains(articleJson)) {
      // Remove it
      savedArticlesJson.remove(articleJson);
      await prefs.setStringList(_bookmarksKey, savedArticlesJson);
      return false; // Now it's not saved
    } else {
      // Save it at the top
      savedArticlesJson.insert(0, articleJson);
      await prefs.setStringList(_bookmarksKey, savedArticlesJson);
      return true; // Now it's saved
    }
  }

  // Add a method to check if article is saved
  Future<bool> isArticleSaved(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    final articleJson = jsonEncode(article.toJson());

    return savedArticlesJson.contains(articleJson);
  }

  Future<bool> saveArticle(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];

    // Check if article is already saved
    final articleJson = jsonEncode(article.toJson());
    if (savedArticlesJson.contains(articleJson)) {
      return false; // Already saved
    }

    savedArticlesJson.insert(0, articleJson);
    await prefs.setStringList(_bookmarksKey, savedArticlesJson);
    return true;
  }

  Future<bool> removeArticle(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];

    final articleJson = jsonEncode(article.toJson());
    if (!savedArticlesJson.contains(articleJson)) {
      return false; // Article wasn't saved
    }

    savedArticlesJson.remove(articleJson);
    await prefs.setStringList(_bookmarksKey, savedArticlesJson);
    return true;
  }
}

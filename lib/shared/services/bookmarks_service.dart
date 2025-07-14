import 'dart:convert';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksService {
  static const String _bookmarksKey = 'saved_bookmarks';

  Future<List<Result>> getSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    if (savedArticlesJson.isEmpty) return [];
    return savedArticlesJson
        .where((json) => json.isNotEmpty)
        .map((json) {
          try {
            return Result.fromJson(jsonDecode(json));
          } catch (e) {
            return null;
          }
        })
        .whereType<Result>()
        .toList();
  }

  Future<bool> toggleSave(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    final articleId = article.articleId ?? article.link ?? '';
    final filteredArticles =
        savedArticlesJson.where((json) {
          try {
            if (json.isEmpty) return false;
            final a = Result.fromJson(jsonDecode(json));
            return (a.articleId ?? a.link ?? '') != articleId ||
                articleId.isEmpty;
          } catch (e) {
            return false;
          }
        }).toList();
    final alreadySaved = filteredArticles.length != savedArticlesJson.length;
    if (alreadySaved) {
      await prefs.setStringList(_bookmarksKey, filteredArticles);
      return false;
    } else {
      filteredArticles.insert(0, jsonEncode(article.toJson()));
      await prefs.setStringList(_bookmarksKey, filteredArticles);
      return true;
    }
  }

  Future<bool> isArticleSaved(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    final articleId = article.articleId ?? article.link ?? '';
    return savedArticlesJson.any((json) {
      try {
        if (json.isEmpty) return false;
        final a = Result.fromJson(jsonDecode(json));
        return (a.articleId ?? a.link ?? '') == articleId &&
            articleId.isNotEmpty;
      } catch (e) {
        return false;
      }
    });
  }

  Future<bool> saveArticle(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    final articleId = article.articleId ?? article.link ?? '';
    final alreadySaved = savedArticlesJson.any((json) {
      try {
        if (json.isEmpty) return false;
        final a = Result.fromJson(jsonDecode(json));
        return (a.articleId ?? a.link ?? '') == articleId &&
            articleId.isNotEmpty;
      } catch (e) {
        return false;
      }
    });
    if (alreadySaved) return false;
    savedArticlesJson.insert(0, jsonEncode(article.toJson()));
    await prefs.setStringList(_bookmarksKey, savedArticlesJson);
    return true;
  }

  Future<bool> removeArticle(Result article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticlesJson = prefs.getStringList(_bookmarksKey) ?? [];
    final articleId = article.articleId ?? article.link ?? '';
    final filteredArticles =
        savedArticlesJson.where((json) {
          try {
            if (json.isEmpty) return false;
            final a = Result.fromJson(jsonDecode(json));
            return (a.articleId ?? a.link ?? '') != articleId ||
                articleId.isEmpty;
          } catch (e) {
            return false;
          }
        }).toList();
    if (filteredArticles.length == savedArticlesJson.length) return false;
    await prefs.setStringList(_bookmarksKey, filteredArticles);
    return true;
  }
}

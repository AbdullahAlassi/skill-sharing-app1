import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/skill_category.dart';

class SkillCategoryProvider with ChangeNotifier {
  final String baseUrl = 'http://10.0.2.2:5000';
  List<SkillCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<SkillCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/skill-categories'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _categories = data.map((json) => SkillCategory.fromJson(json)).toList();
        print(
            'Fetched Categories IDs: ${_categories.map((cat) => cat.id).toList()}');
        _error = null;
      } else {
        _error = 'Failed to load categories';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      print('Error fetching categories: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCategory(SkillCategory category) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/skill-categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 201) {
        final newCategory = SkillCategory.fromJson(json.decode(response.body));
        _categories.add(newCategory);
        notifyListeners();
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updateCategory(String id, SkillCategory category) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/skill-categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedCategory =
            SkillCategory.fromJson(json.decode(response.body));
        final index = _categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          _categories[index] = updatedCategory;
          notifyListeners();
        }
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/skill-categories/$id'),
      );

      if (response.statusCode == 200) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
      } else {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      notifyListeners();
    }
  }
}

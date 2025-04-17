import 'package:flutter/material.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/token_storage.dart';
import '../../config/app_config.dart';

class FavoriteCategoriesScreen extends StatefulWidget {
  const FavoriteCategoriesScreen({super.key});

  @override
  State<FavoriteCategoriesScreen> createState() =>
      _FavoriteCategoriesScreenState();
}

class _FavoriteCategoriesScreenState extends State<FavoriteCategoriesScreen> {
  final List<String> _selectedCategories = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skillService = SkillService();
      final response = await skillService.getCategories();

      if (response.success && response.data != null) {
        setState(() {
          _categories = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load categories';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else if (_selectedCategories.length < 5) {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _savePreferences() async {
    if (_selectedCategories.length < 3) {
      setState(() {
        _errorMessage = 'Please select at least 3 categories';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication error. Please try logging in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'favoriteCategories': _selectedCategories,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to save preferences';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving preferences: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Interests'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'What are you interested in?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select 3-5 categories that interest you. We\'ll use these to recommend relevant skills.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Categories grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) => _toggleCategory(category),
                        backgroundColor: Colors.white,
                        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Selection count
                  Text(
                    'Selected: ${_selectedCategories.length}/5',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedCategories.length < 3
                              ? Colors.red
                              : Colors.green,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

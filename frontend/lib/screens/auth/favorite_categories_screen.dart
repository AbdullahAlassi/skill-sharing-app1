import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/screens/profile/edit_profile_screen.dart';
import 'package:skill_sharing_app/screens/profile/profile_screen.dart';
import '../../models/skill_category.dart';
import '../../providers/user_provider.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import '../../widget/custome_button.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/token_storage.dart';
import '../../config/app_config.dart';

class FavoriteCategoriesScreen extends StatefulWidget {
  const FavoriteCategoriesScreen({Key? key}) : super(key: key);

  @override
  _FavoriteCategoriesScreenState createState() =>
      _FavoriteCategoriesScreenState();
}

class _FavoriteCategoriesScreenState extends State<FavoriteCategoriesScreen> {
  final _skillService = SkillService();
  List<SkillCategory> _categories = [];
  List<String> _selectedCategories = [];
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
      final categories = await _skillService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories.data ?? [];
          // Initialize selected categories from user's preferences
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          if (userProvider.user?.favoriteCategories != null) {
            _selectedCategories = userProvider.user!.favoriteCategories!;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateFavoriteCategories(_selectedCategories);

      if (mounted) {
        if (userProvider.error != null) {
          setState(() {
            _errorMessage = userProvider.error;
            _isLoading = false;
          });
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Categories'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          _loadCategories();
                        },
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Select your favorite categories to get personalized recommendations',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return CheckboxListTile(
                              title: Text(category.name),
                              value:
                                  _selectedCategories.contains(category.name),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCategories.add(category.name);
                                  } else {
                                    _selectedCategories.remove(category.name);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Save Preferences',
                        onPressed: _selectedCategories.isEmpty
                            ? null
                            : () {
                                _saveCategories();
                              },
                      ),
                    ],
                  ),
                ),
    );
  }
}

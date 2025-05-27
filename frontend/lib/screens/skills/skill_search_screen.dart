import 'package:flutter/material.dart';
import 'package:skill_sharing_app/models/skill_model.dart';
import 'package:skill_sharing_app/models/skill_category.dart';
import 'package:skill_sharing_app/screens/skills/skill_detail_screen.dart';
import 'package:skill_sharing_app/services/skill_service.dart';
import 'package:skill_sharing_app/theme/app_theme.dart';
import 'package:skill_sharing_app/widget/skill_card.dart';
import 'package:skill_sharing_app/widget/section_header.dart';
import 'package:skill_sharing_app/utils/api_response.dart';
import 'dart:async';

class SkillSearchScreen extends StatefulWidget {
  const SkillSearchScreen({Key? key}) : super(key: key);

  @override
  _SkillSearchScreenState createState() => _SkillSearchScreenState();
}

class _SkillSearchScreenState extends State<SkillSearchScreen> {
  final _searchController = TextEditingController();
  final _skillService = SkillService();
  Timer? _debounce;
  List<Skill> _skills = [];
  List<SkillCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _skillService.getCategories();
      if (response.success && response.data != null) {
        setState(() {
          _categories = response.data!;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadSkills() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _skillService.searchSkills(
        query: _searchController.text,
        category: _selectedCategory,
        level: _selectedLevel,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _skills = response.data!;
          } else {
            _errorMessage = response.error ?? 'Failed to load skills';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadSkills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Skills'),
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search skills...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),

                // Filters
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All Categories',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ..._categories.map(
                            (category) => DropdownMenuItem(
                              value: category.name,
                              child: Text(
                                category.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                          _loadSkills();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Level filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        decoration: InputDecoration(
                          labelText: 'Level',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All Levels',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...['Beginner', 'Intermediate', 'Advanced'].map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(
                                level,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLevel = value;
                          });
                          _loadSkills();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results section
          Expanded(
            child: _isLoading
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
                            ElevatedButton(
                              onPressed: _loadSkills,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _skills.isEmpty
                        ? const Center(
                            child: Text('No skills found'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _skills.length,
                            itemBuilder: (context, index) {
                              final skill = _skills[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SkillCard(
                                  skill: skill,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              SkillDetailScreen(skill: skill)),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

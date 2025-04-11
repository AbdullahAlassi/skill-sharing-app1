import 'package:flutter/material.dart';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/custome_text.dart';

class CreateSkillScreen extends StatefulWidget {
  const CreateSkillScreen({super.key});

  @override
  _CreateSkillScreenState createState() => _CreateSkillScreenState();
}

class _CreateSkillScreenState extends State<CreateSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  List<Skill> _allSkills = [];
  final List<String> _selectedRelatedSkills = [];

  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  bool _isSkillsLoading = true;
  String? _errorMessage;

  // Create a new instance of SkillService each time
  late final SkillService _skillService;

  @override
  void initState() {
    super.initState();
    // Initialize a fresh instance of SkillService
    _skillService = SkillService();
    print("Initializing CreateSkillScreen with fresh SkillService");

    // Reset state and load fresh data
    _selectedCategory = null;
    _categories = [];
    _loadCategoriesAndSkills();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Combined method to load both categories and skills
  Future<void> _loadCategoriesAndSkills() async {
    setState(() {
      _isCategoriesLoading = true;
      _isSkillsLoading = true;
    });

    // Load categories
    await _loadCategories();

    // Load skills
    await _loadSkills();
  }

  Future<void> _loadCategories() async {
    print("Loading categories...");
    try {
      final response = await _skillService.getCategories();
      print(
        "Categories API response: ${response.success}, data length: ${response.data?.length ?? 0}",
      );

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        setState(() {
          // Store all categories
          _categories = List<String>.from(response.data!);
          print("Loaded ${_categories.length} categories: $_categories");

          // Set default category only if none is selected
          if (_selectedCategory == null && _categories.isNotEmpty) {
            _selectedCategory = _categories.first;
            print("Set default category to: $_selectedCategory");
          }
          _isCategoriesLoading = false;
        });
      } else {
        print("No categories from API, using defaults");
        // If no categories exist yet or the list is empty, provide default ones
        setState(() {
          _categories = [
            'Programming',
            'Design',
            'Marketing',
            'Art',
            'Music',
            'Language',
            'Other',
          ];
          _selectedCategory ??= 'Programming';
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      print("Error loading categories: $e");
      // Use default categories if API fails
      setState(() {
        _categories = [
          'Programming',
          'Design',
          'Marketing',
          'Art',
          'Music',
          'Language',
          'Other',
        ];
        _selectedCategory ??= 'Programming';
        _isCategoriesLoading = false;
      });
    }
  }

  Future<void> _loadSkills() async {
    try {
      final response = await _skillService.getSkills();
      if (response.success && response.data != null) {
        setState(() {
          _allSkills = response.data!;
          _isSkillsLoading = false;
        });
      } else {
        setState(() {
          _allSkills = [];
          _isSkillsLoading = false;
        });
      }
    } catch (e) {
      print("Error loading skills: $e");
      setState(() {
        _allSkills = [];
        _isSkillsLoading = false;
      });
    }
  }

  Future<void> _createSkill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convert selected skill names to IDs
      List<String> relatedSkillIds = [];
      for (String skillName in _selectedRelatedSkills) {
        final skill = _allSkills.firstWhere(
          (s) => s.name == skillName,
          orElse:
              () => Skill(
                id: '',
                name: '',
                category: '',
                description: '',
                createdAt: DateTime.now(),
              ),
        );
        if (skill.id.isNotEmpty) {
          relatedSkillIds.add(skill.id);
        }
      }

      final response = await _skillService.createSkill(
        _nameController.text.trim(),
        _selectedCategory!,
        _descriptionController.text.trim(),
        relatedSkillIds,
      );

      if (response.success) {
        print("Skill created successfully: ${response.data?.name}");

        // Make sure we're returning with a true result to trigger the reload
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to create skill';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Skill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Your Knowledge',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new skill to share with the community',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Skill name field
              CustomTextField(
                label: 'Skill Name',
                hint: 'Enter the name of the skill',
                controller: _nameController,
                prefixIcon: const Icon(Icons.school_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a skill name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              _isCategoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Category",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            hint: Text("Select a category"),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            items:
                                _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                  print(
                                    "Selected category: $_selectedCategory",
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (_selectedCategory == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Please select a category',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
              const SizedBox(height: 16),

              // Description field
              CustomTextField(
                label: 'Description',
                hint: 'Describe what this skill is about',
                controller: _descriptionController,
                prefixIcon: const Icon(Icons.description_outlined),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Related skills
              Text(
                'Related Skills (Optional)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Select skills that are related to this one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),

              _isSkillsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _allSkills.isEmpty
                  ? const Text('No skills available to relate')
                  : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _allSkills.map((skill) {
                          final isSelected = _selectedRelatedSkills.contains(
                            skill.name,
                          );
                          return FilterChip(
                            label: Text(skill.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedRelatedSkills.add(skill.name);
                                } else {
                                  _selectedRelatedSkills.remove(skill.name);
                                }
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            checkmarkColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimaryColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                  ),
              const SizedBox(height: 32),

              // Create button
              CustomButton(
                text: 'Create Skill',
                onPressed: _createSkill,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Cancel button
              CustomButton(
                text: 'Cancel',
                onPressed: () {
                  Navigator.pop(context);
                },
                type: ButtonType.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

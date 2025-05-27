import 'package:flutter/material.dart';
import 'package:skill_sharing_app/widget/custome_button.dart';
import 'package:skill_sharing_app/widget/custome_text.dart';
import '../../models/skill_model.dart';
import '../../models/skill_proficiency_model.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/skill_category_provider.dart';
import '../../models/skill_category.dart';

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
  List<Skill> _allSkills = [];
  final List<String> _selectedRelatedSkills = [];
  ProficiencyLevel _selectedProficiency = ProficiencyLevel.beginner;
  String _selectedDifficultyLevel = 'Beginner';

  bool _isLoading = false;
  bool _isSkillsLoading = true;
  String? _errorMessage;

  // Create a new instance of SkillService each time
  late final SkillService _skillService;

  final List<String> _difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize a fresh instance of SkillService
    _skillService = SkillService();
    print("Initializing CreateSkillScreen with fresh SkillService");

    // Reset state and load fresh data
    _selectedCategory = null;
    _loadSkills();

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillCategoryProvider>(context, listen: false)
          .fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    try {
      final response = await _skillService.getSkills();
      if (response.success && response.data != null) {
        setState(() {
          _allSkills = response.data!;
        });
      }
    } catch (e) {
      print('Error loading skills: $e');
    }
  }

  // Add a new method to load skills by category
  Future<void> _loadSkillsByCategory(String categoryName) async {
    setState(() {
      _isSkillsLoading = true;
      _allSkills = []; // Clear previous skills
    });

    try {
      // Use getSkillsByCategory instead of getMyCreatedSkills
      final response = await _skillService.getSkillsByCategory(categoryName);
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
      print("Error loading skills by category: $e");
      setState(() {
        _allSkills = [];
        _isSkillsLoading = false;
      });
    }
  }

  Future<void> _createSkill() async {
    if (_formKey.currentState!.validate()) {
      // Ensure a category is selected
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Get the selected category object from the provider
        final selectedCategoryObject =
            Provider.of<SkillCategoryProvider>(context, listen: false)
                .categories
                .firstWhere((cat) => cat.id == _selectedCategory);

        final response = await _skillService.createSkill(
          _nameController.text,
          selectedCategoryObject.id, // Pass the category ID
          _descriptionController.text,
          _selectedRelatedSkills, // This is now a list of skill IDs
          'Beginner', // Default proficiency
          _selectedDifficultyLevel,
        );

        if (response.success && response.data != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skill created successfully')),
            );
            Navigator.pop(context, response.data);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(response.error ?? 'Failed to create skill')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
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
                child: Consumer<SkillCategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    if (categoryProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (categoryProvider.error != null) {
                      return Text('Error: ${categoryProvider.error}');
                    }

                    final categories = categoryProvider.categories;
                    if (categories.isEmpty) {
                      return const Text('No categories available');
                    }

                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        hint: const Text("Select a category"),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                              // Load skills based on the selected category
                              _loadSkillsByCategory(value);
                            });
                          }
                        },
                      ),
                    );
                  },
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
              const SizedBox(height: 16),

              // Proficiency Level Selection
              Text(
                "Proficiency Level",
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
                  child: DropdownButton<ProficiencyLevel>(
                    value: _selectedProficiency,
                    isExpanded: true,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    items: ProficiencyLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(
                          level.toString().split('.').last.toUpperCase(),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedProficiency = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add difficulty level dropdown after proficiency
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDifficultyLevel,
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                ),
                items: _difficultyLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDifficultyLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

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
                      : _buildRelatedSkillsSection(),
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

  Widget _buildRelatedSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Skills',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allSkills.map((skill) {
            final isSelected = _selectedRelatedSkills.contains(skill.id);
            return FilterChip(
              label: Text(skill.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRelatedSkills.add(skill.id);
                  } else {
                    _selectedRelatedSkills.remove(skill.id);
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor.withOpacity(0.1),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/skill_model.dart';
import '../../models/skill_proficiency_model.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/custome_text.dart';

class EditSkillScreen extends StatefulWidget {
  final Skill skill;

  const EditSkillScreen({super.key, required this.skill});

  @override
  _EditSkillScreenState createState() => _EditSkillScreenState();
}

class _EditSkillScreenState extends State<EditSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  List<String> _categories = [];
  List<Skill> _allSkills = [];
  final List<String> _selectedRelatedSkills = [];
  ProficiencyLevel _selectedProficiency = ProficiencyLevel.beginner;

  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  bool _isSkillsLoading = true;
  String? _errorMessage;

  late final SkillService _skillService;

  @override
  void initState() {
    super.initState();
    _skillService = SkillService();
    _initializeForm();
    _loadCategoriesAndSkills();
  }

  void _initializeForm() {
    _nameController.text = widget.skill.name;
    _descriptionController.text = widget.skill.description;
    _selectedCategory = widget.skill.category;
    _selectedRelatedSkills.addAll(widget.skill.relatedSkills);
    if (widget.skill.proficiency != null) {
      _selectedProficiency = ProficiencyLevel.values.firstWhere(
        (level) =>
            level.toString().split('.').last.toLowerCase() ==
            widget.skill.proficiency!.toLowerCase(),
        orElse: () => ProficiencyLevel.beginner,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndSkills() async {
    setState(() {
      _isCategoriesLoading = true;
      _isSkillsLoading = true;
    });

    await _loadCategories();
    await _loadSkills();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _skillService.getCategories();
      if (response.success && response.data != null) {
        setState(() {
          _categories = response.data!;
          _isCategoriesLoading = false;
        });
      } else {
        setState(() {
          _categories = SkillService.defaultCategories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _categories = SkillService.defaultCategories;
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
      setState(() {
        _allSkills = [];
        _isSkillsLoading = false;
      });
    }
  }

  Future<void> _updateSkill() async {
    if (!_formKey.currentState!.validate()) return;

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
      // Convert proficiency level to proper case (first letter uppercase)
      final proficiencyLevel = _selectedProficiency.toString().split('.').last;
      final formattedProficiency = proficiencyLevel[0].toUpperCase() +
          proficiencyLevel.substring(1).toLowerCase();

      final response = await _skillService.updateSkill(
        widget.skill.id,
        _nameController.text,
        _selectedCategory!,
        _descriptionController.text,
        _selectedRelatedSkills,
        formattedProficiency,
      );

      if (response.success && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skill updated successfully')),
          );
          Navigator.pop(context, response.data);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to update skill')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Skill')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Skill Details',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Update the skill information',
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
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
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
                          children: _allSkills.map((skill) {
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
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimaryColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 32),

              // Update button
              CustomButton(
                text: 'Update Skill',
                onPressed: _updateSkill,
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

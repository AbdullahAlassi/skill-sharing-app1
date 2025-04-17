import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/skill_proficiency_model.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class SkillProficiencyScreen extends StatefulWidget {
  final String skillId;
  final String skillName;

  const SkillProficiencyScreen({
    super.key,
    required this.skillId,
    required this.skillName,
  });

  @override
  State<SkillProficiencyScreen> createState() => _SkillProficiencyScreenState();
}

class _SkillProficiencyScreenState extends State<SkillProficiencyScreen> {
  ProficiencyLevel _selectedLevel = ProficiencyLevel.beginner;
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProficiency();
  }

  void _loadExistingProficiency() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final existingProficiency = user?.skillProficiencies?.firstWhere(
      (p) => p.skillId == widget.skillId,
      orElse: () => SkillProficiency(
        skillId: widget.skillId,
        level: ProficiencyLevel.beginner,
        startedLearning: DateTime.now(),
      ),
    );

    if (existingProficiency != null) {
      setState(() {
        _selectedLevel = existingProficiency.level;
        _tags.addAll(existingProficiency.tags);
      });
    }
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveProficiency() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final proficiency = SkillProficiency(
        skillId: widget.skillId,
        level: _selectedLevel,
        startedLearning: DateTime.now(),
        tags: _tags,
      );

      // TODO: Call API to save proficiency
      // await userProvider.updateSkillProficiency(proficiency);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving proficiency: $e')),
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
      appBar: AppBar(
        title: Text('${widget.skillName} Proficiency'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Proficiency Level Selection
                  Text(
                    'Select Your Proficiency Level',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: ProficiencyLevel.values.map((level) {
                      return ChoiceChip(
                        label: Text(
                          level.toString().split('.').last.toUpperCase(),
                        ),
                        selected: _selectedLevel == level,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedLevel = level;
                            });
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedLevel == level
                              ? AppTheme.primaryColor
                              : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Tags Section
                  Text(
                    'Add Tags',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Enter a tag',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTag,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                        deleteIconColor: Colors.red,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveProficiency,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Save Proficiency'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
}

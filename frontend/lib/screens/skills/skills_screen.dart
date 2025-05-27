import 'package:flutter/material.dart';
import 'package:skill_sharing_app/widget/skill_card.dart';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'skill_detail_screen.dart';
import 'create_skill_screen.dart';
import 'skill_search_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  List<Skill> _skills = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    print("Loading skills...");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final skillService = SkillService();
      final response = await skillService.getSkills();
      print(
        "Skills API response: ${response.success}, data length: ${response.data?.length ?? 0}",
      );

      if (response.success && response.data != null) {
        setState(() {
          _skills = response.data!;
          // Extract unique categories
          _categories = _skills
              .map((skill) => skill.categoryName)
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList();
          _isLoading = false;
        });
        print("Loaded ${_skills.length} skills");
      } else {
        setState(() {
          _skills = [];
          _categories = [];
          _errorMessage = response.error;
          _isLoading = false;
        });
        print("No skills loaded from API: ${response.error}");
      }
    } catch (e) {
      print("Error loading skills: $e");
      setState(() {
        _skills = [];
        _categories = [];
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Skill> get _filteredSkills {
    if (_selectedCategory == null) {
      return _skills;
    }
    return _skills
        .where((skill) => skill.categoryName == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SkillSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSkills,
              child: Column(
                children: [
                  // Error message if any
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Error loading skills: $_errorMessage',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categories filter
                  if (_categories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: const Text('All'),
                                selected: _selectedCategory == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor:
                                    AppTheme.primaryColor.withOpacity(0.1),
                                checkmarkColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == null
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimaryColor,
                                  fontWeight: _selectedCategory == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            ..._categories.map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory =
                                          selected ? category : null;
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor:
                                      AppTheme.primaryColor.withOpacity(0.1),
                                  checkmarkColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == category
                                        ? AppTheme.primaryColor
                                        : AppTheme.textPrimaryColor,
                                    fontWeight: _selectedCategory == category
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Skills grid
                  Expanded(
                    child: _filteredSkills.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedCategory != null
                                      ? 'No skills found in $_selectedCategory category'
                                      : 'No skills found',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateSkillScreen(),
                                      ),
                                    ).then((result) {
                                      if (result == true) {
                                        _loadSkills();
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create a Skill'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            itemCount: _filteredSkills.length,
                            itemBuilder: (context, index) {
                              final skill = _filteredSkills[index];
                              return SkillCard(
                                skill: skill,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SkillDetailScreen(
                                        skill: skill,
                                      ),
                                    ),
                                  ).then((_) => _loadSkills());
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSkillScreen()),
          ).then((result) {
            print("Returned from CreateSkillScreen with result: $result");
            // Reload skills if a new one was created
            if (result == true) {
              _loadSkills();
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

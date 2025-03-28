import 'package:flutter/material.dart';
import '../../models/skill_model.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/skill_card.dart';
import 'skill_detail_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({Key? key}) : super(key: key);

  @override
  _SkillsScreenState createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  bool _isLoading = true;
  List<Skill> _skills = [];
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual API calls
    setState(() {
      _skills = [
        Skill(
          id: '1',
          name: 'Flutter Development',
          category: 'Programming',
          description: 'Learn to build beautiful cross-platform apps',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '2',
          name: 'UI/UX Design',
          category: 'Design',
          description: 'Create stunning user interfaces and experiences',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '3',
          name: 'Digital Marketing',
          category: 'Marketing',
          description: 'Master the art of online marketing',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '4',
          name: 'Photography',
          category: 'Art',
          description: 'Capture beautiful moments with your camera',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '5',
          name: 'React Native',
          category: 'Programming',
          description: 'Build native mobile apps using JavaScript',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '6',
          name: 'Graphic Design',
          category: 'Design',
          description: 'Create visual content to communicate messages',
          createdAt: DateTime.now(),
        ),
      ];

      _categories = _skills.map((skill) => skill.category).toSet().toList();
      _isLoading = false;
    });
  }

  List<Skill> get _filteredSkills {
    if (_selectedCategory == null) {
      return _skills;
    }
    return _skills
        .where((skill) => skill.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search screen
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadSkills,
                child: Column(
                  children: [
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
                                  selectedColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  checkmarkColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color:
                                        _selectedCategory == null
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimaryColor,
                                    fontWeight:
                                        _selectedCategory == null
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
                                    selectedColor: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                    checkmarkColor: AppTheme.primaryColor,
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedCategory == category
                                              ? AppTheme.primaryColor
                                              : AppTheme.textPrimaryColor,
                                      fontWeight:
                                          _selectedCategory == category
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
                      child:
                          _filteredSkills.isEmpty
                              ? const Center(child: Text('No skills found'))
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
                                          builder:
                                              (context) => SkillDetailScreen(
                                                skill: skill,
                                              ),
                                        ),
                                      );
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
          // Navigate to add skill screen
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

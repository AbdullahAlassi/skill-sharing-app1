import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import '../../widget/custome_button.dart';
import '../../widget/skill_card.dart';
import '../../models/skill_model.dart';
import '../../providers/user_provider.dart';
import 'skill_detail_screen.dart';
import '../profile/profile_screen.dart';

class RecommendedSkillsScreen extends StatefulWidget {
  const RecommendedSkillsScreen({super.key});

  @override
  State<RecommendedSkillsScreen> createState() =>
      _RecommendedSkillsScreenState();
}

class _RecommendedSkillsScreenState extends State<RecommendedSkillsScreen> {
  final SkillService _skillService = SkillService();
  List<Skill> _recommendedSkills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendedSkills();
  }

  Future<void> _loadRecommendedSkills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      // If user is not loaded yet, wait for it
      if (user == null) {
        await userProvider.loadUser();
        final updatedUser = userProvider.user;
        if (updatedUser == null) {
          setState(() {
            _errorMessage = 'Please log in to view recommended skills';
            _isLoading = false;
          });
          return;
        }
      }

      // Check if user has selected favorite categories
      if (userProvider.user?.favoriteCategories == null ||
          userProvider.user!.favoriteCategories!.isEmpty) {
        setState(() {
          _errorMessage = 'Please select your favorite categories first';
          _isLoading = false;
        });
        return;
      }

      // Load recommended skills
      final response = await _skillService.getRecommendations();
      if (response.success && response.data != null) {
        // Filter skills by user's favorite categories
        final filteredSkills = response.data!.where((skill) {
          return userProvider.user!.favoriteCategories!
              .contains(skill.category);
        }).toList();

        setState(() {
          _recommendedSkills = filteredSkills;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to load recommended skills';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Skills'),
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
                      if (_errorMessage ==
                          'Please select your favorite categories first')
                        CustomButton(
                          text: 'Select Categories',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            ).then((_) => _loadRecommendedSkills());
                          },
                        )
                      else
                        CustomButton(
                          text: 'Retry',
                          onPressed: _loadRecommendedSkills,
                        ),
                    ],
                  ),
                )
              : _recommendedSkills.isEmpty
                  ? const Center(
                      child: Text('No recommended skills available'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecommendedSkills,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _recommendedSkills.length,
                        itemBuilder: (context, index) {
                          final skill = _recommendedSkills[index];
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
                              ).then((_) => _loadRecommendedSkills());
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

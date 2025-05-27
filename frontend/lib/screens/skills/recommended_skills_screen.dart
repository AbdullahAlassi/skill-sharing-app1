import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import '../../widget/custome_button.dart';
import '../../widget/skill_card.dart';
import '../../models/skill_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/skill_provider.dart';
import 'skill_detail_screen.dart';
import '../profile/profile_screen.dart';

class RecommendedSkillsScreen extends StatefulWidget {
  const RecommendedSkillsScreen({super.key});

  @override
  State<RecommendedSkillsScreen> createState() =>
      _RecommendedSkillsScreenState();
}

class _RecommendedSkillsScreenState extends State<RecommendedSkillsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendedSkills();
    });
  }

  Future<void> _loadRecommendedSkills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[RecommendedSkillsScreen] Loading recommended skills');

      // Get user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      // If user is not loaded yet, wait for it
      if (user == null) {
        debugPrint(
            '[RecommendedSkillsScreen] User not found, attempting to load');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await userProvider.loadUser();
        });
        final updatedUser = userProvider.user;
        if (updatedUser == null) {
          debugPrint('[RecommendedSkillsScreen] Failed to load user');
          setState(() {
            _errorMessage = 'Please log in to view recommended skills';
            _isLoading = false;
          });
          return;
        }
        debugPrint('[RecommendedSkillsScreen] User loaded successfully');
      }

      // Check if user has selected favorite categories
      if (userProvider.user?.favoriteCategories == null ||
          userProvider.user!.favoriteCategories!.isEmpty) {
        debugPrint('[RecommendedSkillsScreen] No favorite categories selected');
        setState(() {
          _errorMessage = 'Please select your favorite categories first';
          _isLoading = false;
        });
        return;
      }

      debugPrint(
          '[RecommendedSkillsScreen] Loading recommendations via SkillProvider');
      // Load recommended skills using SkillProvider
      final skillProvider = Provider.of<SkillProvider>(context, listen: false);
      await skillProvider.loadRecommendedSkills(context);

      debugPrint('[RecommendedSkillsScreen] Recommendations loaded');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[RecommendedSkillsScreen] Error loading recommendations: $e');
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
              : Consumer<SkillProvider>(
                  builder: (context, skillProvider, child) {
                    final recommendedSkills = skillProvider.recommendedSkills;
                    debugPrint(
                        '[RecommendedSkillsScreen] Building with ${recommendedSkills.length} skills');

                    if (recommendedSkills.isEmpty) {
                      debugPrint(
                          '[RecommendedSkillsScreen] No recommended skills available');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No recommended skills available',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Refresh',
                              onPressed: _loadRecommendedSkills,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
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
                        itemCount: recommendedSkills.length,
                        itemBuilder: (context, index) {
                          final skill = recommendedSkills[index];
                          debugPrint(
                              '[RecommendedSkillsScreen] Building skill card for: ${skill.name}');

                          return Column(
                            children: [
                              Expanded(
                                child: SkillCard(
                                  skill: skill,
                                  onTap: () {
                                    debugPrint(
                                        '[Analytics] User tapped recommended skill: ${skill.name}');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SkillDetailScreen(
                                          skill: skill,
                                        ),
                                      ),
                                    ).then((_) => _loadRecommendedSkills());
                                  },
                                ),
                              ),
                              if (skill.recommendationReason != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Tooltip(
                                    message: skill.recommendationReason!,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                      child: Text(
                                        skill.recommendationReason!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

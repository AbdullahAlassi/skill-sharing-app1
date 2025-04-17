import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resource_model.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../models/skill_proficiency_model.dart';
import '../../providers/user_provider.dart';
import '../../services/resource_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/section_header.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_skill_screen.dart';

class SkillDetailScreen extends StatefulWidget {
  final Skill skill;

  const SkillDetailScreen({super.key, required this.skill});

  @override
  _SkillDetailScreenState createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  List<Resource> _resources = [];
  bool _isLoading = false;
  bool _isUserSkill = false;
  bool _isAddingToProfile = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get resources for this skill
      final resourceService = ResourceService();
      final resourceResponse = await resourceService.getResourcesBySkill(
        widget.skill.id,
      );

      // Get current user
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      setState(() {
        if (resourceResponse.success && resourceResponse.data != null) {
          _resources = resourceResponse.data!;
        } else {
          _resources = [];
        }

        _user = user;
        // Check if this skill is in user's skills and get proficiency
        _isUserSkill = user?.skills.contains(widget.skill.id) ?? false;
        if (_isUserSkill) {
          final proficiency = user?.skillProficiencies?.firstWhere(
            (p) => p.skillId == widget.skill.id,
            orElse: () => SkillProficiency(
              skillId: widget.skill.id,
              level: ProficiencyLevel.beginner,
              startedLearning: DateTime.now(),
            ),
          );
          if (proficiency != null) {
            widget.skill.proficiency =
                proficiency.level.toString().split('.').last;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resources = [];
        _isUserSkill = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserSkill() async {
    setState(() {
      _isAddingToProfile = true;
    });

    try {
      final profileService = ProfileService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (_isUserSkill) {
        // Remove skill from user profile
        final response = await profileService.removeSkill(widget.skill.id);

        if (response.success) {
          // Reload user data to reflect changes
          await userProvider.loadUser();
          if (mounted) {
            setState(() {
              _isUserSkill = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skill removed successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(response.error ?? 'Failed to remove skill')),
            );
          }
        }
      } else {
        // Add skill to user profile
        final response = await profileService.addSkill(
          widget.skill.id,
          'Beginner', // Default proficiency
        );

        if (response.success) {
          // Reload user data to reflect changes
          await userProvider.loadUser();
          if (mounted) {
            setState(() {
              _isUserSkill = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skill added successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.error ?? 'Failed to add skill')),
            );
          }
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
          _isAddingToProfile = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.skill.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.skill.category,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skill name
                  Text(
                    widget.skill.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),

                  // Proficiency level
                  if (widget.skill.proficiency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Proficiency: ${widget.skill.proficiency!.toUpperCase()}',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Description section
                  const SectionHeader(title: 'Description'),
                  const SizedBox(height: 8),
                  Text(
                    widget.skill.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Resources section
                  const SectionHeader(title: 'Learning Resources'),
                  const SizedBox(height: 16),

                  if (_resources.isEmpty)
                    const Text('No resources available for this skill yet.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _resources.length,
                      itemBuilder: (context, index) {
                        final resource = _resources[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getResourceIcon(resource.type),
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        resource.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  resource.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _launchUrl(resource.link),
                                  icon: const Icon(Icons.open_in_new),
                                  label: Text(
                                    'View ${_getResourceTypeLabel(resource.type)}',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // Add to profile or Edit button
                  Center(
                    child:
                        _user?.createdSkills.contains(widget.skill.id) ?? false
                            ? CustomButton(
                                text: 'Edit Skill',
                                onPressed: () {
                                  // TODO: Navigate to edit skill screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditSkillScreen(
                                        skill: widget.skill,
                                      ),
                                    ),
                                  );
                                },
                                type: ButtonType.primary,
                                icon: Icons.edit,
                              )
                            : CustomButton(
                                text: _isUserSkill
                                    ? 'Remove from My Skills'
                                    : 'Add to My Skills',
                                onPressed: _toggleUserSkill,
                                isLoading: _isAddingToProfile,
                                type: _isUserSkill
                                    ? ButtonType.secondary
                                    : ButtonType.primary,
                                icon: _isUserSkill ? Icons.remove : Icons.add,
                              ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'article':
        return Icons.article;
      case 'course':
        return Icons.school;
      case 'book':
        return Icons.book;
      case 'tool':
        return Icons.build;
      default:
        return Icons.link;
    }
  }

  String _getResourceTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return 'Video';
      case 'article':
        return 'Article';
      case 'course':
        return 'Course';
      case 'book':
        return 'Book';
      case 'tool':
        return 'Tool';
      default:
        return 'Resource';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resource_model.dart';
import '../../models/skill_model.dart';
import '../../providers/user_provider.dart';
import '../../services/resource_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/section_header.dart';
import 'package:url_launcher/url_launcher.dart';

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

      // Check if user has this skill
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      setState(() {
        if (resourceResponse.success && resourceResponse.data != null) {
          _resources = resourceResponse.data!;
        } else {
          _resources = [];
        }

        // Check if this skill is in user's skills
        _isUserSkill =
            user?.skills.any((s) => s.skill.id == widget.skill.id) ?? false;

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
        // Implement remove skill functionality
        final response = await profileService.removeSkill(widget.skill.id);

        if (response.success) {
          // Reload user data to reflect changes
          await userProvider.loadUser();
          setState(() {
            _isUserSkill = false;
          });
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
          setState(() {
            _isUserSkill = true;
          });
        }
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isAddingToProfile = false;
      });
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
      body:
          _isLoading
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
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    resource.description,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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

                    // Add to profile button
                    Center(
                      child: CustomButton(
                        text:
                            _isUserSkill
                                ? 'Remove from My Skills'
                                : 'Add to My Skills',
                        onPressed: _toggleUserSkill,
                        isLoading: _isAddingToProfile,
                        type:
                            _isUserSkill
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

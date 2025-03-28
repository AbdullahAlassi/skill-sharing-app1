import 'package:flutter/material.dart';
import '../../models/resource_model.dart';
import '../../models/skill_model.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/section_header.dart';

class SkillDetailScreen extends StatefulWidget {
  final Skill skill;

  const SkillDetailScreen({Key? key, required this.skill}) : super(key: key);

  @override
  _SkillDetailScreenState createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  bool _isLoading = true;
  List<Resource> _resources = [];
  bool _isUserSkill = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual API calls
    setState(() {
      _resources = [
        Resource(
          id: '1',
          title: 'Getting Started with ${widget.skill.name}',
          description: 'A comprehensive guide for beginners',
          link: 'https://example.com/resource1',
          type: 'Article',
          skill: widget.skill,
          addedBy: 'user1',
          createdAt: DateTime.now(),
        ),
        Resource(
          id: '2',
          title: '${widget.skill.name} Advanced Techniques',
          description: 'Take your skills to the next level',
          link: 'https://example.com/resource2',
          type: 'Video',
          skill: widget.skill,
          addedBy: 'user2',
          createdAt: DateTime.now(),
        ),
      ];

      // Check if user has this skill (for demo purposes)
      _isUserSkill = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        widget.skill.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(widget.skill.category),
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category chip
                          Chip(
                            label: Text(
                              widget.skill.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getCategoryColor(
                              widget.skill.category,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.skill.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),

                          // Add to profile button
                          CustomButton(
                            text:
                                _isUserSkill
                                    ? 'Remove from My Skills'
                                    : 'Add to My Skills',
                            onPressed: () {
                              // TODO: Implement add/remove skill functionality
                              setState(() {
                                _isUserSkill = !_isUserSkill;
                              });
                            },
                            type:
                                _isUserSkill
                                    ? ButtonType.secondary
                                    : ButtonType.primary,
                            icon: _isUserSkill ? Icons.remove : Icons.add,
                          ),
                          const SizedBox(height: 32),

                          // Resources section
                          SectionHeader(
                            title: 'Learning Resources',
                            onSeeAllPressed: () {
                              // Navigate to all resources screen
                            },
                          ),
                          const SizedBox(height: 16),
                          _resources.isEmpty
                              ? const Center(
                                child: Text('No resources available yet'),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _resources.length,
                                itemBuilder: (context, index) {
                                  final resource = _resources[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        child: Icon(
                                          _getResourceTypeIcon(resource.type),
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      title: Text(
                                        resource.title,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(resource.description),
                                          const SizedBox(height: 8),
                                          Text(
                                            resource.type,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // Open resource link
                                      },
                                    ),
                                  );
                                },
                              ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Add Resource',
                            onPressed: () {
                              // Navigate to add resource screen
                            },
                            type: ButtonType.secondary,
                            icon: Icons.add,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Icons.code;
      case 'design':
        return Icons.brush;
      case 'marketing':
        return Icons.trending_up;
      case 'art':
        return Icons.palette;
      default:
        return Icons.school;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Colors.blue;
      case 'design':
        return Colors.purple;
      case 'marketing':
        return Colors.green;
      case 'art':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getResourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'article':
        return Icons.article;
      case 'video':
        return Icons.video_library;
      case 'course':
        return Icons.school;
      case 'book':
        return Icons.book;
      default:
        return Icons.link;
    }
  }
}

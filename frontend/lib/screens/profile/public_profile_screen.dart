import 'package:flutter/material.dart';
import '../../services/public_profile_service.dart';
import '../../config/app_config.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../skills/skill_detail_screen.dart';
import '../../models/skill_model.dart';
import '../../services/skill_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PublicProfileScreenState createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late PublicProfileService _publicProfileService;
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _publicProfileService = PublicProfileService(baseUrl: AppConfig.apiBaseUrl);
    _loadPublicProfile();
  }

  Future<void> _loadPublicProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await _publicProfileService.getPublicProfile(widget.userId);
      if (response['success'] && response['data'] != null) {
        setState(() {
          _user = User.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to load profile';
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
        title: Text(_user?.name ?? 'Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPublicProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? const Center(child: Text('User not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture and Name
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    (_user!.profilePicture != null &&
                                            _user!.profilePicture!.isNotEmpty)
                                        ? NetworkImage(_user!.profilePicture!)
                                        : null,
                                child: (_user!.profilePicture == null ||
                                        _user!.profilePicture!.isEmpty)
                                    ? Text(
                                        _user!.name.isNotEmpty
                                            ? _user!.name[0].toUpperCase()
                                            : '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user!.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    if (_user!.bio != null &&
                                        _user!.bio!.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          _user!.bio!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Created Skills Section
                          Text(
                            'Skills Created by ${_user!.name}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildCreatedSkillsList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildCreatedSkillsList() {
    if (_user!.createdSkills.isEmpty) {
      return const Center(
        child: Text('This user has not created any skills yet.'),
      );
    }

    return FutureBuilder<List<Skill>>(
      future: _loadCreatedSkills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading skills: ${snapshot.error}'),
          );
        }

        final skills = snapshot.data ?? [];

        if (skills.isEmpty) {
          return const Center(
            child: Text('No skills found.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: skills.length,
          itemBuilder: (context, index) {
            final skill = skills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ListTile(
                leading: Icon(_getSkillCategoryIcon(skill.categoryName)),
                title: Text(skill.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Difficulty: ${skill.difficultyLevel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getDifficultyColor(skill.difficultyLevel),
                          ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SkillDetailScreen(skill: skill),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Skill>> _loadCreatedSkills() async {
    final skillService = SkillService();
    final skills = <Skill>[];

    for (final skillId in _user!.createdSkills) {
      try {
        final response = await skillService.getSkillById(skillId);
        if (response.success && response.data != null) {
          skills.add(response.data!);
        }
      } catch (e) {
        print('Error loading skill $skillId: $e');
      }
    }

    return skills;
  }

  // Helper function from SkillDetailScreen to get category icon
  IconData _getSkillCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Icons.code;
      case 'design':
        return Icons.palette;
      case 'language':
        return Icons.language;
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports;
      case 'cooking':
        return Icons.restaurant;
      case 'art':
        return Icons.brush;
      case 'business':
        return Icons.business;
      case 'science':
        return Icons.science;
      default:
        return Icons.school;
    }
  }

  // Helper function from SkillDetailScreen to get difficulty color
  Color _getDifficultyColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }
}

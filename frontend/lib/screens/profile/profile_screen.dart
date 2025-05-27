import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/screens/home/dashboard_screen.dart';
import 'package:skill_sharing_app/utils/token_storage.dart';
import 'package:skill_sharing_app/widget/skill_card.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/profile_service.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import '../skills/skill_detail_screen.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../auth/favorite_categories_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  User? _user;
  List<Skill> _userSkills = [];
  List<String> _favoriteCategories = [];
  List<Skill> _createdSkills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // If user is not loaded, try to load it
      if (userProvider.user == null) {
        print('User not loaded, attempting to load user data...');
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await userProvider.loadUser();
        });
      }

      final user = userProvider.user;
      print('Current user: ${user?.name ?? "null"}');
      print('Created skills IDs: ${user?.createdSkills ?? []}');

      if (!mounted) return;

      setState(() {
        _user = user;
        if (user != null) {
          _userSkills = [];
          _favoriteCategories = user.favoriteCategories;
          _createdSkills = []; // We'll fetch these skills
        } else {
          _userSkills = [];
          _favoriteCategories = [];
          _createdSkills = [];
        }
      });

      // Fetch user's skills
      if (user != null) {
        final profileService =
            ProfileService(ApiClient(baseUrl: AppConfig.apiBaseUrl));
        final skillsResponse = await profileService.getUserSkills();

        if (skillsResponse.success && skillsResponse.data != null) {
          print('\n=== Processing User Skills ===');
          print('Raw skills data: ${skillsResponse.data}');

          if (mounted) {
            setState(() {
              _userSkills = (skillsResponse.data as List)
                  .where((skillObj) {
                    print('\nChecking skill object: $skillObj');
                    final hasSkill = skillObj['skill'] != null;
                    print('Has skill data: $hasSkill');
                    return hasSkill;
                  })
                  .map((skillObj) {
                    print('\nProcessing skill object: $skillObj');
                    final skillData = skillObj['skill'];
                    if (skillData is Map<String, dynamic>) {
                      print('Skill data: $skillData');

                      // Extract category name safely
                      final categoryName =
                          skillData['category']?['name']?.toString() ?? '';
                      print('Category name: $categoryName');

                      // Create skill map with safe defaults
                      final skillMap = {
                        'id': skillData['_id']?.toString() ?? '',
                        'name': skillData['name']?.toString() ?? '',
                        'description':
                            skillData['description']?.toString() ?? '',
                        'category': categoryName,
                        'difficultyLevel':
                            skillData['difficultyLevel']?.toString() ??
                                'Beginner',
                        'proficiency': skillObj['proficiency']?.toString() ??
                            skillData['proficiency']?.toString() ??
                            'Beginner',
                        'createdAt': skillData['createdAt']?.toString() ??
                            DateTime.now().toIso8601String(),
                        'createdBy': skillData['createdBy']?.toString(),
                        'resources': skillData['resources'] ?? [],
                        'relatedSkills': skillData['relatedSkills'] ?? [],
                        'roadmap': skillData['roadmap'] ?? [],
                      };

                      print('Created skill map: $skillMap');
                      final skill = Skill.fromJson(skillMap);
                      print('Created skill instance: ${skill.name}');
                      return skill;
                    }
                    print('Invalid skill data format');
                    return null;
                  })
                  .where((skill) => skill != null)
                  .cast<Skill>()
                  .toList();

              print('\nFinal user skills list:');
              print('Number of skills: ${_userSkills.length}');
              print(
                  'Skill names: ${_userSkills.map((s) => s.name).join(', ')}');
              print('=== End Processing User Skills ===\n');
            });
          }
        } else {
          print("Failed to load user skills: ${skillsResponse.error}");
        }

        // Fetch created skills using the new endpoint
        final skillService = SkillService();
        final createdSkillsResponse = await skillService.getMyCreatedSkills();
        if (createdSkillsResponse.success &&
            createdSkillsResponse.data != null) {
          if (mounted) {
            setState(() {
              _createdSkills = List<Skill>.from(createdSkillsResponse.data!);
              print("Created skills loaded: ${_createdSkills.length}");
              print(
                  "Created skills: ${_createdSkills.map((s) => s.name).join(', ')}");
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _createdSkills = [];
              print(
                  "Failed to load created skills: ${createdSkillsResponse.error}");
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            ).then((_) => _loadUserData());
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) => _loadUserData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_user != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile header with improved design
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundImage: _user!.profilePicture !=
                                                null &&
                                            _user!.profilePicture!.isNotEmpty
                                        ? NetworkImage(_user!.profilePicture!)
                                        : null,
                                    child: _user!.profilePicture == null ||
                                            _user!.profilePicture!.isEmpty
                                        ? const Icon(Icons.person, size: 40)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _user!.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _user!.email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  AppTheme.textSecondaryColor,
                                            ),
                                      ),
                                      if (_user!.bio != null &&
                                          _user!.bio!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _user!.bio!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tabs with improved design
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: AppTheme.textSecondaryColor,
                              indicatorColor: Theme.of(context).primaryColor,
                              indicatorSize: TabBarIndicatorSize.label,
                              labelStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              tabs: const [
                                Tab(text: 'My Skills'),
                                Tab(text: 'Favorite Categories'),
                                Tab(text: 'Created Skills'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // TabBarView content remains the same
                          SizedBox(
                            height: 500,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Skills Tab
                                _userSkills.isEmpty
                                    ? const Center(
                                        child: Text('No skills added yet.'),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.only(top: 16),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: _userSkills.length,
                                        itemBuilder: (context, index) {
                                          return SkillCard(
                                            skill: _userSkills[index],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SkillDetailScreen(
                                                    skill: _userSkills[index],
                                                  ),
                                                ),
                                              ).then((_) => _loadUserData());
                                            },
                                          );
                                        },
                                      ),

                                // Favorite Categories Tab
                                Column(
                                  children: [
                                    Expanded(
                                      child: Consumer<UserProvider>(
                                        builder:
                                            (context, userProvider, child) {
                                          final favoriteCategories =
                                              userProvider.user
                                                      ?.favoriteCategories ??
                                                  [];

                                          if (favoriteCategories.isEmpty)
                                            return const Center(
                                              child: Text(
                                                  'No favorite categories selected yet.'),
                                            );

                                          return ListView.builder(
                                            padding:
                                                const EdgeInsets.only(top: 16),
                                            itemCount:
                                                favoriteCategories.length,
                                            itemBuilder: (context, index) {
                                              return Card(
                                                margin: const EdgeInsets.only(
                                                    bottom: 8),
                                                child: ListTile(
                                                  title: Text(
                                                    favoriteCategories[index],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
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

                                // Created Skills Tab
                                _createdSkills.isEmpty
                                    ? const Center(
                                        child: Text('No skills created yet.'),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.only(top: 16),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                        ),
                                        itemCount: _createdSkills.length,
                                        itemBuilder: (context, index) {
                                          return SkillCard(
                                            skill: _createdSkills[index],
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SkillDetailScreen(
                                                    skill:
                                                        _createdSkills[index],
                                                  ),
                                                ),
                                              ).then((_) => _loadUserData());
                                            },
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content:
                                const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true && mounted) {
                          // Use AuthProvider for logout
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.logout(context);

                          if (!mounted) return;

                          // Navigate to login screen
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

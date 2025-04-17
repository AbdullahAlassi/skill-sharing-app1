import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/profile_service.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/section_header.dart';
import 'package:frontend/widget/skill_card.dart';
import '../skills/skill_detail_screen.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUser();

      if (!mounted) return;

      final user = userProvider.user;

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
        _isLoading = false;
      });

      // Fetch user's skills
      if (user != null) {
        final skillService = SkillService();
        final skills = <Skill>[];

        // Fetch skills from user.skills array
        for (final skillId in user.skills) {
          final response = await skillService.getSkillById(skillId);
          if (response.success && response.data != null) {
            skills.add(response.data!);
          }
        }

        if (mounted) {
          setState(() {
            _userSkills = skills;
          });
        }
      }

      // Fetch created skills
      if (user != null && user.createdSkills.isNotEmpty) {
        final skillService = SkillService();
        final skills = <Skill>[];

        for (final skillId in user.createdSkills) {
          final response = await skillService.getSkillById(skillId);
          if (response.success && response.data != null) {
            skills.add(response.data!);
          }
        }

        if (mounted) {
          setState(() {
            _createdSkills = skills;
          });
        }
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
          : _user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _user!.profilePicture != null &&
                                    _user!.profilePicture!.isNotEmpty
                                ? NetworkImage(_user!.profilePicture!)
                                : null,
                            child: _user!.profilePicture == null ||
                                    _user!.profilePicture!.isEmpty
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user!.name,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user!.email,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                                if (_user!.bio != null &&
                                    _user!.bio!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _user!.bio!,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tabs
                      TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryColor,
                        unselectedLabelColor: AppTheme.textSecondaryColor,
                        indicatorColor: AppTheme.primaryColor,
                        tabs: const [
                          Tab(text: 'My Skills'),
                          Tab(text: 'Favorite Categories'),
                          Tab(text: 'Created Skills'),
                        ],
                      ),
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
                            _favoriteCategories.isEmpty
                                ? const Center(
                                    child: Text(
                                        'No favorite categories selected yet.'),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(top: 16),
                                    itemCount: _favoriteCategories.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          title: Text(
                                            _favoriteCategories[index],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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
                                                skill: _createdSkills[index],
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
    );
  }
}

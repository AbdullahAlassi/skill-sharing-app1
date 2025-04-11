import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/profile_service.dart';
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
  List<Skill> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Don't call _loadUserData() here
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call _loadUserData() here instead
    if (_isLoading) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data from provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Use Future.microtask to schedule this after the current build phase
      Future.microtask(() async {
        await userProvider.loadUser();

        if (!mounted) return;

        final user = userProvider.user;

        setState(() {
          _user = user;

          // Extract user skills and interests
          if (user != null) {
            _userSkills = user.skills.map((s) => s.skill).toList();
            _userInterests = user.interests ?? [];
          } else {
            _userSkills = [];
            _userInterests = [];
          }

          _isLoading = false;
        });
      });
    } catch (e) {
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
              ? const Center(child: Text('Failed to load user data.'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.2,
                          ),
                          backgroundImage:
                              _user!.profilePicture != null &&
                                      _user!.profilePicture!.isNotEmpty
                                  ? NetworkImage(_user!.profilePicture!)
                                  : null,
                          child:
                              _user!.profilePicture != null &&
                                      _user!.profilePicture!.isNotEmpty
                                  ? null
                                  : Icon(
                                    Icons.person,
                                    size: 40,
                                    color: AppTheme.primaryColor,
                                  ),
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
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              if (_user!.bio != null &&
                                  _user!.bio!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _user!.bio!,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                        Tab(text: 'Interests'),
                      ],
                    ),
                    Expanded(
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
                                          builder:
                                              (context) => SkillDetailScreen(
                                                skill: _userSkills[index],
                                              ),
                                        ),
                                      ).then((_) => _loadUserData());
                                    },
                                  );
                                },
                              ),

                          // Interests Tab
                          _userInterests.isEmpty
                              ? const Center(
                                child: Text('No interests added yet.'),
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
                                itemCount: _userInterests.length,
                                itemBuilder: (context, index) {
                                  return SkillCard(
                                    skill: _userInterests[index],
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => SkillDetailScreen(
                                                skill: _userInterests[index],
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
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Logout',
                      onPressed: () async {
                        final userProvider = Provider.of<UserProvider>(
                          context,
                          listen: false,
                        );
                        await userProvider.logout();
                        // Navigate to login screen
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      type: ButtonType.secondary,
                      icon: Icons.logout,
                    ),
                  ],
                ),
              ),
    );
  }
}

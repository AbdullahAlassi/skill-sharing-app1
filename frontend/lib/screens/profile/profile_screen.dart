import 'package:flutter/material.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/section_header.dart';
import 'package:frontend/widget/skill_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  User? _user;
  List<Skill> _userSkills = [];
  List<Skill> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual API calls
    setState(() {
      _user = User(
        id: '1',
        name: 'Test User',
        email: 'test.user@example.com',
        bio:
            'Passionate developer and designer with 5 years of experience. Love to learn new technologies and share knowledge with others.',
        profilePicture: 'https://randomuser.me/api/portraits/men/32.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      );

      _userSkills = [
        Skill(
          id: '1',
          name: 'Flutter Development',
          category: 'Programming',
          description: 'Building cross-platform mobile applications',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '2',
          name: 'UI/UX Design',
          category: 'Design',
          description: 'Creating user-friendly interfaces',
          createdAt: DateTime.now(),
        ),
      ];

      _userInterests = [
        Skill(
          id: '3',
          name: 'Machine Learning',
          category: 'Programming',
          description: 'Building intelligent systems',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '4',
          name: 'Digital Marketing',
          category: 'Marketing',
          description: 'Promoting products and services online',
          createdAt: DateTime.now(),
        ),
      ];

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadUserData,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'Profile',
                          style: const TextStyle(color: Colors.white),
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Navigate to settings screen
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Profile header
                          _buildProfileHeader(),

                          // Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: AppTheme.primaryColor,
                              unselectedLabelColor: AppTheme.textSecondaryColor,
                              indicatorColor: AppTheme.primaryColor,
                              tabs: const [
                                Tab(text: 'Skills'),
                                Tab(text: 'Interests'),
                                Tab(text: 'Progress'),
                              ],
                            ),
                          ),

                          // Tab content
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildSkillsTab(),
                                _buildInterestsTab(),
                                _buildProgressTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile picture
          CircleAvatar(
            radius: 50,
            backgroundImage:
                _user?.profilePicture != null
                    ? NetworkImage(_user!.profilePicture!)
                    : null,
            child:
                _user?.profilePicture == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
          ),
          const SizedBox(height: 16),

          // User name
          Text(
            _user?.name ?? 'User',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // User bio
          Text(
            _user?.bio ?? 'No bio available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Member since
          Text(
            'Member since ${_formatDate(_user?.createdAt ?? DateTime.now())}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Edit profile button
          CustomButton(
            text: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: _user),
                ),
              ).then((_) => _loadUserData());
            },
            type: ButtonType.secondary,
            icon: Icons.edit,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'My Skills',
            subtitle: 'Skills you have added to your profile',
            onSeeAllPressed: _userSkills.length > 4 ? () {} : null,
          ),
          const SizedBox(height: 16),
          _userSkills.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You haven\'t added any skills yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Browse Skills',
                      onPressed: () {
                        // Navigate to skills screen
                      },
                      type: ButtonType.primary,
                      icon: Icons.search,
                      isFullWidth: false,
                    ),
                  ],
                ),
              )
              : Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        // Navigate to skill detail
                      },
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildInterestsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'My Interests',
            subtitle: 'Skills you are interested in learning',
            onSeeAllPressed: _userInterests.length > 4 ? () {} : null,
          ),
          const SizedBox(height: 16),
          _userInterests.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.interests_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You haven\'t added any interests yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Explore Skills',
                      onPressed: () {
                        // Navigate to skills screen
                      },
                      type: ButtonType.primary,
                      icon: Icons.explore,
                      isFullWidth: false,
                    ),
                  ],
                ),
              )
              : Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        // Navigate to skill detail
                      },
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'My Progress',
            subtitle: 'Track your learning journey',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.trending_up,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress tracking coming soon!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Set Learning Goals',
                    onPressed: () {
                      // Navigate to goals screen
                    },
                    type: ButtonType.primary,
                    icon: Icons.flag,
                    isFullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

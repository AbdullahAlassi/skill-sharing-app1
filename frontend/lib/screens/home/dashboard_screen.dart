import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/screens/notification/notificationScreen.dart';
import 'package:skill_sharing_app/widget/event_card.dart';
import 'package:skill_sharing_app/widget/section_header.dart';
import 'package:skill_sharing_app/widget/skill_card.dart';
import 'package:skill_sharing_app/widget/resource_card.dart';
import 'package:skill_sharing_app/widget/app_drawer.dart';
import '../../models/event_model.dart';
import '../../models/skill_model.dart';
import '../../models/resource_model.dart' as rm;
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/skill_service.dart';
import '../../services/resource_service.dart';
import '../../theme/app_theme.dart';
import '../skills/skill_detail_screen.dart';
import '../events/events_screen.dart';
import '../skills/skills_screen.dart';
import '../skills/recommended_skills_screen.dart';
import '../profile/profile_screen.dart';
import '../resources/resource_detail_screen.dart';
import '../resources/resource_recommendation_screen.dart';
import '../../providers/notification_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Skill> _recommendedSkills = [];
  List<Event> _upcomingEvents = [];
  List<rm.Resource> _recommendedResources = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const SkillsScreen(),
    const EventsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    // Initialize notification count
    Future.microtask(() {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

      final currentUser = userProvider.user;
      print('Current user: ${currentUser?.name ?? "null"}');

      if (currentUser == null) {
        print('Loading recommendations for user: null');
        print('User favorite categories: null');
      } else {
        print('Loading recommendations for user: ${currentUser.id}');
        print('User favorite categories: ${currentUser.favoriteCategories}');
      }

      // Load recommended skills
      final skillService = SkillService();
      final skillsResponse = await skillService.getRecommendations();

      if (skillsResponse.success && skillsResponse.data != null) {
        setState(() {
          // Filter out skills created by the current user
          _recommendedSkills = skillsResponse.data!
              .where((skill) => skill.createdBy?.id != currentUser?.id)
              .toList();
        });
      } else {
        setState(() {
          _errorMessage =
              skillsResponse.error ?? 'Failed to load recommended skills';
        });
      }

      // Load recommended resources
      final resourceService = ResourceService();
      final resourcesResponse =
          await resourceService.getResourcesByFavoriteCategories();

      if (resourcesResponse.success && resourcesResponse.data != null) {
        print(
            '[DEBUG DashboardScreen] Raw recommended resources received: ${resourcesResponse.data!.length}');
        setState(() {
          _recommendedResources = resourcesResponse.data!;
          print(
              '[DEBUG DashboardScreen] Recommended resources after filtering: ${_recommendedResources.length}');
        });
      } else {
        print(
            '[DEBUG DashboardScreen] Failed to load recommended resources: ${resourcesResponse.error}');
      }

      // Load upcoming events
      final eventService = EventService();
      final eventsResponse = await eventService.getEvents();

      if (eventsResponse.success && eventsResponse.data != null) {
        setState(() {
          _upcomingEvents = eventsResponse.data!
              .where((event) =>
                  event.isUpcoming && event.organizerId != currentUser?.id)
              .toList();
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Skills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Skill> _recommendedSkills = [];
  List<Event> _upcomingEvents = [];
  List<rm.Resource> _recommendedResources = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      // Load recommended skills
      final skillService = SkillService();
      final skillsResponse = await skillService.getRecommendations();

      if (skillsResponse.success && skillsResponse.data != null) {
        setState(() {
          _recommendedSkills = skillsResponse.data!
              .where((skill) => skill.createdBy?.id != currentUser?.id)
              .toList();
        });
      }

      // Load recommended resources
      final resourceService = ResourceService();
      final resourcesResponse =
          await resourceService.getResourcesByFavoriteCategories();

      if (resourcesResponse.success && resourcesResponse.data != null) {
        print(
            '[DEBUG HomeContent] Raw recommended resources received: ${resourcesResponse.data!.length}');
        setState(() {
          // Filter out resources created by the current user
          _recommendedResources = resourcesResponse.data!;
          print(
              '[DEBUG HomeContent] Recommended resources after filtering: ${_recommendedResources.length}');
        });
      } else {
        print(
            '[DEBUG HomeContent] Failed to load recommended resources: ${resourcesResponse.error}');
      }

      // Load upcoming events
      final eventService = EventService();
      final eventsResponse = await eventService.getEvents();

      if (eventsResponse.success && eventsResponse.data != null) {
        setState(() {
          _upcomingEvents = eventsResponse.data!
              .where((event) =>
                  event.isUpcoming && event.organizerId != currentUser?.id)
              .toList();
        });
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Dashboard'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User greeting
                    Text(
                      'Hello, ${currentUser?.name ?? "User"}!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What would you like to learn today?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 24.0),

                    // Recommended Skills Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended Skills',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecommendedSkillsScreen(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _recommendedSkills.isEmpty
                        ? const Center(child: Text('No skills available'))
                        : SizedBox(
                            height: 250,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recommendedSkills.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12.0),
                              itemBuilder: (context, index) {
                                final skill = _recommendedSkills[index];
                                return SkillCard(
                                  skill: skill,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SkillDetailScreen(skill: skill),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 24.0),

                    // Recommended Resources Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended Resources',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ResourceRecommendationScreen(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _recommendedResources.isEmpty
                        ? const Center(child: Text('No resources available'))
                        : SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recommendedResources.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 4.0),
                              itemBuilder: (context, index) {
                                final resource = _recommendedResources[index];
                                return DashboardResourceCard(
                                  resource: resource,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SkillDetailScreen(
                                          skill: resource.skill,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                );
                              },
                            ),
                          ),

                    const SizedBox(height: 24.0),

                    // Upcoming Events Section
                    SectionHeader(
                      title: 'Upcoming Events',
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EventsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _upcomingEvents.isEmpty
                        ? const Center(
                            child: Text('No upcoming events available'),
                          )
                        : SizedBox(
                            height: 250,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _upcomingEvents.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12.0),
                              itemBuilder: (context, index) {
                                final event = _upcomingEvents[index];
                                return EventCard(event: event);
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class DashboardResourceCard extends StatelessWidget {
  final rm.Resource resource;
  final VoidCallback? onTap;

  const DashboardResourceCard({
    Key? key,
    required this.resource,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getResourceTypeIcon(resource.type),
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resource.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: resource.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(resource.skill.name),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added by: ${resource.addedBy['name']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getResourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'link':
        return Icons.link;
      case 'image':
        return Icons.image;
      default:
        return Icons.article;
    }
  }
}

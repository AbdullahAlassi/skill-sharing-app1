import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../models/skill_model.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/event_card.dart';
import 'package:frontend/widget/section_header.dart';
import 'package:frontend/widget/skill_card.dart';
import '../skills/skill_detail_screen.dart';
import '../events/events_screen.dart';
import '../skills/skills_screen.dart';
import '../skills/recommended_skills_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Skill> _recommendedSkills = [];
  List<Event> _upcomingEvents = [];
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

      // If user is not loaded, try to load it
      if (currentUser == null) {
        print('User not loaded, attempting to load user data...');
        await userProvider.loadUser();
      }

      final updatedUser = userProvider.user;
      print('Current user: ${updatedUser?.name ?? "null"}');

      if (updatedUser == null) {
        print('Loading recommendations for user: null');
        print('User favorite categories: null');
      } else {
        print('Loading recommendations for user: ${updatedUser.id}');
        print('User favorite categories: ${updatedUser.favoriteCategories}');
      }

      // Load recommended skills
      final skillService = SkillService();
      final skillsResponse = await skillService.getRecommendations();

      if (skillsResponse.success && skillsResponse.data != null) {
        setState(() {
          _recommendedSkills = skillsResponse.data!;
        });
      } else {
        setState(() {
          _errorMessage =
              skillsResponse.error ?? 'Failed to load recommended skills';
        });
      }

      // Load upcoming events
      final eventService = EventService();
      final eventsResponse = await eventService.getEvents();

      if (eventsResponse.success && eventsResponse.data != null) {
        setState(() {
          _upcomingEvents =
              eventsResponse.data!.where((event) => event.isUpcoming).toList();
        });
      }

      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
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
                            height: 200,
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

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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Skill> _recommendedSkills = [];
  List<Event> _upcomingEvents = [];
  bool _isLoading = false;

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
      // Get user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      print('Loading recommendations for user: ${user?.id}');

      // Get skill recommendations
      final skillService = SkillService();
      final skillResponse = await skillService.getRecommendations();

      print('Recommendations response: ${skillResponse.success}');
      print('Recommendations data length: ${skillResponse.data?.length ?? 0}');
      if (!skillResponse.success) {
        print('Recommendations error: ${skillResponse.error}');
      }

      // Get upcoming events
      final eventService = EventService();
      final eventResponse = await eventService.getEvents();

      setState(() {
        if (skillResponse.success && skillResponse.data != null) {
          // Limit to 4 skills
          _recommendedSkills = skillResponse.data!.take(4).toList();
          print('Loaded ${_recommendedSkills.length} recommended skills');
        } else {
          // If recommendations failed, get some default skills
          _loadDefaultSkills();
        }

        if (eventResponse.success && eventResponse.data != null) {
          // Sort events by date and take only upcoming ones
          _upcomingEvents =
              eventResponse.data!
                  .where((event) => event.date.isAfter(DateTime.now()))
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));

          // Limit to 3 events
          if (_upcomingEvents.length > 3) {
            _upcomingEvents = _upcomingEvents.sublist(0, 3);
          }
        } else {
          _upcomingEvents = [];
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _recommendedSkills = [];
        _upcomingEvents = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDefaultSkills() async {
    try {
      final skillService = SkillService();
      final response = await skillService.getSkills();

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        setState(() {
          // Take the first 4 skills as default recommendations
          _recommendedSkills = response.data!.take(4).toList();
          print('Loaded ${_recommendedSkills.length} default skills');
        });
      } else {
        setState(() {
          _recommendedSkills = [];
          print('No default skills available');
        });
      }
    } catch (e) {
      print('Error loading default skills: $e');
      setState(() {
        _recommendedSkills = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body:
          _isLoading
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
                        'Hello, ${Provider.of<UserProvider>(context).user?.name ?? "User"}!',
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
                      SectionHeader(
                        title: 'Recommended Skills',
                        onViewAll: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SkillsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _recommendedSkills.isEmpty
                          ? const Center(child: Text('No skills available'))
                          : SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recommendedSkills.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(width: 12.0),
                              itemBuilder: (context, index) {
                                final skill = _recommendedSkills[index];
                                return SkillCard(
                                  skill: skill,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
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
                              separatorBuilder:
                                  (context, index) =>
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

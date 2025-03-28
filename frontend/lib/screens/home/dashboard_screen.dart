import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/skill_model.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/event_card.dart';
import 'package:frontend/widget/section_header.dart';
import 'package:frontend/widget/skill_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Skill> _recommendedSkills = [];
  List<Event> _upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual API calls
    setState(() {
      _recommendedSkills = [
        Skill(
          id: '1',
          name: 'Flutter Development',
          category: 'Programming',
          description: 'Learn to build beautiful cross-platform apps',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '2',
          name: 'UI/UX Design',
          category: 'Design',
          description: 'Create stunning user interfaces and experiences',
          createdAt: DateTime.now(),
        ),
        Skill(
          id: '3',
          name: 'Digital Marketing',
          category: 'Marketing',
          description: 'Master the art of online marketing',
          createdAt: DateTime.now(),
        ),
      ];

      _upcomingEvents = [
        Event(
          id: '1',
          title: 'Flutter Workshop',
          description: 'Learn Flutter basics and build your first app',
          date: DateTime.now().add(const Duration(days: 2)),
          location: 'Online',
          organizerId: '1',
          organizerName: 'John Doe',
          isVirtual: true,
          createdAt: DateTime.now(),
        ),
        Event(
          id: '2',
          title: 'UI/UX Masterclass',
          description:
              'Advanced techniques for creating better user experiences',
          date: DateTime.now().add(const Duration(days: 5)),
          location: 'Tech Hub, New York',
          organizerId: '2',
          organizerName: 'Jane Smith',
          isVirtual: false,
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
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: true,
                      pinned: true,
                      backgroundColor: AppTheme.primaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Skill Sharing',
                          style: TextStyle(color: Colors.white),
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            // Navigate to search screen
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Navigate to notifications screen
                          },
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // User greeting
                          Text(
                            'Hello, John!',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'What would you like to learn today?',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textSecondaryColor),
                          ),
                          const SizedBox(height: 24),

                          // Recommended skills section
                          SectionHeader(
                            title: 'Recommended Skills',
                            onSeeAllPressed: () {
                              // Navigate to skills screen
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recommendedSkills.length,
                              itemBuilder: (context, index) {
                                return SizedBox(
                                  width: 160,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: SkillCard(
                                      skill: _recommendedSkills[index],
                                      onTap: () {
                                        // Navigate to skill detail screen
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Upcoming events section
                          SectionHeader(
                            title: 'Upcoming Events',
                            onSeeAllPressed: () {
                              // Navigate to events screen
                            },
                          ),
                          const SizedBox(height: 16),
                          ..._upcomingEvents.map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: EventCard(
                                event: event,
                                onTap: () {
                                  // Navigate to event detail screen
                                },
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

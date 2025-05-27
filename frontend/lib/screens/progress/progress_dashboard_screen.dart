import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/progress_provider.dart';
import '../../providers/skill_provider.dart';
import '../../models/goal_model.dart';
import '../../widget/progress/overall_progress_chart.dart';
import '../../widget/progress/practice_chart.dart';
import '../../widget/progress/progress_card.dart';
import '../../widget/skill_card.dart';
import '../goals/set_goal_screen.dart';
import '../goals/goal_edit_screen.dart';
import '../skills/skill_detail_screen.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load progress data when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().fetchUserProgress();
      context.read<SkillProvider>().loadRecommendedSkills(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProgressProvider>().fetchUserProgress();
              context.read<SkillProvider>().loadRecommendedSkills(context);
            },
          ),
        ],
      ),
      body: Consumer2<ProgressProvider, SkillProvider>(
        builder: (context, progressProvider, skillProvider, child) {
          if (progressProvider.isLoading || skillProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (progressProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    progressProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      progressProvider.fetchUserProgress();
                      skillProvider.loadRecommendedSkills(context);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await progressProvider.fetchUserProgress();
              await skillProvider.loadRecommendedSkills(context);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Progress Summary
                  const OverallProgressChart(),
                  const SizedBox(height: 24),

                  // Recommended Skills Section
                  const Text(
                    'Recommended Skills',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (skillProvider.recommendedSkills.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recommendations available',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add favorite categories to get personalized recommendations',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: skillProvider.recommendedSkills.length,
                        itemBuilder: (context, index) {
                          final skill = skillProvider.recommendedSkills[index];
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Expanded(
                                  child: SkillCard(
                                    skill: skill,
                                    onTap: () {
                                      debugPrint(
                                          '[Analytics] User tapped recommended skill from dashboard: ${skill.name}');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SkillDetailScreen(
                                            skill: skill,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (skill.recommendationReason != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Tooltip(
                                      message: skill.recommendationReason!,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                        child: Text(
                                          skill.recommendationReason!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Per-Skill Progress
                  const Text(
                    'Skill Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (progressProvider.skillProgress.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No skills tracked yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add a skill to start tracking your progress',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...progressProvider.skillProgress.map(
                      (skillProgress) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProgressCard(skillProgress: skillProgress),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Goals Section
                  const Text(
                    'My Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (progressProvider.goals.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No goals set yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Goals are automatically created when you add a skill',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: progressProvider.goals.length,
                      itemBuilder: (context, index) {
                        final goal = progressProvider.goals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goal.skill.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    'Target: ${DateFormat.yMMMd().format(goal.targetDate)}'),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: goal.currentProgress / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(goal.currentProgress),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    'Progress: ${goal.currentProgress.toStringAsFixed(1)}%'),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                      goal.status.toString().split('.').last),
                                  backgroundColor: _getStatusColor(goal.status),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Completed Resources
                  const Text(
                    'Recently Completed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: progressProvider.completedResources.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No completed resources yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Complete resources to see them here',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                progressProvider.completedResources.length,
                            itemBuilder: (context, index) {
                              final resource =
                                  progressProvider.completedResources[index];
                              return Card(
                                margin: const EdgeInsets.only(right: 16),
                                child: Container(
                                  width: 280,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _getResourceTypeIcon(resource.type),
                                            color:
                                                Theme.of(context).primaryColor,
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
                                        'Completed on ${resource.completions.isNotEmpty ? resource.completions.first.completedAt.toLocal().toString().split(' ')[0] : 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
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

  Color _getProgressColor(double progress) {
    if (progress >= 100) {
      return Colors.green;
    } else if (progress > 0) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.completed:
        return Colors.green[100]!;
      case GoalStatus.expired:
        return Colors.red[100]!;
      default:
        return Colors.blue[100]!;
    }
  }
}

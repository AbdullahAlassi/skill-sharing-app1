import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/screens/resources/resource_detail_screen.dart';
import 'package:skill_sharing_app/screens/skills/skill_roadmap_screen.dart';
import 'package:skill_sharing_app/widget/custome_button.dart';
import 'package:skill_sharing_app/widget/section_header.dart';
import '../../models/resource_model.dart' as rm;
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../models/skill_proficiency_model.dart';
import '../../providers/user_provider.dart';
import '../../services/resource_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_skill_screen.dart';
import '../../services/api_client.dart';
import '../../config/app_config.dart';
import '../../services/skill_service.dart';
import '../resources/add_resource_screen.dart';
import '../../models/skill_review_model.dart';
import '../../services/skill_review_service.dart';
import '../../widget/skill_review_card.dart';
import '../../models/user_model.dart' as um;
import '../profile/public_profile_screen.dart';
import '../../services/progress_service.dart';

class SkillDetailScreen extends StatefulWidget {
  final Skill skill;

  const SkillDetailScreen({
    Key? key,
    required this.skill,
  }) : super(key: key);

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen>
    with TickerProviderStateMixin {
  List<rm.Resource> _resources = [];
  bool _isLoading = false;
  bool _isUserSkill = false;
  bool _isAddingToProfile = false;
  User? _user;
  bool _isCompleted = false;
  double _progress = 0.0;
  late Skill _currentSkill;

  List<SkillReview> _reviews = [];
  bool _isLoadingReviews = false;
  String? _reviewsError;
  late SkillReviewService _skillReviewService;

  List<Skill> _relatedSkills = [];
  bool _isLoadingRelatedSkills = false;

  // Add a listener for the UserProvider
  late VoidCallback _userProviderListener;

  // Declare UserProvider field
  late UserProvider _userProvider;

  double _skillProgress = 0.0;
  int _practiceTimeMinutes = 0;
  double? _assessmentScore;

  @override
  void initState() {
    super.initState();
    _currentSkill = widget.skill;
    _skillReviewService = SkillReviewService(baseUrl: AppConfig.apiBaseUrl);

    // Initialize the listener after the provider is available in context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get and store the UserProvider instance
      _userProvider = Provider.of<UserProvider>(context, listen: false);

      _userProviderListener = () {
        // This callback will be called when notifyListeners() is called in UserProvider
        _updateUserState();
      };
      // Add listener using the stored instance
      _userProvider.addListener(_userProviderListener);

      // Initial state update based on current user in provider
      _updateUserState();

      // Load other data
      _loadData(); // This will still load resources, skill details, etc.
      _loadRelatedSkills();
    });

    _loadSkillProgress();
  }

  // New method to update user-related state
  void _updateUserState() {
    print('\n=== Updating User State ===');
    print('Current user: ${_userProvider.user?.id}');
    print('Current skill: ${_currentSkill.id}');
    print('User skills: ${_userProvider.user?.skills}');

    if (_userProvider.user != null) {
      // Check if the current skill is in the user's skills list
      _isUserSkill = _userProvider.user!.skills.any((skillId) {
        print('Comparing skill IDs:');
        print('- Current skill ID: ${_currentSkill.id}');
        print('- User skill ID: $skillId');
        return skillId == _currentSkill.id;
      });

      print('Is user skill: $_isUserSkill');
    } else {
      _isUserSkill = false;
      print('User is null, setting _isUserSkill to false');
    }
    print('=== User State Update Complete ===\n');
  }

  @override
  void dispose() {
    // Remove the listener using the stored instance
    _userProvider.removeListener(_userProviderListener);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      // Get resources for this skill
      final resourceService = ResourceService();
      print('[DEBUG] Loading resources for skill: ${_currentSkill.id}');
      final resourceResponse = await resourceService.getResourcesBySkill(
        _currentSkill.id,
      );

      print('[DEBUG] Resource response success: ${resourceResponse.success}');
      print(
          '[DEBUG] Resource data length: ${resourceResponse.data?.length ?? 0} resources');

      // Fetch the latest skill data to ensure we have the correct difficulty level and creator info
      final skillService = SkillService();
      print('[DEBUG] Fetching skill details for skill: ${_currentSkill.id}');
      final skillResponse = await skillService.getSkillById(_currentSkill.id);

      print('[DEBUG] Skill response success: ${skillResponse.success}');

      if (skillResponse.success && skillResponse.data != null) {
        print(
            '[DEBUG] Skill data received: ${skillResponse.data}'); // Log the received skill data
        print(
            '[DEBUG] Creator data in response: ${skillResponse.data?.createdBy}'); // Log creator data specifically
        setState(() {
          _currentSkill = skillResponse.data!;
        });

        // Add debug logging for creator detection
        print('[DEBUG] Skill creator ID: ${_currentSkill.createdBy?.id}');
        print('[DEBUG] Current user ID: ${_user?.id}');
      }

      setState(() {
        if (resourceResponse.success && resourceResponse.data != null) {
          _resources = resourceResponse.data!;
          print('Set resources: ${_resources.length}');
        } else {
          _resources = [];
          print('No resources found or error: ${resourceResponse.error}');
        }

        _isLoading = false;
      });

      // Load reviews after initial data is loaded
      await _loadReviews();
    } catch (e) {
      print('Error in _loadData: $e');
      setState(() {
        _resources = [];
        _isUserSkill = false;
        _isLoading = false;
        _isLoadingReviews = false;
        _reviewsError = e.toString();
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final response = await _skillReviewService.getReviews(_currentSkill.id);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _reviews = List<SkillReview>.from(
              response['data'].map((x) => SkillReview.fromJson(x)));
          _isLoadingReviews = false;
        });
      } else {
        setState(() {
          _reviews = [];
          _reviewsError = response['error'] ?? 'Failed to load reviews';
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      setState(() {
        _reviews = [];
        _reviewsError = 'Error loading reviews: ${e.toString()}';
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadRelatedSkills() async {
    if (_currentSkill.relatedSkills == null ||
        _currentSkill.relatedSkills!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingRelatedSkills = true;
    });

    try {
      final skillService = SkillService();
      final relatedSkills = <Skill>[];

      for (final skillId in _currentSkill.relatedSkills!) {
        final response = await skillService.getSkillById(skillId);
        if (response.success && response.data != null) {
          relatedSkills.add(response.data!);
        }
      }

      setState(() {
        _relatedSkills = relatedSkills;
        _isLoadingRelatedSkills = false;
      });
    } catch (e) {
      print('Error loading related skills: $e');
      setState(() {
        _isLoadingRelatedSkills = false;
      });
    }
  }

  Future<void> _toggleUserSkill() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      bool success;

      if (_isUserSkill) {
        // Remove skill
        success = await userProvider.removeSkill(_currentSkill.id);
        if (success) {
          await userProvider.loadUser();
          if (mounted) {
            _updateUserState();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skill removed from your profile')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to remove skill')),
            );
          }
        }
      } else {
        // Add skill
        success = await userProvider.addSkill(_currentSkill.id, 'Beginner');
        if (success) {
          await userProvider.loadUser();
          if (mounted) {
            _updateUserState();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Skill added to your profile')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add skill')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling skill: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  Future<void> _loadSkillProgress() async {
    try {
      setState(() => _isLoading = true);
      final progressService =
          ProgressService(apiClient: ApiClient(baseUrl: AppConfig.apiBaseUrl));
      final response =
          await progressService.fetchSkillProgress(widget.skill.id);

      if (mounted) {
        setState(() {
          print('[DEBUG] Full API response: ${response.data}');
          if (response.success && response.data != null) {
            final data = response.data!;
            if (data.containsKey('skillProgress')) {
              final skillProgressList = data['skillProgress'];

              print(
                  '[DEBUG] Type of skillProgressList: ${skillProgressList.runtimeType}');
              print(
                  '[DEBUG] Contents of skillProgressList: $skillProgressList');

              final matchingSkill = (skillProgressList as List)
                  .cast<Map<String, dynamic>>()
                  .firstWhere(
                (sp) {
                  print(
                      '[DEBUG] Checking skillId: ${sp['skillId']} vs widget.skill.id: ${widget.skill.id}');
                  return sp['skillId'] == widget.skill.id;
                },
                orElse: () {
                  print('[DEBUG] No matching skill progress found');
                  return {};
                },
              );

              if (matchingSkill.isNotEmpty) {
                print('[DEBUG] Matching skill data: $matchingSkill');
                _skillProgress =
                    (matchingSkill['completionPercentage'] ?? 0).toDouble();
                _practiceTimeMinutes =
                    matchingSkill['practiceTimeMinutes'] ?? 0;
                _assessmentScore = matchingSkill['assessmentScore'];
                print(
                    '[DEBUG] Updated progress values: $_skillProgress%, $_practiceTimeMinutes min');
              } else {
                print('[DEBUG] Empty matching skill data, setting defaults');
                _skillProgress = 0.0;
                _practiceTimeMinutes = 0;
                _assessmentScore = null;
              }
            } else {
              print('[DEBUG] skillProgress key not found in response data');
              print('[DEBUG] Available keys: ${data.keys.toList()}');
              _skillProgress = 0.0;
              _practiceTimeMinutes = 0;
              _assessmentScore = null;
            }
          } else {
            print('[DEBUG] Response error: ${response.error}');
            print('[DEBUG] Response success: ${response.success}');
            _skillProgress = 0.0;
            _practiceTimeMinutes = 0;
            _assessmentScore = null;
          }
          _isLoading = false;
        });
      }
    } catch (e, st) {
      print('[ERROR] Exception while loading skill progress: $e\n$st');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _skillProgress = 0.0;
          _practiceTimeMinutes = 0;
          _assessmentScore = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isCreator = userProvider.user?.id == _currentSkill.createdBy?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSkill.name),
        actions: [
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSkillScreen(
                      skill: _currentSkill,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip

                  // Creator Information Card
                  _buildCreatorCard(),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentSkill.categoryName,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skill name
                  Text(
                    _currentSkill.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  Divider(height: 15),

                  // Progress section - only show for users who added the skill (not creator)
                  if (_isUserSkill && !isCreator) ...[
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                  ],

                  // Description section
                  const SizedBox(height: 8),
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),

                  // Difficulty section
                  _buildDifficultySection(),
                  const SizedBox(height: 24),

                  // Resources section
                  const SectionHeader(title: 'Learning Resources'),
                  const SizedBox(height: 16),
                  _buildResourcesSection(),

                  // Add Resource button
                  if (isCreator)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddResourceScreen(
                                  skill: _currentSkill,
                                ),
                              ),
                            ).then((_) => _loadData());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Resource'),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Reviews section and Add Review button (conditional)
                  // Add Comment and Rate button (only for non-creators who added the skill)
                  if (_isUserSkill && !isCreator)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showAddReviewDialog();
                          },
                          icon: const Icon(Icons.comment_outlined),
                          label: const Text('Add Comment and Rate'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Skill Reviews Section
                  const SectionHeader(title: 'Reviews'),
                  const SizedBox(height: 8),
                  _buildReviewsSection(),
                  const SizedBox(height: 24),

                  // Add to profile or Edit button (conditional)
                  if (!isCreator && !_isUserSkill)
                    Center(
                      child: CustomButton(
                        text: 'Add to My Skills',
                        onPressed: _toggleUserSkill,
                        isLoading: _isAddingToProfile,
                        type: ButtonType.primary,
                        icon: Icons.add,
                      ),
                    ),
                  if (!isCreator && _isUserSkill)
                    Center(
                      child: CustomButton(
                        text: 'Remove from My Skills',
                        onPressed: _toggleUserSkill,
                        isLoading: _isAddingToProfile,
                        type: ButtonType.secondary,
                        icon: Icons.remove,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Related Skills section
                  _buildRelatedSkillsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completion'),
                Text('${_skillProgress.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _skillProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Practice Time'),
                Text('${(_practiceTimeMinutes / 60).toStringAsFixed(1)} hours'),
              ],
            ),
            if (_assessmentScore != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assessment Score'),
                  Text('${_assessmentScore!.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          _currentSkill.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Difficulty Level',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getDifficultyColor(_currentSkill.difficultyLevel)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentSkill.difficultyLevel.toUpperCase(),
            style: TextStyle(
              color: _getDifficultyColor(_currentSkill.difficultyLevel),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildResourcesSection() {
    if (_resources.isEmpty) {
      return const Center(
        child: Text('No resources available for this skill yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _resources.length,
          itemBuilder: (context, index) {
            final resource = _resources[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                  leading: Icon(_getResourceIcon(resource.type)),
                  title: Text(resource.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.description),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${resource.type}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ResourceDetailScreen(resource: resource)));
                  }),
            );
          },
        ),
      ],
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'article':
        return Icons.article;
      case 'link':
        return Icons.link;
      default:
        return Icons.link;
    }
  }

  void _toggleCompletion() {
    setState(() {
      _isCompleted = !_isCompleted;
      if (_isCompleted) {
        _progress = 1.0;
      }
    });
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviewsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading reviews: $_reviewsError',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Center(
        child: Text('No reviews yet.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        // Get current user ID to check ownership
        final currentUserId =
            Provider.of<UserProvider>(context, listen: false).user?.id;
        final isMyReview = review.userId == currentUserId;

        return SkillReviewCard(
          userName: review.userName,
          rating: review.rating,
          comment: review.comment,
          createdAt: review.createdAt,
          onEdit: isMyReview
              ? () {
                  // Only allow edit if it's my review
                  _showEditReviewDialog(review);
                }
              : null,
          onDelete: isMyReview
              ? () {
                  // Only allow delete if it's my review
                  _showDeleteReviewDialog(review);
                }
              : null,
        );
      },
    );
  }

  // Show dialog to add a new review
  void _showAddReviewDialog() {
    int selectedRating = 5; // Default rating
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Your Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your Rating:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Your Comment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isEmpty || selectedRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rating and a comment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final response = await _skillReviewService.addReview(
                    skillId: _currentSkill.id,
                    rating: selectedRating,
                    comment: commentController.text,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (response['success'] == true) {
                      _loadReviews(); // Reload reviews after adding
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Review added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response['error'] ?? 'Failed to add review',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Dismiss the dialog on error
                    print('Error submitting review: $e'); // Log the error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('An error occurred: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // Show dialog to edit an existing review
  void _showEditReviewDialog(SkillReview reviewToEdit) {
    int selectedRating = reviewToEdit.rating; // Initial rating
    final commentController =
        TextEditingController(text: reviewToEdit.comment); // Initial comment

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Your Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your Rating:'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Your Comment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.isEmpty || selectedRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please provide a rating and a comment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final response = await _skillReviewService.updateReview(
                  skillId: _currentSkill.id,
                  reviewId: reviewToEdit.id,
                  rating: selectedRating,
                  comment: commentController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (response['success'] == true) {
                    _loadReviews(); // Reload reviews after editing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response['error'] ?? 'Failed to update review',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog to delete a review
  void _showDeleteReviewDialog(SkillReview reviewToDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await _skillReviewService.deleteReview(
                skillId: _currentSkill.id,
                reviewId: reviewToDelete.id,
              );

              if (mounted) {
                Navigator.pop(context);
                if (response['success'] == true) {
                  _loadReviews(); // Reload reviews after deleting
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response['error'] ?? 'Failed to delete review',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red), // Red color for delete button
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Build the creator information card
  Widget _buildCreatorCard() {
    final creator = _currentSkill.createdBy;

    // Only show the card if creator information is available
    if (creator == null) {
      return Container(); // Return empty container if creator is null
    }

    // Assuming creator is a User object with name and profilePicture
    final creatorName = creator.name ?? 'Unknown Creator';
    final creatorProfilePicture =
        creator.profilePicture; // Assuming this field exists on the User model

    // The proficiency level of the skill itself when created, not the user's proficiency
    final skillCreatorProficiency =
        _currentSkill.difficultyLevel; // Assuming this is stored in skill model

    return GestureDetector(
      onTap: () {
        // Navigate to creator's public profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfileScreen(userId: creator.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.zero, // Adjust margin as needed
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Profile Picture or initial
              CircleAvatar(
                radius: 20,
                backgroundImage: (creatorProfilePicture != null &&
                        creatorProfilePicture.isNotEmpty)
                    ? NetworkImage(creatorProfilePicture)
                    : null,
                child: (creatorProfilePicture == null ||
                        creatorProfilePicture.isEmpty)
                    ? Text(
                        creatorName.isNotEmpty
                            ? creatorName[0].toUpperCase()
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Created By',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      creatorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Creator's proficiency in THIS skill (from skill document)
                    Text(
                      'Proficiency: ${_currentSkill.difficultyLevel.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Optional: Add an arrow or icon indicating tappability
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Build the related skills section
  Widget _buildRelatedSkillsSection() {
    if (_isLoadingRelatedSkills) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_relatedSkills.isEmpty) {
      return Container(); // Don't show the section if there are no related skills
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Related Skills'),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _relatedSkills.length,
          itemBuilder: (context, index) {
            final skill = _relatedSkills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(skill.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.description),
                    const SizedBox(height: 4),
                    Text(
                      'Difficulty: ${skill.difficultyLevel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SkillDetailScreen(skill: skill),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

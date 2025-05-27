import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skill_sharing_app/widget/custome_button.dart';
import 'package:skill_sharing_app/widget/section_header.dart';
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_config.dart';
import 'package:skill_sharing_app/services/api_client.dart';

class ResourceDetailScreen extends StatefulWidget {
  final Resource resource;

  const ResourceDetailScreen({
    Key? key,
    required this.resource,
  }) : super(key: key);

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  late Resource _resource;
  bool _isLoading = false;
  bool _isMarkingComplete = false;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  bool _isSubmittingReview = false;
  final _reviewController = TextEditingController();
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _resource = widget.resource;
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final resourceService = ResourceService();
      final response = await resourceService.getResourceById(_resource.id);
      if (response.success && response.data != null) {
        setState(() {
          _resource = response.data!;
          _reviews = response.data!.reviews ?? [];
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  bool isCompletedByCurrentUser(Resource resource, String userId) {
    return resource.completions.any((c) => c.user == userId);
  }

  Future<void> _toggleResourceCompleted() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to mark resources as completed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isMarkingComplete = true;
    });

    try {
      final progressProvider = context.read<ProgressProvider>();
      final isCompleted = isCompletedByCurrentUser(_resource, userId);

      // Call the appropriate method based on current state
      if (isCompleted) {
        await progressProvider.unmarkResourceComplete(
          _resource.skill.id,
          _resource.id,
        );
      } else {
        await progressProvider.markResourceCompleted(
          _resource.skill.id,
          _resource.id,
        );
      }

      // Refresh the resource to get updated completion status
      final resourceService = ResourceService();
      final response = await resourceService.getResourceById(_resource.id);

      if (response.success && response.data != null) {
        setState(() {
          _resource = response.data!;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCompleted
                ? 'Resource unmarked as completed'
                : 'Resource marked as completed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(response.error ?? 'Failed to refresh resource status');
      }
    } catch (e) {
      debugPrint('Error toggling resource completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingComplete = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingReview = true;
    });

    try {
      final resourceService = ResourceService();
      final response = await resourceService.submitReview(
        _resource.id,
        _selectedRating,
        _reviewController.text,
      );

      if (response.success) {
        _reviewController.clear();
        setState(() {
          _selectedRating = 0;
        });
        await _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error ?? 'Failed to submit review'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmittingReview = false;
      });
    }
  }

  Widget _buildResourcePreview() {
    if (_resource.fileUrl != null) {
      // Construct the full image URL
      final imageUrl = '${AppConfig.apiBaseUrl}${_resource.fileUrl}';

      // Handle file preview based on type
      switch (_resource.type.toLowerCase()) {
        case 'image':
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text('Failed to load image'),
              );
            },
          );
        case 'pdf':
          return const Center(
            child: Text('PDF Preview - Coming Soon'),
          );
        case 'video':
          return const Center(
            child: Text('Video Preview - Coming Soon'),
          );
        default:
          return const Center(
            child: Text('File Preview - Coming Soon'),
          );
      }
    } else if (_resource.link.isNotEmpty) {
      return InkWell(
        onTap: () => _launchUrl(_resource.link),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.link),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _resource.link,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildReviewForm() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write a Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    Icons.star,
                    color: index < _selectedRating
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitReview,
                child: _isSubmittingReview
                    ? const CircularProgressIndicator()
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewForm(),
        if (_reviews.isEmpty)
          const Center(
            child: Text('No reviews yet'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(review.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color: index < review.rating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                      if (review.comment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(review.comment),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;
    final isCompleted =
        userId != null && isCompletedByCurrentUser(_resource, userId);
    final authProvider = context.watch<AuthProvider>();

    // Show a loading indicator if auth data is still loading or user is null
    if (authProvider.isLoading || authProvider.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_resource.title),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_resource.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resource type chip
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
                      _resource.type,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resource preview
                  _buildResourcePreview(),
                  const SizedBox(height: 24),

                  // Description
                  const SectionHeader(title: 'Description'),
                  const SizedBox(height: 8),
                  Text(_resource.description),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.person,
                        'Added by ${_resource.addedBy['name']}',
                      ),
                      _buildStatItem(
                        Icons.calendar_today,
                        timeago.format(_resource.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add the button above the reviews section
                  if (userId != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isMarkingComplete
                              ? null
                              : _toggleResourceCompleted,
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: isCompleted
                                ? Colors.white
                                : null, // Adjust color for button background
                          ),
                          label: Text(
                            isCompleted
                                ? 'Unmark as Completed'
                                : 'Mark as Completed',
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.white
                                  : null, // Adjust color for button background
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted
                                ? Colors.lightGreen
                                : Theme.of(context)
                                    .primaryColor, // Adjust button background color
                            foregroundColor: isCompleted
                                ? Colors.white
                                : null, // Adjust text/icon color
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Reviews section
                  const SectionHeader(title: 'Reviews'),
                  const SizedBox(height: 16),
                  _buildReviewsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

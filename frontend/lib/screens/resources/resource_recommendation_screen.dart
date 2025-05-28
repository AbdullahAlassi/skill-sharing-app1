import 'package:flutter/material.dart';
import 'package:skill_sharing_app/screens/skills/skill_detail_screen.dart';
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import 'resource_detail_screen.dart';

class ResourceRecommendationScreen extends StatefulWidget {
  final String? skillId;
  final String? category;
  final List<String>? tags;

  const ResourceRecommendationScreen({
    Key? key,
    this.skillId,
    this.category,
    this.tags,
  }) : super(key: key);

  @override
  _ResourceRecommendationScreenState createState() =>
      _ResourceRecommendationScreenState();
}

class _ResourceRecommendationScreenState
    extends State<ResourceRecommendationScreen> {
  final ResourceService _resourceService = ResourceService();
  List<Resource> _resources = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendedResources();
  }

  Future<void> _loadRecommendedResources() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('[DEBUG] Starting to load recommended resources');
      final response =
          await _resourceService.getResourcesByFavoriteCategories();
      print(
          '[DEBUG] Response received: success=${response.success}, error=${response.error}');
      print('[DEBUG] Response data: ${response.data?.length ?? 0} resources');

      if (response.success) {
        setState(() {
          _resources = response.data ?? [];
          _isLoading = false;
        });
        print(
            '[DEBUG] Resources loaded successfully: ${_resources.length} resources');
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load recommended resources';
          _isLoading = false;
        });
        print('[DEBUG] Failed to load resources: $_error');
      }
    } catch (e) {
      print('[DEBUG] Exception while loading resources: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Resources'),
      ),
      body: RecommendedResourcesWidget(
        resources: _resources,
        isLoading: _isLoading,
        error: _error,
        onRefresh: _loadRecommendedResources,
      ),
    );
  }
}

class RecommendedResourcesWidget extends StatelessWidget {
  final List<Resource> resources;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  const RecommendedResourcesWidget({
    Key? key,
    required this.resources,
    required this.isLoading,
    this.error,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (resources.isEmpty) {
      return const Center(
        child: Text('No recommended resources found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: resources.length,
        itemBuilder: (context, index) {
          return _buildResourceCard(context, resources[index]);
        },
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, Resource resource) {
    return Container(
      width: 400,
      height: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SkillDetailScreen(skill: resource.skill),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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

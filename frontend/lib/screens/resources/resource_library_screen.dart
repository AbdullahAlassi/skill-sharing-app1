import 'package:flutter/material.dart';
import 'package:skill_sharing_app/screens/resources/add_resource_screen.dart';
import 'package:skill_sharing_app/screens/resources/resource_detail_screen.dart';
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ResourceLibraryScreen extends StatefulWidget {
  final String skillId;

  const ResourceLibraryScreen({
    Key? key,
    required this.skillId,
  }) : super(key: key);

  @override
  _ResourceLibraryScreenState createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen>
    with SingleTickerProviderStateMixin {
  final ResourceService _resourceService = ResourceService();
  List<Resource> _mySkillsResources = [];
  List<Resource> _createdSkillsResources = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedType;
  String _sortBy = 'createdAt';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load resources from user's skills
      final mySkillsResponse = await _resourceService.getResourcesByUserSkills(
        type: _selectedType,
        sort: _sortBy,
      );

      // Load resources from user's created skills
      final createdSkillsResponse =
          await _resourceService.getResourcesByCreatedSkills(
        type: _selectedType,
        sort: _sortBy,
      );

      if (mySkillsResponse.success && createdSkillsResponse.success) {
        setState(() {
          _mySkillsResources = mySkillsResponse.data ?? [];
          _createdSkillsResources = createdSkillsResponse.data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = mySkillsResponse.error ??
              createdSkillsResponse.error ??
              'Failed to load resources';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _flagResource(String resourceId) async {
    try {
      await _resourceService.flagResource(resourceId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource flagged for moderation')),
      );
      _loadResources();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error flagging resource: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteResource(String resourceId) async {
    try {
      await _resourceService.deleteResource(resourceId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully')),
      );
      _loadResources();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting resource: ${e.toString()}')),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Resource Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedType == null,
                    onSelected: (selected) {
                      setState(() => _selectedType = null);
                    },
                  ),
                  ...Resource.types.map(
                    (type) => FilterChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (selected) {
                        setState(() => _selectedType = selected ? type : null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadResources();
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceList(List<Resource> resources) {
    if (resources.isEmpty) {
      return const Center(child: Text('No resources found'));
    }

    return ListView.builder(
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            title: Text(resource.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(resource.type),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(resource.skill.name),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Added by: ${resource.addedBy['name']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ResourceDetailScreen(resource: resource),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[200],
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Skills Resources'),
            Tab(text: 'Created Skills Resources'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResourceList(_mySkillsResources),
                    _buildResourceList(_createdSkillsResources),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/screens/skills/skill_detail_screen.dart';
import '../../models/skill_category.dart';
import '../../providers/skill_provider.dart';

class CategorySkillsScreen extends StatefulWidget {
  final SkillCategory category;

  const CategorySkillsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategorySkillsScreen> createState() => _CategorySkillsScreenState();
}

class _CategorySkillsScreenState extends State<CategorySkillsScreen> {
  @override
  void initState() {
    super.initState();
    final categoryId = widget.category.id;
    print(
        '[DEBUG] CategorySkillsScreen init for category: ${widget.category.name} (${categoryId})');

    Future.microtask(() async {
      final provider = Provider.of<SkillProvider>(context, listen: false);
      print('[DEBUG] Starting fetch for category ID: $categoryId');
      await provider.fetchSkillsByCategory(categoryId);
      print(
          '[DEBUG] Fetch completed. Skills count in provider: ${provider.skills.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: Consumer<SkillProvider>(
        builder: (context, skillProvider, child) {
          print(
              '[DEBUG] Rendering CategorySkillsScreen for category ID: ${widget.category.id}');
          print('[DEBUG] Provider error: ${skillProvider.error}');
          print('[DEBUG] Provider isLoading: ${skillProvider.isLoading}');
          print(
              '[DEBUG] Total skills from provider: ${skillProvider.skills.length}');

          if (skillProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (skillProvider.error != null) {
            print('[DEBUG] Error state: ${skillProvider.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${skillProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print(
                          '[DEBUG] Retrying fetch for category ID: ${widget.category.id}');
                      skillProvider.fetchSkillsByCategory(widget.category.id);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Log each skill's category for debugging
          print('[DEBUG] Skills in provider:');
          for (var skill in skillProvider.skills) {
            print('- Skill: ${skill.name}, Category: ${skill.category}');
          }

          final skills = skillProvider.skills
              .where((skill) => skill.category == widget.category.id)
              .toList();

          print('[DEBUG] Filtered skills for category: ${skills.length}');

          if (skills.isEmpty) {
            print(
                '[DEBUG] No skills found for category: ${widget.category.name}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No skills found in ${widget.category.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to add a skill!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: skills.length,
            itemBuilder: (context, index) {
              final skill = skills[index];
              print('[DEBUG] Building skill card for: ${skill.name}');
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(skill.name[0].toUpperCase()),
                  ),
                  title: Text(skill.name),
                  subtitle: Text(skill.description),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                SkillDetailScreen(skill: skill)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

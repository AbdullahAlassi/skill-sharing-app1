import 'package:flutter/material.dart';
import '../models/skill_model.dart';
import '../theme/app_theme.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final VoidCallback onTap;

  const SkillCard({Key? key, required this.skill, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(skill.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  skill.category,
                  style: TextStyle(
                    color: _getCategoryColor(skill.category),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Skill name
              Text(
                skill.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Skill description
              Expanded(
                child: Text(
                  skill.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Colors.blue;
      case 'design':
        return Colors.purple;
      case 'marketing':
        return Colors.green;
      case 'art':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/skill_provider.dart';
import '../../services/progress_service.dart';
import '../../models/skill_model.dart';
import '../../models/goal_model.dart';
import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../providers/progress_provider.dart';

class SetGoalScreen extends StatefulWidget {
  const SetGoalScreen({Key? key}) : super(key: key);

  @override
  _SetGoalScreenState createState() => _SetGoalScreenState();
}

class _SetGoalScreenState extends State<SetGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  Skill? _selectedSkill;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));
  late ProgressService _progressService;

  @override
  void initState() {
    super.initState();
    _progressService =
        ProgressService(apiClient: ApiClient(baseUrl: AppConfig.apiBaseUrl));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillProvider>(context, listen: false).loadSkills();
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(const Duration(days: 365 * 5)), // 5 years from now
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _createGoal() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSkill == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a skill')),
        );
        return;
      }

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Creating goal...', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.blueGrey,
            duration: Duration(seconds: 1)),
      );

      final response = await _progressService.createGoal(
        skillId: _selectedSkill!.id,
        targetDate: _targetDate,
      );

      if (response['success']) {
        // Refresh progress data in ProgressProvider
        await Provider.of<ProgressProvider>(context, listen: false)
            .fetchUserProgress();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Goal created successfully!',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create goal: ${response['error']}',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Learning Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<SkillProvider>(
                builder: (context, skillProvider, child) {
                  if (skillProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (skillProvider.skills.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No skills found. Please add a skill first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    );
                  }
                  return DropdownButtonFormField<Skill>(
                    decoration: const InputDecoration(
                      labelText: 'Skill',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedSkill,
                    items: skillProvider.skills.map((skill) {
                      return DropdownMenuItem<Skill>(
                        value: skill,
                        child: Text(skill.name),
                      );
                    }).toList(),
                    onChanged: (Skill? newValue) {
                      setState(() {
                        _selectedSkill = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a skill' : null,
                  );
                },
              ),
              const SizedBox(height: 16.0),
              ListTile(
                title: const Text('Target Completion Date'),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd').format(_targetDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDate(context),
              ),
              // Optional: Text field for goal description
              // TextFormField(
              //   decoration: const InputDecoration(
              //     labelText: 'Goal Description (Optional)',
              //     border: OutlineInputBorder(),
              //   ),
              // ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _createGoal,
                child: const Text('Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

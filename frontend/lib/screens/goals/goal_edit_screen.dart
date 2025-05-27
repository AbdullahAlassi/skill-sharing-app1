import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/models/goal_model.dart';
import 'package:skill_sharing_app/providers/progress_provider.dart';

class GoalEditScreen extends StatefulWidget {
  final GoalModel goal;

  const GoalEditScreen({Key? key, required this.goal}) : super(key: key);

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  late double _currentProgress;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentProgress = widget.goal.currentProgress;
  }

  Future<void> _updateGoal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await context.read<ProgressProvider>().updateGoal(
            goalId: widget.goal.id,
            currentProgress: _currentProgress,
          );

      if (result['success']) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to update goal';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Skill: ${widget.goal.skill.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Current Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _currentProgress,
              min: 0,
              max: 100,
              divisions: 100,
              label: '${_currentProgress.round()}%',
              onChanged: (value) {
                setState(() {
                  _currentProgress = value;
                });
              },
            ),
            Text(
              '${_currentProgress.round()}%',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateGoal,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Update Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

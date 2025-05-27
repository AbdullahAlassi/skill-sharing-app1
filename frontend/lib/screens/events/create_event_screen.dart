import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/widget/custome_button.dart';
import '../../models/skill_model.dart';
import '../../services/event_service.dart';
import '../../services/skill_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _selectedEndDate;
  bool _isVirtual = true;
  List<String> _selectedSkills = [];
  List<Skill> _userSkills = [];
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadUserSkills();
    }
  }

  void _showSnackBar(String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  Future<void> _loadUserSkills() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null) {
        _showSnackBar('Please login to create an event');
        Navigator.pop(context);
        return;
      }

      final skillService = SkillService();
      final response = await skillService.getUserSkills(currentUser.id);

      if (response.success && response.data != null) {
        setState(() {
          _userSkills = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(response.error ?? 'Failed to load skills');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isEndDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isEndDate) {
            _selectedEndDate = selectedDateTime;
          } else {
            _selectedDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final eventService = EventService();
      final response = await eventService.createEvent(
        _titleController.text,
        _descriptionController.text,
        _selectedDate!,
        _selectedEndDate,
        _locationController.text,
        _isVirtual,
        _meetingLinkController.text,
        _selectedSkills,
        int.tryParse(_maxParticipantsController.text),
      );

      if (response.success && mounted) {
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to create event')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
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
        title: const Text('Create Event'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                              _selectedDate == null
                                  ? 'Select Date & Time'
                                  : DateFormat(
                                      'MMM d, y • h:mm a',
                                    ).format(_selectedDate!),
                            ),
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // End Date (Optional)
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                              _selectedEndDate == null
                                  ? 'Select End Date & Time (Optional)'
                                  : DateFormat(
                                      'MMM d, y • h:mm a',
                                    ).format(_selectedEndDate!),
                            ),
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        if (_selectedEndDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _selectedEndDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Virtual Event Toggle
                    SwitchListTile(
                      title: const Text('Virtual Event'),
                      value: _isVirtual,
                      onChanged: (value) {
                        setState(() {
                          _isVirtual = value;
                        });
                      },
                    ),

                    // Meeting Link (if virtual)
                    if (_isVirtual) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _meetingLinkController,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Link',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Max Participants
                    TextFormField(
                      controller: _maxParticipantsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Participants (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Create Button
                    CustomButton(
                      text: 'Create Event',
                      onPressed: _createEvent,
                      isLoading: _isLoading,
                      type: ButtonType.primary,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/widget/custome_button.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Event _event;
  bool _isRegistered = false;
  bool _isLoading = false;
  bool _isOrganizer = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _checkRegistrationStatus();
  }

  void _updateRegistrationStatus(Event event) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    if (currentUserId != null) {
      final isUserRegistered =
          event.participants.any((p) => p.userId == currentUserId);
      final isOrganizer = event.organizerId == currentUserId;

      print('[DEBUG] Updating registration status:');
      print('- Current user ID: $currentUserId');
      print(
          '- Event participants: ${event.participants.map((p) => p.userId).toList()}');
      print('- Is user registered: $isUserRegistered');
      print('- Is organizer: $isOrganizer');

      setState(() {
        _event = event;
        _isRegistered = isUserRegistered;
        _isOrganizer = isOrganizer;
      });
    }
  }

  Future<void> _checkRegistrationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventService = EventService();
      final response = await eventService.getEventById(_event.id);

      if (response.success && response.data != null) {
        _updateRegistrationStatus(response.data!);
      } else {
        print('[DEBUG] Failed to fetch event status: ${response.error}');
      }
    } catch (e) {
      print('[DEBUG] Error checking registration status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleRegistration() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final eventService = EventService();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign in to register for events'),
            action: SnackBarAction(
              label: 'Sign In',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ),
        );
        return;
      }

      if (_isRegistered) {
        print('[DEBUG] Attempting to unregister from event: ${_event.id}');
        final response = await eventService.unregisterFromEvent(_event.id);

        if (response.success && response.data != null && mounted) {
          print('[DEBUG] Unregistration successful, updating UI state');

          // Immediately update local state
          setState(() {
            _event.participants.removeWhere((p) => p.userId == currentUserId);
            _isRegistered = false;
          });

          print(
              '[DEBUG] Participants after manual removal: ${_event.participants.map((p) => p.userId).toList()}');
          print('[DEBUG] isRegistered: $_isRegistered');

          // Update with server data
          _updateRegistrationStatus(response.data!);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully unregistered from event'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('[DEBUG] Unregistration failed: ${response.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response.error ?? 'Failed to unregister from event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('[DEBUG] Attempting to register for event: ${_event.id}');
        final response = await eventService.registerForEvent(_event.id);

        if (response.success && response.data != null && mounted) {
          print('[DEBUG] Registration successful, updating UI state');

          // Immediately update local state
          setState(() {
            _event = response.data!;
            _isRegistered = true;
          });

          print(
              '[DEBUG] Updated event participants: ${_event.participants.map((p) => p.userId).toList()}');
          print('[DEBUG] isRegistered: $_isRegistered');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully registered for event'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print('[DEBUG] Registration failed: ${response.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'Failed to register for event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[DEBUG] Error in _toggleRegistration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration:
                        BoxDecoration(gradient: AppTheme.primaryGradient),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _event.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(_event.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _event.isVirtual
                                  ? Icons.videocam
                                  : Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _event.location,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Event details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Organizer
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const CircleAvatar(child: Icon(Icons.person)),
                          title: const Text('Organized by'),
                          subtitle: Text(
                            _event.organizerName ?? 'Unknown organizer',
                          ),
                        ),

                        const Divider(),

                        // Description
                        const Text(
                          'About this event',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_event.description),

                        const SizedBox(height: 24),

                        // Related Skills
                        if (_event.relatedSkills.isNotEmpty) ...[
                          const Text(
                            'Related Skills',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _event.relatedSkills
                                .map((skill) => Chip(label: Text(skill)))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Registration status
                        if (_event.maxParticipants != null) ...[
                          const Text(
                            'Registration Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_event.participants.length}/${_event.maxParticipants} participants',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Action buttons
                        if (!_isOrganizer) ...[
                          CustomButton(
                            text: _isRegistered
                                ? 'Cancel Registration'
                                : 'Register for Event',
                            onPressed: _event.isFull && !_isRegistered
                                ? () {}
                                : () => _toggleRegistration(),
                            isLoading: _isLoading,
                            type: _isRegistered
                                ? ButtonType.secondary
                                : ButtonType.primary,
                          ),
                          if (_event.isFull && !_isRegistered)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'This event is full',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Edit Event',
                                  onPressed: () {
                                    // TODO: Navigate to edit event screen
                                  },
                                  type: ButtonType.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomButton(
                                  text: 'Delete Event',
                                  onPressed: () {
                                    // TODO: Show delete confirmation dialog
                                  },
                                  type: ButtonType.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

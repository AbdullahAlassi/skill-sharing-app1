import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import 'package:frontend/widget/custome_button.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isRegistered = false;
  bool _isLoading = false;
  bool _isOrganizer = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.user?.id;

    setState(() {
      _isRegistered = widget.event.participants.any(
        (p) => p.userId == currentUserId,
      );
      _isOrganizer = widget.event.organizerId == currentUserId;
    });
  }

  Future<void> _toggleRegistration() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final eventService = EventService();

      if (_isRegistered) {
        // Unregister from event
        final response = await eventService.unregisterFromEvent(
          widget.event.id,
        );

        if (response.success && mounted) {
          setState(() {
            _isRegistered = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully unregistered from event'),
            ),
          );
        }
      } else {
        // Register for event
        final response = await eventService.registerForEvent(widget.event.id);

        if (response.success && mounted) {
          setState(() {
            _isRegistered = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully registered for event')),
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
    final dateFormat = DateFormat('EEEE, MMMM d, y • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                        dateFormat.format(widget.event.date),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        widget.event.isVirtual
                            ? Icons.videocam
                            : Icons.location_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.event.location,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: const Text('Organized by'),
                    subtitle: Text(
                      widget.event.organizerName ?? 'Unknown organizer',
                    ),
                  ),

                  const Divider(),

                  // Description
                  const Text(
                    'About this event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.event.description),

                  const SizedBox(height: 24),

                  // Related Skills
                  if (widget.event.relatedSkills.isNotEmpty) ...[
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
                      children: widget.event.relatedSkills
                          .map((skill) => Chip(label: Text(skill)))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Registration status
                  if (widget.event.maxParticipants != null) ...[
                    const Text(
                      'Registration Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.event.participants.length}/${widget.event.maxParticipants} participants',
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
                      onPressed:
                          widget.event.isFull ? () {} : _toggleRegistration,
                      isLoading: _isLoading,
                      type: _isRegistered
                          ? ButtonType.secondary
                          : ButtonType.primary,
                    ),
                    if (widget.event.isFull && !_isRegistered)
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/custome_button.dart';
import 'package:frontend/widget/section_header.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isLoading = false;
  bool _isRegistered = false;
  List<Participant> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call to get event details
    setState(() {
      _isRegistered = widget.event.isUserRegistered;
      _participants = widget.event.participants;
      _isLoading = false;
    });
  }

  Future<void> _toggleRegistration() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call to register/unregister
    setState(() {
      _isRegistered = !_isRegistered;

      if (_isRegistered) {
        // Add current user to participants
        _participants.add(
          Participant(
            userId: 'currentUserId', // Replace with actual user ID
            userName: 'Current User', // Replace with actual user name
            registeredAt: DateTime.now(),
          ),
        );
      } else {
        // Remove current user from participants
        _participants.removeWhere((p) => p.userId == 'currentUserId');
      }

      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventHeader(),
                          const SizedBox(height: 24),
                          _buildEventDetails(),
                          const SizedBox(height: 24),
                          _buildOrganizerSection(),
                          const SizedBox(height: 24),
                          _buildRelatedSkillsSection(),
                          const SizedBox(height: 24),
                          _buildParticipantsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.event.title,
          style: const TextStyle(color: Colors.white),
        ),
        background:
            widget.event.image != null
                ? Image.network(widget.event.image!, fit: BoxFit.cover)
                : Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Center(
                    child: Icon(
                      widget.event.isVirtual ? Icons.videocam : Icons.event,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Share event
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border, color: Colors.white),
          onPressed: () {
            // Save event
          },
        ),
      ],
    );
  }

  Widget _buildEventHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event date and time
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              _formatDate(widget.event.date),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Event title
        Text(
          widget.event.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),

        // Event location
        Row(
          children: [
            Icon(
              widget.event.isVirtual ? Icons.videocam : Icons.location_on,
              size: 20,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.event.location,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),

        // Meeting link for virtual events
        if (widget.event.isVirtual && widget.event.meetingLink != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.link, size: 20, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.event.meetingLink!,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Registration status
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                _isRegistered
                    ? AppTheme.successColor.withOpacity(0.1)
                    : widget.event.isFull
                    ? AppTheme.errorColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _isRegistered
                ? 'You are registered'
                : widget.event.isFull
                ? 'Event is full'
                : 'Registration open',
            style: TextStyle(
              color:
                  _isRegistered
                      ? AppTheme.successColor
                      : widget.event.isFull
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'About This Event'),
        const SizedBox(height: 8),
        Text(
          widget.event.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        // Additional details
        if (widget.event.maxParticipants != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.people, size: 20, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                'Maximum participants: ${widget.event.maxParticipants}',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],

        // End date if available
        if (widget.event.endDate != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.event_available,
                size: 20,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Ends on: ${_formatDate(widget.event.endDate!)}',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOrganizerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Organizer'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: const Icon(Icons.person, color: AppTheme.primaryColor),
          ),
          title: Text(
            widget.event.organizerName ?? 'Unknown Organizer',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: const Text('Event Organizer'),
          trailing: IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () {
              // Message organizer
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedSkillsSection() {
    // If no related skills, don't show this section
    if (widget.event.relatedSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Related Skills'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              widget.event.relatedSkills.map((skillId) {
                // TODO: Replace with actual skill data
                return Chip(
                  label: Text('Skill $skillId'),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Participants',
          subtitle: '${_participants.length} people registered',
        ),
        const SizedBox(height: 8),
        _participants.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Be the first to register!',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            )
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length > 5 ? 5 : _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage:
                        participant.userProfilePicture != null
                            ? NetworkImage(participant.userProfilePicture!)
                            : null,
                    child:
                        participant.userProfilePicture == null
                            ? const Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                            )
                            : null,
                  ),
                  title: Text(
                    participant.userName ?? 'Anonymous User',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Registered on ${_formatShortDate(participant.registeredAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
        if (_participants.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Show all participants
              },
              icon: const Icon(Icons.people),
              label: Text('See all ${_participants.length} participants'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Share button
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                // Share event
              },
            ),
            const SizedBox(width: 8),

            // Save button
            IconButton(
              icon: const Icon(Icons.bookmark_border_outlined),
              onPressed: () {
                // Save event
              },
            ),
            const SizedBox(width: 16),

            // Register/Unregister button
            Expanded(
              child: CustomButton(
                text: _isRegistered ? 'Cancel Registration' : 'Register Now',
                onPressed:
                    widget.event.isFull && !_isRegistered
                        ? null
                        : () {
                          _toggleRegistration(); // Wrap the async call in a synchronous function
                        },
                isLoading: _isLoading,
                type: _isRegistered ? ButtonType.secondary : ButtonType.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    return formatter.format(date);
  }

  String _formatShortDate(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_sharing_app/widget/event_card.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  List<Event> _allEvents = [];
  List<Event> _myEvents = [];
  List<Event> _registeredEvents = [];
  List<Event> _pastEvents = [];
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventService = EventService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.user?.id?.trim();
      final now = DateTime.now();

      print('Loading events for user: $currentUserId');
      print('Current time: $now');

      // Load all events
      final allEventsResponse = await eventService.getEvents();
      print('All events response: ${allEventsResponse.success}');
      if (allEventsResponse.data != null) {
        print('Number of events received: ${allEventsResponse.data!.length}');
      }

      if (!mounted) return;

      if (allEventsResponse.success && allEventsResponse.data != null) {
        setState(() {
          // Filter events based on date and exclude user's created events
          _allEvents = allEventsResponse.data!.where((event) {
            final isUpcoming = event.date.isAfter(now);
            final eventOrganizerId = event.organizerId.trim();
            final isNotOrganizer = eventOrganizerId != currentUserId;
            return isUpcoming && isNotOrganizer;
          }).toList();
          print('Filtered all events: ${_allEvents.length}');

          // Filter events created by current user
          _myEvents = allEventsResponse.data!.where((event) {
            final isUpcoming = event.date.isAfter(now);
            final eventOrganizerId = event.organizerId.trim();
            final isOrganizer = eventOrganizerId == currentUserId;
            return isUpcoming && isOrganizer;
          }).toList();
          print('Filtered my events: ${_myEvents.length}');

          // Get registered events by checking participants array
          _registeredEvents = allEventsResponse.data!.where((event) {
            final isUpcoming = event.date.isAfter(now);
            final isRegistered = event.participants.any(
                (participant) => participant.userId.trim() == currentUserId);
            return isUpcoming && isRegistered;
          }).toList();
          print('Filtered registered events: ${_registeredEvents.length}');

          // Initialize past events list
          _pastEvents = [];

          // Add past events created by current user
          final myPastEvents = allEventsResponse.data!.where((event) {
            final isPast = event.date.isBefore(now);
            final eventOrganizerId = event.organizerId.trim();
            final isOrganizer = eventOrganizerId == currentUserId;
            return isPast && isOrganizer;
          }).toList();
          _pastEvents.addAll(myPastEvents);
          print('Added my past events: ${myPastEvents.length}');

          // Add past events that user attended (was a participant)
          final attendedPastEvents = allEventsResponse.data!.where((event) {
            final isPast = event.date.isBefore(now);
            final wasParticipant = event.participants.any(
                (participant) => participant.userId.trim() == currentUserId);
            return isPast && wasParticipant;
          }).toList();
          _pastEvents.addAll(attendedPastEvents);
          print('Added attended past events: ${attendedPastEvents.length}');

          // Remove duplicates from past events
          _pastEvents = _pastEvents.toSet().toList();
          print('Final past events count: ${_pastEvents.length}');

          _isLoading = false;
        });
      } else {
        setState(() {
          _allEvents = [];
          _myEvents = [];
          _registeredEvents = [];
          _pastEvents = [];
          _isLoading = false;
          _errorMessage = allEventsResponse.error ?? 'Failed to load events';
        });
        print('Error loading events: ${allEventsResponse.error}');
      }
    } catch (e, stackTrace) {
      print('Error in _loadEvents: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;

      setState(() {
        _allEvents = [];
        _myEvents = [];
        _registeredEvents = [];
        _pastEvents = [];
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Events'),
            Tab(text: 'My Events'),
            Tab(text: 'Registered'),
            Tab(text: 'Past Events'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEventScreen(),
                ),
              );
              if (result == true) {
                _loadEvents();
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(_allEvents),
          _buildEventsList(_myEvents),
          _buildEventsList(_registeredEvents),
          _buildPastEventsList(_pastEvents),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (_isLoading && events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: events.isEmpty
          ? const Center(
              child: Text(
                'No events available',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: EventCard(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      ).then((_) => _loadEvents());
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPastEventsList(List<Event> events) {
    if (_isLoading && events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadEvents, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: events.isEmpty
          ? const Center(
              child: Text(
                'No past events available',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: EventCard(
                    event: event,
                    isPast: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      ).then((_) => _loadEvents());
                    },
                  ),
                );
              },
            ),
    );
  }
}

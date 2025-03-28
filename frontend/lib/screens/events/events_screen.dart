import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'package:frontend/widget/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  List<Event> _allEvents = [];
  List<Event> _userEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load all events
      final allEventsResponse = await _eventService.getEvents();

      if (allEventsResponse.success) {
        setState(() {
          _allEvents = allEventsResponse.data ?? [];
        });
      } else {
        setState(() {
          _errorMessage = allEventsResponse.error ?? 'Failed to load events';
        });
      }

      // Load user events
      final userEventsResponse = await _eventService.getUserEvents();

      if (userEventsResponse.success) {
        setState(() {
          _userEvents = userEventsResponse.data ?? [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'All Events'), Tab(text: 'My Events')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : TabBarView(
                controller: _tabController,
                children: [
                  // All events tab
                  _buildEventsList(_allEvents),

                  // My events tab
                  _buildEventsList(_userEvents),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create event screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return const Center(child: Text('No events found'));
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCard(
            event: event,
            onTap: () {
              Navigator.pushNamed(context, '/event-detail', arguments: event);
            },
          );
        },
      ),
    );
  }
}

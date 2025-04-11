import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend/widget/event_card.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventService = EventService();
      final response = await eventService.getEvents();

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _events = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _events = [];
          _isLoading = false;
          _errorMessage = response.error ?? 'Failed to load events';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _events = [];
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _events.isEmpty) {
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
      child:
          _events.isEmpty
              ? const Center(
                child: Text(
                  'No events available',
                  style: TextStyle(fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EventCard(
                      event: event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => EventDetailScreen(event: event),
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

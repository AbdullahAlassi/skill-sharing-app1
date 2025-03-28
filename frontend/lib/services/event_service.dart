import '../models/event_model.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _apiClient;

  EventService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Get all events
  Future<ApiResponse<List<Event>>> getEvents() async {
    return await _apiClient.get<List<Event>>(
      'events',
      (json) => List<Event>.from(json.map((x) => Event.fromJson(x))),
    );
  }

  // Get event by ID
  Future<ApiResponse<Event>> getEventById(String id) async {
    return await _apiClient.get<Event>(
      'events/$id',
      (json) => Event.fromJson(json),
    );
  }

  // Create a new event
  Future<ApiResponse<Event>> createEvent(
    String title,
    String description,
    DateTime date,
    DateTime? endDate,
    String location,
    bool isVirtual,
    String? meetingLink,
    List<String> relatedSkills,
    int? maxParticipants,
  ) async {
    return await _apiClient.post<Event>('events', {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      'location': location,
      'isVirtual': isVirtual,
      if (meetingLink != null) 'meetingLink': meetingLink,
      'relatedSkills': relatedSkills,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
    }, (json) => Event.fromJson(json));
  }

  // Update an event
  Future<ApiResponse<Event>> updateEvent(
    String id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    String? location,
    bool? isVirtual,
    String? meetingLink,
    List<String>? relatedSkills,
    int? maxParticipants,
  ) async {
    return await _apiClient.put<Event>('events/$id', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (date != null) 'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      if (location != null) 'location': location,
      if (isVirtual != null) 'isVirtual': isVirtual,
      'meetingLink': meetingLink,
      if (relatedSkills != null) 'relatedSkills': relatedSkills,
      'maxParticipants': maxParticipants,
    }, (json) => Event.fromJson(json));
  }

  // Delete an event
  Future<ApiResponse<Map<String, dynamic>>> deleteEvent(String id) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'events/$id',
      (json) => json,
    );
  }

  // Register for an event
  Future<ApiResponse<Map<String, dynamic>>> registerForEvent(String id) async {
    return await _apiClient.post<Map<String, dynamic>>(
      'events/$id/register',
      {},
      (json) => json,
    );
  }

  // Unregister from an event
  Future<ApiResponse<Map<String, dynamic>>> unregisterFromEvent(
    String id,
  ) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'events/$id/register',
      (json) => json,
    );
  }

  // Get events user is registered for
  Future<ApiResponse<List<Event>>> getUserEvents() async {
    return await _apiClient.get<List<Event>>(
      'events/user',
      (json) => List<Event>.from(json.map((x) => Event.fromJson(x))),
    );
  }
}

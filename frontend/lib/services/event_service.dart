import 'dart:async';
import '../models/event_model.dart';
import 'api_client.dart';
import 'skill_service.dart';
import 'dart:convert';
import '../utils/api_response.dart';
import '../config/app_config.dart';

class EventService {
  final ApiClient _apiClient;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  EventService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  // Get all events
  Future<ApiResponse<List<Event>>> getEvents() async {
    try {
      final response = await _apiClient.get<List<Event>>('api/events', (json) {
        final eventList = json['events'] ?? [];
        return List<Event>.from(eventList.map((x) => Event.fromJson(x)));
      }).timeout(_timeoutDuration);

      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Events loaded successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      return ApiResponse<List<Event>>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse<List<Event>>(
        success: false,
        error: 'Failed to load events: ${e.toString()}',
        message: 'Failed to load events',
        statusCode: 500,
      );
    }
  }

  // Get event by ID
  Future<ApiResponse<Event>> getEventById(String id) async {
    try {
      final response = await _apiClient
          .get<Event>('api/events/$id', (json) => Event.fromJson(json))
          .timeout(_timeoutDuration);

      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Event loaded successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      return ApiResponse<Event>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse<Event>(
        success: false,
        error: 'Failed to load event: ${e.toString()}',
        message: 'Failed to load event',
        statusCode: 500,
      );
    }
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
    List<String> selectedSkills,
    int? maxParticipants,
  ) async {
    try {
      print('=== Starting Event Creation ===');
      print('Event Data:');
      print('- Title: $title');
      print('- Description: $description');
      print('- Date: ${date.toIso8601String()}');
      print('- End Date: ${endDate?.toIso8601String()}');
      print('- Location: $location');
      print('- Is Virtual: $isVirtual');
      print('- Meeting Link: $meetingLink');
      print('- Selected Skills: $selectedSkills');
      print('- Max Participants: $maxParticipants');

      // Get user's skills
      print('\nFetching user skills...');
      final skillService = SkillService();
      final skillsResponse = await skillService.getSkills().timeout(
            _timeoutDuration,
          );

      if (!skillsResponse.success) {
        print('Failed to fetch skills: ${skillsResponse.error}');
        return ApiResponse<Event>(
          success: false,
          error: 'Failed to fetch skills',
          message: 'Failed to fetch skills',
          statusCode: skillsResponse.statusCode,
        );
      }

      print('User skills fetched successfully');
      print('Available skills: ${skillsResponse.data?.length ?? 0}');

      // Filter selected skills from user's skills
      final userSkills = skillsResponse.data ?? [];
      final selectedSkillIds = userSkills
          .where((skill) => selectedSkills.contains(skill.name))
          .map((skill) => skill.id)
          .toList();

      print('\nSelected skill IDs: $selectedSkillIds');

      // Prepare request body
      final requestBody = {
        'title': title,
        'description': description,
        'category': 'General',
        'date': date.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        'location': location,
        'isVirtual': isVirtual,
        if (meetingLink != null) 'meetingLink': meetingLink,
        'relatedSkills': selectedSkillIds,
        if (maxParticipants != null) 'maxParticipants': maxParticipants,
      };

      print('\nSending request to create event...');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await _apiClient.post<Event>(
        'api/events',
        requestBody,
        (json) {
          if (json is String) {
            final parsedJson = jsonDecode(json);
            return Event.fromJson(parsedJson);
          }
          return Event.fromJson(json);
        },
      ).timeout(_timeoutDuration);

      print('\nCreate event response:');
      print('- Event created successfully');
      print('- Event ID: ${response.data?.id}');

      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Event created successfully',
        statusCode: 201,
      );
    } on TimeoutException {
      print('\nEvent creation timed out');
      return ApiResponse<Event>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      print('\nError in createEvent:');
      print('- Error type: ${e.runtimeType}');
      print('- Error message: $e');
      print('- Stack trace: ${e.toString()}');
      return ApiResponse<Event>(
        success: false,
        error: 'Failed to create event: ${e.toString()}',
        message: 'Failed to create event',
        statusCode: 500,
      );
    } finally {
      print('\n=== Event Creation Process Completed ===\n');
    }
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
    try {
      final response = await _apiClient
          .put<Event>(
            'api/events/$id',
            {
              if (title != null) 'title': title,
              if (description != null) 'description': description,
              if (date != null) 'date': date.toIso8601String(),
              if (endDate != null) 'endDate': endDate.toIso8601String(),
              if (location != null) 'location': location,
              if (isVirtual != null) 'isVirtual': isVirtual,
              if (meetingLink != null) 'meetingLink': meetingLink,
              if (relatedSkills != null) 'relatedSkills': relatedSkills,
              if (maxParticipants != null) 'maxParticipants': maxParticipants,
            },
            (json) => Event.fromJson(json),
          )
          .timeout(_timeoutDuration);

      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Event updated successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      return ApiResponse<Event>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse<Event>(
        success: false,
        error: 'Failed to update event: ${e.toString()}',
        message: 'Failed to update event',
        statusCode: 500,
      );
    }
  }

  // Delete an event
  Future<ApiResponse<Map<String, dynamic>>> deleteEvent(String id) async {
    try {
      print('[DEBUG] Starting event deletion for event ID: $id');

      final response = await _apiClient.delete<Map<String, dynamic>>(
        'api/events/$id',
        (json) {
          print('[DEBUG] Delete response: $json');
          return json as Map<String, dynamic>;
        },
      ).timeout(_timeoutDuration);

      print('[DEBUG] Event deletion response: ${response.success}');
      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Event deleted successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      print('[DEBUG] Delete request timed out');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      print('[DEBUG] Error in deleteEvent: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Failed to delete event: ${e.toString()}',
        message: 'Failed to delete event',
        statusCode: 500,
      );
    }
  }

  // Register for an event
  Future<ApiResponse<Event>> registerForEvent(String id) async {
    try {
      print('=== Starting Event Registration ===');
      print('Event ID: $id');

      // First, make the registration request
      final registerResponse = await _apiClient
          .post<Map<String, dynamic>>(
            'api/events/$id/register',
            {'eventId': id},
            (json) => json as Map<String, dynamic>,
          )
          .timeout(_timeoutDuration);

      if (!registerResponse.success) {
        return ApiResponse<Event>(
          success: false,
          error: registerResponse.error ?? 'Failed to register for event',
          message: 'Failed to register for event',
          statusCode: registerResponse.statusCode,
        );
      }

      print('[DEBUG] Registration successful, fetching updated event data');

      // After successful registration, fetch the updated event data
      final eventResponse = await _apiClient
          .get<Event>(
            'api/events/$id',
            (json) => Event.fromJson(json),
          )
          .timeout(_timeoutDuration);

      if (!eventResponse.success || eventResponse.data == null) {
        return ApiResponse<Event>(
          success: false,
          error: eventResponse.error ?? 'Failed to fetch updated event data',
          message: 'Failed to fetch updated event data',
          statusCode: eventResponse.statusCode,
        );
      }

      print('[DEBUG] Updated event data fetched successfully');
      return ApiResponse(
        success: true,
        data: eventResponse.data,
        message: 'Registered for event successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      print('Registration request timed out');
      return ApiResponse<Event>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in registerForEvent: $e');
      return ApiResponse<Event>(
        success: false,
        error: 'Failed to register for event: ${e.toString()}',
        message: 'Failed to register for event',
        statusCode: 500,
      );
    }
  }

  // Unregister from an event
  Future<ApiResponse<Event>> unregisterFromEvent(String id) async {
    try {
      print('[DEBUG] Starting event unregistration for event ID: $id');

      final response = await _apiClient.delete<Event>(
        'api/events/$id/register',
        (json) {
          print('[DEBUG] Raw unregister response: $json');

          // Handle different response formats
          Map<String, dynamic> eventData;
          if (json is String) {
            eventData = jsonDecode(json);
          } else if (json is Map<String, dynamic>) {
            eventData = json;
          } else {
            throw Exception('Unexpected response format');
          }

          // Extract event data if it's wrapped
          if (eventData.containsKey('event')) {
            eventData = eventData['event'];
          }

          print('[DEBUG] Parsed event data: $eventData');
          final event = Event.fromJson(eventData);
          print('[DEBUG] Event after unregistration: ${event.participants}');

          return event;
        },
      ).timeout(_timeoutDuration);

      if (response.data == null) {
        throw Exception('No event data received from server');
      }

      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Unregistered from event successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      print('[DEBUG] Unregistration request timed out');
      return ApiResponse<Event>(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      print('[DEBUG] Error in unregisterFromEvent: $e');
      return ApiResponse<Event>(
        success: false,
        error: 'Failed to unregister from event: ${e.toString()}',
        message: 'Failed to unregister from event',
        statusCode: 500,
      );
    }
  }

  // Get events user is registered for
  Future<ApiResponse<List<Event>>> getUserEvents() async {
    try {
      print('[DEBUG] Fetching user events...');
      final response = await _apiClient.get<dynamic>(
        'api/events/user/events',
        (json) {
          print('[DEBUG] Raw response type: ${json.runtimeType}');
          print('[DEBUG] Raw response: $json');

          // Handle both List and Map responses
          List<dynamic> rawList;
          if (json is List) {
            rawList = json;
          } else if (json is Map<String, dynamic>) {
            if (json.containsKey('events')) {
              rawList = json['events'] as List;
            } else if (json.containsKey('data')) {
              rawList = json['data'] as List;
            } else {
              print(
                  '[ERROR] Unexpected response format: missing events/data key');
              return <Event>[];
            }
          } else {
            print('[ERROR] Unexpected response type: ${json.runtimeType}');
            return <Event>[];
          }

          // Safely parse each event
          final events = <Event>[];
          for (var item in rawList) {
            if (item is Map<String, dynamic>) {
              try {
                final event = Event.fromJson(item);
                events.add(event);
              } catch (e) {
                print('[ERROR] Failed to parse event: $e');
                print('[ERROR] Problematic item: $item');
              }
            } else {
              print('[ERROR] Skipping non-map item: ${item.runtimeType}');
            }
          }

          print('[DEBUG] Successfully parsed ${events.length} events');
          return events;
        },
      ).timeout(_timeoutDuration);

      if (!response.success) {
        return ApiResponse<List<Event>>(
          success: false,
          error: response.error ?? 'Failed to load user events',
          message: 'Failed to load user events',
          statusCode: response.statusCode,
        );
      }

      // Handle the response data
      List<Event> events;
      if (response.data is List) {
        events = (response.data as List).map((item) {
          if (item is Event) {
            return item;
          } else if (item is Map<String, dynamic>) {
            return Event.fromJson(item);
          } else {
            throw Exception('Invalid event data format');
          }
        }).toList();
      } else {
        print(
            '[ERROR] Unexpected response data type: ${response.data.runtimeType}');
        return ApiResponse<List<Event>>(
          success: false,
          error: 'Invalid response format',
          message: 'Failed to load user events',
          statusCode: 500,
        );
      }

      return ApiResponse<List<Event>>(
        success: true,
        data: events,
        message: 'User events loaded successfully',
        statusCode: 200,
      );
    } on TimeoutException {
      print('[ERROR] Request timed out');
      return ApiResponse<List<Event>>(
        success: false,
        error: 'Request timed out. Please try again.',
        message: 'Timeout error',
        statusCode: 408,
      );
    } catch (e, st) {
      print('[ERROR] Exception in getUserEvents: $e');
      print(st);
      return ApiResponse<List<Event>>(
        success: false,
        error: 'Failed to load user events: ${e.toString()}',
        message: 'Failed to load user events',
        statusCode: 500,
      );
    }
  }
}

import 'dart:async';
import '../models/event_model.dart';
import 'api_client.dart';
import 'skill_service.dart';
import 'dart:convert';

class EventService {
  final ApiClient _apiClient;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  EventService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Get all events
  Future<ApiResponse<List<Event>>> getEvents() async {
    try {
      final response = await _apiClient.get<List<Event>>('events', (json, _) {
        if (json is String) {
          final parsedJson = jsonDecode(json);
          if (parsedJson is List) {
            return parsedJson.map((x) => Event.fromJson(x)).toList();
          }
        } else if (json is List) {
          return json.map((x) => Event.fromJson(x)).toList();
        }
        return [];
      }).timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in getEvents: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to load events: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get event by ID
  Future<ApiResponse<Event>> getEventById(String id) async {
    try {
      final response = await _apiClient
          .get<Event>('events/$id', (json, _) => Event.fromJson(json))
          .timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to load event: ${e.toString()}',
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
        return ApiResponse(
          success: false,
          error: 'Failed to fetch skills',
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

      final response =
          await _apiClient.post<Event>('events', requestBody, (json, _) {
        // Handle both string and map responses
        if (json is String) {
          final parsedJson = jsonDecode(json);
          return Event.fromJson(parsedJson);
        } else if (json is Map<String, dynamic>) {
          return Event.fromJson(json);
        }
        throw Exception('Invalid response format');
      }).timeout(_timeoutDuration);

      print('\nCreate event response:');
      print('- Success: ${response.success}');
      print('- Status Code: ${response.statusCode}');
      if (!response.success) {
        print('- Error: ${response.error}');
        print('- Response body: ${response.body}');
      } else {
        print('- Event created successfully');
        print('- Event ID: ${response.data?.id}');
      }

      return response;
    } on TimeoutException {
      print('\nEvent creation timed out');
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      print('\nError in createEvent:');
      print('- Error type: ${e.runtimeType}');
      print('- Error message: $e');
      print('- Stack trace: ${e.toString()}');
      return ApiResponse(
        success: false,
        error: 'Failed to create event: ${e.toString()}',
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
              'events/$id',
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
              (json, _) => Event.fromJson(json))
          .timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to update event: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Delete an event
  Future<ApiResponse<Map<String, dynamic>>> deleteEvent(String id) async {
    try {
      final response = await _apiClient
          .delete<Map<String, dynamic>>(
            'events/$id',
            (json, _) => json as Map<String, dynamic>,
          )
          .timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to delete event: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Register for an event
  Future<ApiResponse<Event>> registerForEvent(String id) async {
    try {
      final response =
          await _apiClient.post<Event>('events/$id/register', {}, (json, _) {
        if (json is String) {
          final parsedJson = jsonDecode(json);
          return Event.fromJson(parsedJson);
        }
        return Event.fromJson(json);
      }).timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in registerForEvent: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to register for event: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Unregister from an event
  Future<ApiResponse<Event>> unregisterFromEvent(String id) async {
    try {
      final response = await _apiClient.delete<Event>(
        'events/$id/register',
        (json, _) {
          if (json is String) {
            final parsedJson = jsonDecode(json);
            return Event.fromJson(parsedJson);
          }
          return Event.fromJson(json);
        },
      ).timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to unregister from event: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get events user is registered for
  Future<ApiResponse<List<Event>>> getUserEvents() async {
    try {
      final response = await _apiClient.get<List<Event>>(
        'events/user/events',
        (json, _) {
          if (json is String) {
            final parsedJson = jsonDecode(json);
            if (parsedJson is List) {
              return parsedJson.map((x) => Event.fromJson(x)).toList();
            }
          } else if (json is List) {
            return json.map((x) => Event.fromJson(x)).toList();
          }
          return [];
        },
      ).timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'Failed to load user events: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}

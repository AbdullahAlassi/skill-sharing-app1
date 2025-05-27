class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final bool isVirtual;
  final String? meetingLink;
  final String? image;
  final List<String> relatedSkills;
  final String organizerId;
  final String? organizerName;
  final List<Participant> participants;
  final int? maxParticipants;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endDate,
    required this.location,
    this.isVirtual = true,
    this.meetingLink,
    this.image,
    this.relatedSkills = const [],
    required this.organizerId,
    this.organizerName,
    this.participants = const [],
    this.maxParticipants,
    required this.createdAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    print('Parsing event JSON: $json');

    // Parse date with error handling
    DateTime parseDate(String dateStr) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Error parsing date: $dateStr');
        return DateTime.now();
      }
    }

    // Parse organizer ID with error handling
    String parseOrganizerId(dynamic organizer) {
      if (organizer == null) {
        print('Warning: organizer is null');
        return '';
      }
      if (organizer is String) {
        return organizer.trim();
      }
      if (organizer is Map) {
        final id = organizer['_id']?.toString() ?? '';
        print('Extracted organizer ID from map: $id');
        return id.trim();
      }
      print('Warning: unexpected organizer format: $organizer');
      return '';
    }

    // Parse organizer name with error handling
    String? parseOrganizerName(dynamic organizer) {
      if (organizer is Map) {
        return organizer['name']?.toString();
      }
      return null;
    }

    final event = Event(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: parseDate(json['date']),
      endDate: json['endDate'] != null ? parseDate(json['endDate']) : null,
      location: json['location']?.toString() ?? '',
      isVirtual: json['isVirtual'] ?? true,
      meetingLink: json['meetingLink']?.toString(),
      image: json['image']?.toString(),
      relatedSkills: json['relatedSkills'] != null
          ? List<String>.from(
              json['relatedSkills'].map((x) => x['name'] ?? x.toString()),
            )
          : [],
      organizerId: parseOrganizerId(json['organizer']),
      organizerName: parseOrganizerName(json['organizer']),
      participants: json['participants'] != null
          ? List<Participant>.from(
              json['participants'].map((x) => Participant.fromJson(x)),
            )
          : [],
      maxParticipants: json['maxParticipants'],
      createdAt: json['createdAt'] != null
          ? parseDate(json['createdAt'])
          : DateTime.now(),
    );

    print('Parsed event: ${event.toJson()}');
    return event;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'location': location,
      'isVirtual': isVirtual,
      if (meetingLink != null) 'meetingLink': meetingLink,
      'relatedSkills': relatedSkills,
      'organizerId': organizerId,
      if (organizerName != null) 'organizerName': organizerName,
      'participants': participants.map((x) => x.toJson()).toList(),
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool isUserRegistered(String userId) =>
      participants.any((p) => p.userId == userId);
  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isFull =>
      maxParticipants != null && participants.length >= maxParticipants!;
}

class Participant {
  final String userId;
  final String? userName;
  final String? userProfilePicture;
  final DateTime registeredAt;

  Participant({
    required this.userId,
    this.userName,
    this.userProfilePicture,
    required this.registeredAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    print('Parsing participant JSON: $json');

    // Parse user ID with error handling
    String parseUserId(dynamic user) {
      if (user == null) {
        print('Warning: user is null');
        return '';
      }
      if (user is String) {
        return user;
      }
      if (user is Map) {
        return user['_id']?.toString() ?? '';
      }
      print('Warning: unexpected user format: $user');
      return '';
    }

    // Parse user name with error handling
    String? parseUserName(dynamic user) {
      if (user is Map) {
        return user['name']?.toString();
      }
      return null;
    }

    // Parse user profile picture with error handling
    String? parseUserProfilePicture(dynamic user) {
      if (user is Map) {
        return user['profilePicture']?.toString();
      }
      return null;
    }

    // Parse registration date with error handling
    DateTime parseRegisteredAt(dynamic dateStr) {
      if (dateStr == null) {
        return DateTime.now();
      }
      try {
        return DateTime.parse(dateStr.toString());
      } catch (e) {
        print('Error parsing registration date: $dateStr');
        return DateTime.now();
      }
    }

    final participant = Participant(
      userId: parseUserId(json['user']),
      userName: parseUserName(json['user']),
      userProfilePicture: parseUserProfilePicture(json['user']),
      registeredAt: parseRegisteredAt(json['registeredAt']),
    );

    print('Parsed participant: ${participant.toJson()}');
    return participant;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (userName != null) 'userName': userName,
      if (userProfilePicture != null) 'userProfilePicture': userProfilePicture,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }
}

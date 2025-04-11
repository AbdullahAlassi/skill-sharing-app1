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
    return Event(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      location: json['location'],
      isVirtual: json['isVirtual'] ?? true,
      meetingLink: json['meetingLink'],
      image: json['image'],
      relatedSkills:
          json['relatedSkills'] != null
              ? List<String>.from(
                json['relatedSkills'].map((x) => x['name'] ?? x.toString()),
              )
              : [],
      organizerId:
          json['organizer'] is String
              ? json['organizer']
              : json['organizer']['_id'],
      organizerName:
          json['organizer'] is Map ? json['organizer']['name'] : null,
      participants:
          json['participants'] != null
              ? List<Participant>.from(
                json['participants'].map((x) => Participant.fromJson(x)),
              )
              : [],
      maxParticipants: json['maxParticipants'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'location': location,
      'isVirtual': isVirtual,
      if (meetingLink != null) 'meetingLink': meetingLink,
      'relatedSkills': relatedSkills,
      if (maxParticipants != null) 'maxParticipants': maxParticipants,
    };
  }

  bool get isUserRegistered =>
      participants.any((p) => p.userId == 'currentUserId');
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
    return Participant(
      userId: json['user'] is String ? json['user'] : json['user']['_id'],
      userName: json['user'] is Map ? json['user']['name'] : null,
      userProfilePicture:
          json['user'] is Map ? json['user']['profilePicture'] : null,
      registeredAt:
          json['registeredAt'] != null
              ? DateTime.parse(json['registeredAt'])
              : DateTime.now(),
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String eventType; // 'match' (Maç Etkinliği) veya 'entertainment' (Eğlence, Parti, Konser vb.)
  final String? teamId; // Maç etkinliği ise takım ID'si (ör. 'gs', 'fb')
  final String locationCity; // İl / Bölge (ör. 'İstanbul', 'Kadıköy', 'Beşiktaş')
  final String? venueName; // Mekan veya Stat adı
  final DateTime eventDateTime; // Etkinlik tarihi ve saati
  final String creatorUserId;
  final String creatorEmail;
  final List<String> participantUserIds; // Onaylanmış katılımcılar
  final List<String> pendingUserIds; // Onay bekleyen katılım istekleri
  final String? opponentTeamId; // Rakip takım varsa
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    this.teamId,
    required this.locationCity,
    this.venueName,
    required this.eventDateTime,
    required this.creatorUserId,
    required this.creatorEmail,
    List<String>? participantUserIds,
    List<String>? pendingUserIds,
    this.opponentTeamId,
    DateTime? createdAt,
  })  : participantUserIds = participantUserIds ?? [creatorUserId],
        pendingUserIds = pendingUserIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory EventModel.fromMap(Map<String, dynamic> data, String docId) {
    return EventModel(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventType: data['eventType'] ?? 'match',
      teamId: data['teamId'],
      locationCity: data['locationCity'] ?? '',
      venueName: data['venueName'],
      eventDateTime: data['eventDateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['eventDateTime'] as int)
          : DateTime.now(),
      creatorUserId: data['creatorUserId'] ?? '',
      creatorEmail: data['creatorEmail'] ?? '',
      participantUserIds: (data['participantUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pendingUserIds: (data['pendingUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      opponentTeamId: data['opponentTeamId'],
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventType': eventType,
      'teamId': teamId,
      'locationCity': locationCity,
      'venueName': venueName,
      'eventDateTime': eventDateTime.millisecondsSinceEpoch,
      'creatorUserId': creatorUserId,
      'creatorEmail': creatorEmail,
      'participantUserIds': participantUserIds,
      'pendingUserIds': pendingUserIds,
      'opponentTeamId': opponentTeamId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? eventType,
    String? teamId,
    String? locationCity,
    String? venueName,
    DateTime? eventDateTime,
    String? creatorUserId,
    String? creatorEmail,
    List<String>? participantUserIds,
    List<String>? pendingUserIds,
    String? opponentTeamId,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      teamId: teamId ?? this.teamId,
      locationCity: locationCity ?? this.locationCity,
      venueName: venueName ?? this.venueName,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      participantUserIds: participantUserIds ?? List.from(this.participantUserIds),
      pendingUserIds: pendingUserIds ?? List.from(this.pendingUserIds),
      opponentTeamId: opponentTeamId ?? this.opponentTeamId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AdModel {
  final String id;
  final String title;
  final String mediaUrl; // Resim veya video linki / dosya yolu
  final String mediaType; // 'image' veya 'video'
  final String targetUrl; // Tıklanınca açılacak web sitesi / sosyal medya
  final String type; // 'google' veya 'sponsor'
  final bool isActive;
  final int rewardSeconds; // Minimum izlenme süresi (sn)
  final int viewCount; // İzlenme sayısı
  final String targetTeamId; // 'all' (Tüm Takımlar) veya takım ID'si (ör. 'gs', 'fb')
  final int durationDays; // Kaç gün gösterilecek
  final DateTime startDate; // Başlangıç tarihi
  final DateTime endDate; // Bitiş tarihi
  final String frequency; // 'always' (Her şovda), 'every_2' (2 şovda bir), 'every_3' (3 şovda bir)
  final int displayOrder; // Gösterim sırası (1, 2, 3...)

  AdModel({
    required this.id,
    this.title = 'Sponsor Reklamı',
    required this.mediaUrl,
    this.mediaType = 'image',
    required this.targetUrl,
    this.type = 'sponsor',
    required this.isActive,
    this.rewardSeconds = 15,
    this.viewCount = 0,
    this.targetTeamId = 'all',
    this.durationDays = 7,
    DateTime? startDate,
    DateTime? endDate,
    this.frequency = 'always',
    this.displayOrder = 1,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ??
            (startDate ?? DateTime.now())
                .add(Duration(days: durationDays > 0 ? durationDays : 7));

  /// Geriye dönük uyumluluk
  String get imageUrl => mediaUrl;

  /// Reklam süresi doldu mu?
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Reklam şu anda kullanıcılara gösterilebilir mi?
  bool get isEligible => isActive && !isExpired;

  /// Kalan gün sayısı
  int get remainingDays {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory AdModel.fromMap(Map<String, dynamic> data, String documentId) {
    final startMs = data['startDate'] as int?;
    final endMs = data['endDate'] as int?;
    final dur = data['durationDays'] as int? ?? 7;
    final start = startMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startMs)
        : DateTime.now();
    final end = endMs != null
        ? DateTime.fromMillisecondsSinceEpoch(endMs)
        : start.add(Duration(days: dur));

    return AdModel(
      id: documentId,
      title: data['title'] ?? 'Sponsor Reklamı',
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      targetUrl: data['targetUrl'] ?? '',
      type: data['type'] ?? 'sponsor',
      isActive: data['isActive'] ?? false,
      rewardSeconds: data['rewardSeconds'] ?? 15,
      viewCount: data['viewCount'] ?? 0,
      targetTeamId: data['targetTeamId'] ?? 'all',
      durationDays: dur,
      startDate: start,
      endDate: end,
      frequency: data['frequency'] ?? 'always',
      displayOrder: data['displayOrder'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'mediaUrl': mediaUrl,
      'imageUrl': mediaUrl, // Eski sürümlerle tam uyumluluk
      'mediaType': mediaType,
      'targetUrl': targetUrl,
      'type': type,
      'isActive': isActive,
      'rewardSeconds': rewardSeconds,
      'viewCount': viewCount,
      'targetTeamId': targetTeamId,
      'durationDays': durationDays,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'frequency': frequency,
      'displayOrder': displayOrder,
    };
  }

  AdModel copyWith({
    String? id,
    String? title,
    String? mediaUrl,
    String? imageUrl,
    String? mediaType,
    String? targetUrl,
    String? type,
    bool? isActive,
    int? rewardSeconds,
    int? viewCount,
    String? targetTeamId,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
    String? frequency,
    int? displayOrder,
  }) {
    return AdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      mediaUrl: mediaUrl ?? imageUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      targetUrl: targetUrl ?? this.targetUrl,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      rewardSeconds: rewardSeconds ?? this.rewardSeconds,
      viewCount: viewCount ?? this.viewCount,
      targetTeamId: targetTeamId ?? this.targetTeamId,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

class AdModel {
  final String id;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String type; // 'google' or 'sponsor'
  final bool isActive;
  final int rewardSeconds; // e.g., 15 or 30 seconds
  final int viewCount; // İzlenme sayısı

  AdModel({
    required this.id,
    this.title = 'Sponsor Reklamı',
    required this.imageUrl,
    required this.targetUrl,
    this.type = 'sponsor',
    required this.isActive,
    this.rewardSeconds = 15,
    this.viewCount = 0,
  });

  factory AdModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AdModel(
      id: documentId,
      title: data['title'] ?? 'Sponsor Reklamı',
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'] ?? '',
      type: data['type'] ?? 'sponsor',
      isActive: data['isActive'] ?? false,
      rewardSeconds: data['rewardSeconds'] ?? 15,
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'type': type,
      'isActive': isActive,
      'rewardSeconds': rewardSeconds,
      'viewCount': viewCount,
    };
  }

  AdModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? targetUrl,
    String? type,
    bool? isActive,
    int? rewardSeconds,
    int? viewCount,
  }) {
    return AdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      targetUrl: targetUrl ?? this.targetUrl,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      rewardSeconds: rewardSeconds ?? this.rewardSeconds,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}

class AdModel {
  final String id;
  final String imageUrl;
  final String targetUrl;
  final bool isActive;

  AdModel({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
    required this.isActive,
  });

  factory AdModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AdModel(
      id: documentId,
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'isActive': isActive,
    };
  }
}

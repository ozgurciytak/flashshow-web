class TeamModel {
  final String id;
  final String name;
  final String league; // Lige göre filtreleme için eklendi
  final String primaryColorHex;
  final String secondaryColorHex;

  TeamModel({
    required this.id,
    required this.name,
    required this.league,
    required this.primaryColorHex,
    required this.secondaryColorHex,
  });

  factory TeamModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TeamModel(
      id: documentId,
      name: data['name'] ?? '',
      league: data['league'] ?? 'Diğer',
      primaryColorHex: data['primaryColorHex'] ?? 'FFFFFF',
      secondaryColorHex: data['secondaryColorHex'] ?? '000000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'league': league,
      'primaryColorHex': primaryColorHex,
      'secondaryColorHex': secondaryColorHex,
    };
  }
}

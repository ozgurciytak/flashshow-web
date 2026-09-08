import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';

class DatabaseService extends ChangeNotifier {
  // Sabit (Fixed) Süper Lig ve Diğer Ligler Takımları
  static final List<TeamModel> _fixedTeams = [
    // --- SÜPER LİG (19 Takım) ---
    TeamModel(id: 'gs', name: 'Galatasaray', league: 'Süper Lig', primaryColorHex: 'A32638', secondaryColorHex: 'FDB912'),
    TeamModel(id: 'fb', name: 'Fenerbahçe', league: 'Süper Lig', primaryColorHex: '000080', secondaryColorHex: 'FFFF00'),
    TeamModel(id: 'bjk', name: 'Beşiktaş', league: 'Süper Lig', primaryColorHex: '000000', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'ts', name: 'Trabzonspor', league: 'Süper Lig', primaryColorHex: '800000', secondaryColorHex: '0000FF'),
    TeamModel(id: 'ibfk', name: 'Başakşehir', league: 'Süper Lig', primaryColorHex: 'F58220', secondaryColorHex: '0B2240'),
    TeamModel(id: 'samsun', name: 'Samsunspor', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'eyup', name: 'Eyüpspor', league: 'Süper Lig', primaryColorHex: '4B1E87', secondaryColorHex: 'F9D616'),
    TeamModel(id: 'goztepe', name: 'Göztepe', league: 'Süper Lig', primaryColorHex: 'FFE000', secondaryColorHex: 'DA291C'),
    TeamModel(id: 'sivas', name: 'Sivasspor', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'antalya', name: 'Antalyaspor', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'konya', name: 'Konyaspor', league: 'Süper Lig', primaryColorHex: '008542', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'kasimpasa', name: 'Kasımpaşa', league: 'Süper Lig', primaryColorHex: '0B2240', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'rize', name: 'Çaykur Rizespor', league: 'Süper Lig', primaryColorHex: '008542', secondaryColorHex: '005BBB'),
    TeamModel(id: 'alanya', name: 'Alanyaspor', league: 'Süper Lig', primaryColorHex: 'FF6600', secondaryColorHex: '008542'),
    TeamModel(id: 'gaziantep', name: 'Gaziantep FK', league: 'Süper Lig', primaryColorHex: 'E30613', secondaryColorHex: '000000'),
    TeamModel(id: 'bodrum', name: 'Bodrum FK', league: 'Süper Lig', primaryColorHex: '008542', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'kayseri', name: 'Kayserispor', league: 'Süper Lig', primaryColorHex: 'FFCC00', secondaryColorHex: 'DA291C'),
    TeamModel(id: 'hatay', name: 'Hatayspor', league: 'Süper Lig', primaryColorHex: '800000', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'adanads', name: 'Adana Demirspor', league: 'Süper Lig', primaryColorHex: '005BBB', secondaryColorHex: '0B2240'),

    // --- DİĞER LİGLER (TFF 1. Lig & Köklü Takımlar) ---
    TeamModel(id: 'kocaeli', name: 'Kocaelispor', league: 'Diğer Ligler', primaryColorHex: '008542', secondaryColorHex: '000000'),
    TeamModel(id: 'sakarya', name: 'Sakaryaspor', league: 'Diğer Ligler', primaryColorHex: '008542', secondaryColorHex: '000000'),
    TeamModel(id: 'bursa', name: 'Bursaspor', league: 'Diğer Ligler', primaryColorHex: '008542', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'ankaragucu', name: 'Ankaragücü', league: 'Diğer Ligler', primaryColorHex: 'FDB912', secondaryColorHex: '000080'),
    TeamModel(id: 'gencler', name: 'Gençlerbirliği', league: 'Diğer Ligler', primaryColorHex: 'E30613', secondaryColorHex: '000000'),
    TeamModel(id: 'karagumruk', name: 'Fatih Karagümrük', league: 'Diğer Ligler', primaryColorHex: 'E30613', secondaryColorHex: '000000'),
    TeamModel(id: 'istanbulspor', name: 'İstanbulspor', league: 'Diğer Ligler', primaryColorHex: 'FDB912', secondaryColorHex: '000000'),
    TeamModel(id: 'pendik', name: 'Pendikspor', league: 'Diğer Ligler', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'amed', name: 'Amed SK', league: 'Diğer Ligler', primaryColorHex: '008542', secondaryColorHex: 'E30613'),
    TeamModel(id: 'erzurum', name: 'Erzurumspor', league: 'Diğer Ligler', primaryColorHex: '005BBB', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'bolu', name: 'Boluspor', league: 'Diğer Ligler', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'bandirma', name: 'Bandırmaspor', league: 'Diğer Ligler', primaryColorHex: '800000', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'corum', name: 'Çorum FK', league: 'Diğer Ligler', primaryColorHex: 'E30613', secondaryColorHex: '000000'),
    TeamModel(id: 'adanaspor', name: 'Adanaspor', league: 'Diğer Ligler', primaryColorHex: 'FF6600', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'karsiyaka', name: 'Karşıyaka', league: 'Diğer Ligler', primaryColorHex: '008542', secondaryColorHex: 'E30613'),
    TeamModel(id: 'eskisehir', name: 'Eskişehirspor', league: 'Diğer Ligler', primaryColorHex: '000000', secondaryColorHex: 'E30613'),

    // --- DİĞER LİGLER (Avrupa & Dünya Devleri) ---
    TeamModel(id: 'rm', name: 'Real Madrid', league: 'Diğer Ligler', primaryColorHex: 'FFFFFF', secondaryColorHex: 'EEB211'),
    TeamModel(id: 'barca', name: 'Barcelona', league: 'Diğer Ligler', primaryColorHex: '004D98', secondaryColorHex: 'A50044'),
    TeamModel(id: 'atm', name: 'Atletico Madrid', league: 'Diğer Ligler', primaryColorHex: 'CB3524', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'sevilla', name: 'Sevilla', league: 'Diğer Ligler', primaryColorHex: 'FFFFFF', secondaryColorHex: 'D4001F'),
    TeamModel(id: 'bilbao', name: 'Athletic Bilbao', league: 'Diğer Ligler', primaryColorHex: 'EE2524', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'mci', name: 'Manchester City', league: 'Diğer Ligler', primaryColorHex: '6CABDD', secondaryColorHex: '1C2C5B'),
    TeamModel(id: 'arsenal', name: 'Arsenal', league: 'Diğer Ligler', primaryColorHex: 'EF0107', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'liv', name: 'Liverpool', league: 'Diğer Ligler', primaryColorHex: 'C8102E', secondaryColorHex: '00B2A9'),
    TeamModel(id: 'mun', name: 'Manchester United', league: 'Diğer Ligler', primaryColorHex: 'DA291C', secondaryColorHex: 'FBE122'),
    TeamModel(id: 'chelsea', name: 'Chelsea', league: 'Diğer Ligler', primaryColorHex: '034694', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'tottenham', name: 'Tottenham', league: 'Diğer Ligler', primaryColorHex: '132257', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'inter', name: 'Inter', league: 'Diğer Ligler', primaryColorHex: '0066B2', secondaryColorHex: '000000'),
    TeamModel(id: 'milan', name: 'Milan', league: 'Diğer Ligler', primaryColorHex: 'FB090B', secondaryColorHex: '000000'),
    TeamModel(id: 'juve', name: 'Juventus', league: 'Diğer Ligler', primaryColorHex: '000000', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'napoli', name: 'Napoli', league: 'Diğer Ligler', primaryColorHex: '12A0D7', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'roma', name: 'Roma', league: 'Diğer Ligler', primaryColorHex: '8E1F2F', secondaryColorHex: 'F19E00'),
    TeamModel(id: 'bayern', name: 'Bayern Münih', league: 'Diğer Ligler', primaryColorHex: 'DC052D', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'bvb', name: 'Borussia Dortmund', league: 'Diğer Ligler', primaryColorHex: 'FDE100', secondaryColorHex: '000000'),
    TeamModel(id: 'leverkusen', name: 'Bayer Leverkusen', league: 'Diğer Ligler', primaryColorHex: '000000', secondaryColorHex: 'E32221'),
    TeamModel(id: 'psg', name: 'Paris Saint-Germain', league: 'Diğer Ligler', primaryColorHex: '004170', secondaryColorHex: 'DA291C'),
    TeamModel(id: 'ajax', name: 'Ajax', league: 'Diğer Ligler', primaryColorHex: 'D2122E', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'benfica', name: 'Benfica', league: 'Diğer Ligler', primaryColorHex: 'E30613', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'sporting', name: 'Sporting CP', league: 'Diğer Ligler', primaryColorHex: '008057', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'porto', name: 'Porto', league: 'Diğer Ligler', primaryColorHex: '003882', secondaryColorHex: 'FFFFFF'),
    TeamModel(id: 'intermiami', name: 'Inter Miami', league: 'Diğer Ligler', primaryColorHex: 'F7B5CD', secondaryColorHex: '231F20'),
    TeamModel(id: 'alnassr', name: 'Al-Nassr', league: 'Diğer Ligler', primaryColorHex: 'FFDD00', secondaryColorHex: '002B7F'),
  ];

  List<TeamModel> _customTeams = [];
  List<UserModel> _users = [];
  List<AdModel> _ads = [
    AdModel(
      id: 'default_ad',
      imageUrl: '',
      targetUrl: 'https://flashshow.app',
      isActive: true,
    ),
  ];

  DatabaseService() {
    _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final customTeamsJson = prefs.getString('custom_teams');
      if (customTeamsJson != null) {
        final List<dynamic> decoded = jsonDecode(customTeamsJson);
        _customTeams = decoded.map((m) => TeamModel.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList();
      }

      final usersJson = prefs.getString('registered_users');
      if (usersJson != null) {
        final List<dynamic> decodedUsers = jsonDecode(usersJson);
        _users = decodedUsers.map((m) => UserModel.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList();
      }

      notifyListeners();
    } catch (e) {
      print('Yerel veritabanı yükleme hatası: ');
    }
  }

  List<TeamModel> get allTeams => [..._fixedTeams, ..._customTeams];

  List<String> get leagues {
    final set = allTeams.map((t) => t.league).toSet().toList();
    if (set.contains('Süper Lig')) {
      set.remove('Süper Lig');
      set.insert(0, 'Süper Lig');
    }
    if (set.contains('Diğer Ligler')) {
      set.remove('Diğer Ligler');
      if (set.length > 1) {
        set.insert(1, 'Diğer Ligler');
      } else {
        set.add('Diğer Ligler');
      }
    }
    return set;
  }

  List<TeamModel> getTeamsByLeague(String league) {
    return allTeams.where((t) => t.league == league).toList();
  }

  TeamModel? getTeamById(String id) {
    try {
      return allTeams.firstWhere((t) => t.id == id);
    } catch (_) {
      return _fixedTeams.first;
    }
  }

  Future<void> addTeam(TeamModel team) async {
    _customTeams.add(team);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_customTeams.map((t) => {
        'id': t.id,
        'name': t.name,
        'league': t.league,
        'primaryColorHex': t.primaryColorHex,
        'secondaryColorHex': t.secondaryColorHex,
      }).toList());
      await prefs.setString('custom_teams', encoded);
    } catch (e) {
      print('Takım kaydedilemedi: ');
    }
  }

  Future<void> deleteTeam(String id) async {
    _customTeams.removeWhere((t) => t.id == id);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_customTeams.map((t) => {
        'id': t.id,
        'name': t.name,
        'league': t.league,
        'primaryColorHex': t.primaryColorHex,
        'secondaryColorHex': t.secondaryColorHex,
      }).toList());
      await prefs.setString('custom_teams', encoded);
    } catch (e) {
      print('Takım silinemedi: ');
    }
  }

  List<UserModel> get users => _users;

  Future<void> saveUser(UserModel user) async {
    final index = _users.indexWhere((u) => u.id == user.id || u.email == user.email);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_users.map((u) => {
        'id': u.id,
        'email': u.email,
        'role': u.role,
        'teamId': u.teamId,
      }).toList());
      await prefs.setString('registered_users', encoded);
    } catch (e) {
      print('Kullanıcı kaydedilemedi: ');
    }
  }

  List<AdModel> get ads => _ads;
}

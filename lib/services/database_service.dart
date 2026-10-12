import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';
import '../models/event_model.dart';

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
  List<AdModel> _ads = [];
  List<EventModel> _events = [];
  Map<String, int> _teamSupportCounts = {}; // Takım ID -> İzlenen reklam sayısı

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

      final adsJson = prefs.getString('app_ads');
      if (adsJson != null) {
        final List<dynamic> decodedAds = jsonDecode(adsJson);
        _ads = decodedAds.map((m) => AdModel.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList();
      } else {
        // Varsayılan reklamlar: Hem Google Ads hem de Sponsor Reklamı örneği
        _ads = [
          AdModel(
            id: 'google_ad_1',
            title: 'Google AdMob Ödüllü Reklam',
            imageUrl: '',
            targetUrl: 'https://google.com/admob',
            type: 'google',
            isActive: true,
            rewardSeconds: 15,
          ),
          AdModel(
            id: 'sponsor_ad_1',
            title: 'Flash Show Resmi Sponsoru',
            imageUrl: '',
            targetUrl: 'https://flashshow.app',
            type: 'sponsor',
            isActive: true,
            rewardSeconds: 15,
          ),
        ];
        _saveAdsToPrefs();
      }

      final eventsJson = prefs.getString('app_events');
      if (eventsJson != null) {
        final List<dynamic> decodedEvents = jsonDecode(eventsJson);
        _events = decodedEvents.map((m) => EventModel.fromMap(m as Map<String, dynamic>, m['id'] ?? '')).toList();
      } else {
        // Varsayılan örnek etkinlikler (Kullanıcılar ilk açışta görebilsin)
        _events = [
          EventModel(
            id: 'demo_event_1',
            title: 'Süper Lig Derbi Flash Şov Koreografisi',
            description: 'Stadyumda tüm tribün tek dakikada flaş şovla aydınlanıyor!',
            eventType: 'match',
            teamId: 'gs',
            opponentTeamId: 'fb',
            locationCity: 'İstanbul',
            venueName: 'Rams Park',
            eventDateTime: DateTime.now().add(const Duration(hours: 3)),
            creatorUserId: 'admin_user',
            creatorEmail: 'derbi@flashshow.com',
            participantUserIds: ['admin_user', 'user_1', 'user_2'],
          ),
          EventModel(
            id: 'demo_event_2',
            title: 'Kadıköy Maç Önü Coşku Buluşması',
            description: 'Maç öncesi meydanda toplanıp senkronize flaş şov yapıyoruz.',
            eventType: 'match',
            teamId: 'fb',
            opponentTeamId: 'gs',
            locationCity: 'İstanbul',
            venueName: 'Kadıköy Meydanı',
            eventDateTime: DateTime.now().add(const Duration(hours: 4)),
            creatorUserId: 'fener_fan',
            creatorEmail: 'fener@flashshow.com',
            participantUserIds: ['fener_fan'],
          ),
          EventModel(
            id: 'demo_event_3',
            title: 'Şampiyonluk Kutlaması & Parti Şovu',
            description: 'Müzik eşliğinde hep birlikte flaş ritmi oluşturuyoruz.',
            eventType: 'entertainment',
            teamId: null,
            locationCity: 'İzmir',
            venueName: 'Kordon Boyu',
            eventDateTime: DateTime.now().add(const Duration(hours: 6)),
            creatorUserId: 'izmir_fan',
            creatorEmail: 'parti@flashshow.com',
            participantUserIds: ['izmir_fan'],
          ),
        ];
        _saveEventsToPrefs();
      }

      final supportJson = prefs.getString('team_support_counts');
      if (supportJson != null) {
        final Map<String, dynamic> decodedSupport = jsonDecode(supportJson);
        _teamSupportCounts = decodedSupport.map((k, v) => MapEntry(k, v as int));
      }

      notifyListeners();
    } catch (e) {
      print('Yerel veritabanı yükleme hatası: $e');
    }
  }

  // --- TAKIMLAR ---
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
      print('Takım kaydedilemedi: $e');
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
      print('Takım silinemedi: $e');
    }
  }

  // --- KULLANICILAR ---
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
      final encoded = jsonEncode(_users.map((u) => u.toMap()).toList());
      await prefs.setString('registered_users', encoded);
    } catch (e) {
      print('Kullanıcı kaydedilemedi: $e');
    }
  }

  /// Admin tarafından kullanıcının hesabını askıya alma / kaldırma
  Future<void> toggleUserSuspension(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index >= 0) {
      final updated = _users[index].copyWith(isSuspended: !_users[index].isSuspended);
      _users[index] = updated;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('registered_users', jsonEncode(_users.map((u) => u.toMap()).toList()));
      } catch (_) {}
    }
  }

  /// Admin tarafından veya kullanıcı isteğiyle kullanıcı silme
  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registered_users', jsonEncode(_users.map((u) => u.toMap()).toList()));
    } catch (_) {}
  }

  // --- REKLAMLAR ---
  List<AdModel> get ads => _ads;
  List<AdModel> get activeAds => _ads.where((a) => a.isActive).toList();

  Future<void> addAd(AdModel ad) async {
    _ads.add(ad);
    notifyListeners();
    await _saveAdsToPrefs();
  }

  Future<void> updateAd(AdModel ad) async {
    final idx = _ads.indexWhere((a) => a.id == ad.id);
    if (idx >= 0) {
      _ads[idx] = ad;
      notifyListeners();
      await _saveAdsToPrefs();
    }
  }

  Future<void> deleteAd(String id) async {
    _ads.removeWhere((a) => a.id == id);
    notifyListeners();
    await _saveAdsToPrefs();
  }

  Future<void> _saveAdsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_ads.map((a) => a.toMap()).toList());
      await prefs.setString('app_ads', encoded);
    } catch (e) {
      print('Reklamlar kaydedilemedi: $e');
    }
  }

  // --- TAKIMA DESTEK OL & REKLAM İZLEME ---
  int getSupportCount(String teamId) {
    return _teamSupportCounts[teamId] ?? 0;
  }

  /// Takımı tutan kayıtlı üye sayısı
  int getTeamMemberCount(String teamId) {
    return _users.where((u) => u.teamId == teamId).length;
  }

  /// Toplam reklam izlenme sayısı (Tüm reklamlar)
  int get totalAdViews {
    return _ads.fold<int>(0, (sum, ad) => sum + ad.viewCount);
  }

  /// Toplam etkinlik katılımcı sayısı
  int get totalEventParticipants {
    return _events.fold<int>(0, (sum, ev) => sum + ev.participantUserIds.length);
  }

  Future<void> recordAdSupport(String teamId, {String? adId}) async {
    final current = _teamSupportCounts[teamId] ?? 0;
    _teamSupportCounts[teamId] = current + 1;

    // İlgili reklamın viewCount'unu artır
    if (adId != null) {
      final adIdx = _ads.indexWhere((a) => a.id == adId);
      if (adIdx >= 0) {
        _ads[adIdx] = _ads[adIdx].copyWith(viewCount: _ads[adIdx].viewCount + 1);
        await _saveAdsToPrefs();
      }
    } else if (_ads.isNotEmpty) {
      _ads[0] = _ads[0].copyWith(viewCount: _ads[0].viewCount + 1);
      await _saveAdsToPrefs();
    }

    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('team_support_counts', jsonEncode(_teamSupportCounts));
    } catch (e) {
      print('Destek puanı kaydedilemedi: $e');
    }
  }

  // --- ETKİNLİKLER ---
  List<EventModel> get events => _events;

  /// Şehir / Konuma göre etkinlik filtreleme
  List<EventModel> searchEventsByLocation(String locationQuery) {
    if (locationQuery.trim().isEmpty) return _events;
    final query = locationQuery.trim().toLowerCase();
    return _events.where((e) =>
      e.locationCity.toLowerCase().contains(query) ||
      (e.venueName != null && e.venueName!.toLowerCase().contains(query)) ||
      e.title.toLowerCase().contains(query)
    ).toList();
  }

  /// Kullanıcının oluşturduğu ya da katıldığı geçmiş etkinlikler
  List<EventModel> getUserEventHistory(String userId) {
    return _events.where((e) =>
      e.creatorUserId == userId ||
      e.participantUserIds.contains(userId)
    ).toList();
  }

  /// Yeni Etkinlik Oluşturma Kontrolü
  /// Eğlence / Parti etkinliklerinde aynı bölgede aynı etkinlikten 2 tane olmaması kuralı!
  String? canCreateEvent(EventModel event) {
    if (event.eventType == 'entertainment') {
      final isDuplicate = _events.any((e) =>
        e.eventType == 'entertainment' &&
        e.locationCity.trim().toLowerCase() == event.locationCity.trim().toLowerCase() &&
        e.title.trim().toLowerCase() == event.title.trim().toLowerCase() &&
        e.eventDateTime.difference(event.eventDateTime).inHours.abs() < 4
      );
      if (isDuplicate) {
        return 'Bu konumda ve saat aralığında benzer bir eğlence/parti etkinliği zaten mevcut!';
      }
    }
    return null; // Oluşturulabilir
  }

  Future<bool> createEvent(EventModel event) async {
    final error = canCreateEvent(event);
    if (error != null) {
      return false;
    }
    _events.insert(0, event);
    notifyListeners();
    await _saveEventsToPrefs();
    return true;
  }

  /// Katılma İsteği Gönder (Pending listesine ekle)
  Future<void> requestToJoinEvent(String eventId, String userId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      final ev = _events[idx];
      if (!ev.participantUserIds.contains(userId) && !ev.pendingUserIds.contains(userId)) {
        final updated = ev.copyWith(
          pendingUserIds: [...ev.pendingUserIds, userId],
        );
        _events[idx] = updated;
        notifyListeners();
        await _saveEventsToPrefs();
      }
    }
  }

  /// Katılma İsteğini Onayla (Etkinlik sahibi onaylar)
  Future<void> approveJoinRequest(String eventId, String userId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      final ev = _events[idx];
      final newPending = List<String>.from(ev.pendingUserIds)..remove(userId);
      final newParticipants = List<String>.from(ev.participantUserIds);
      if (!newParticipants.contains(userId)) {
        newParticipants.add(userId);
      }
      _events[idx] = ev.copyWith(
        pendingUserIds: newPending,
        participantUserIds: newParticipants,
      );
      notifyListeners();
      await _saveEventsToPrefs();
    }
  }

  /// Katılma İsteğini Reddet
  Future<void> rejectJoinRequest(String eventId, String userId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      final ev = _events[idx];
      final newPending = List<String>.from(ev.pendingUserIds)..remove(userId);
      _events[idx] = ev.copyWith(pendingUserIds: newPending);
      notifyListeners();
      await _saveEventsToPrefs();
    }
  }

  /// Etkinlik Sil
  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
    await _saveEventsToPrefs();
  }

  Future<void> _saveEventsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_events.map((e) => e.toMap()).toList());
      await prefs.setString('app_events', encoded);
    } catch (e) {
      print('Etkinlikler kaydedilemedi: $e');
    }
  }
}

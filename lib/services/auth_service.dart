import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUserModel;
  bool _isGuest = false;
  bool _isLocalAuth = false;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isAuthenticated => _isGuest || _isLocalAuth || _currentUserModel != null;
  bool get isAdmin => _currentUserModel?.role == 'admin';
  bool get isGuest => _isGuest;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuestSaved = prefs.getBool('is_guest') ?? false;
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedTeamId = prefs.getString('team_id');

      if (isGuestSaved) {
        _isGuest = true;
        _currentUserModel = UserModel(
          id: 'guest',
          email: 'misafir@flashshow.com',
          role: 'user',
          teamId: savedTeamId,
        );
        notifyListeners();
      } else if (isLoggedIn) {
        final email = prefs.getString('user_email') ?? 'kullanici@flashshow.com';
        final uid = prefs.getString('user_id') ?? 'local_user';
        final role = prefs.getString('user_role') ?? 'user';
        _isLocalAuth = true;
        _currentUserModel = UserModel(
          id: uid,
          email: email,
          role: role,
          teamId: savedTeamId,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Yerel oturum yüklenemedi: $e');
    }
  }

  void loginAsGuest() async {
    _isGuest = true;
    _isLocalAuth = false;
    _currentUserModel = UserModel(
      id: 'guest',
      email: 'misafir@flashshow.com',
      role: 'user',
      teamId: null,
    );
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', true);
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('team_id');
    } catch (_) {}
  }

  Future<String?> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Lütfen e-posta ve şifrenizi girin.';
    }

    _isGuest = false;
    _isLocalAuth = true;
    final uid = 'user_${email.hashCode.abs()}';
    final role = email.toLowerCase().contains('admin') ? 'admin' : 'user';

    String? savedTeam;
    try {
      final prefs = await SharedPreferences.getInstance();
      savedTeam = prefs.getString('team_id');
    } catch (_) {}

    _currentUserModel = UserModel(
      id: uid,
      email: email,
      role: role,
      teamId: savedTeam,
    );

    await _saveLocalSession(email: email, uid: uid, role: role);
    notifyListeners();
    return null; // Başarılı
  }

  Future<String?> signUp(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Lütfen e-posta ve şifrenizi girin.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Lütfen geçerli bir e-posta adresi girin.';
    }
    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }

    _isGuest = false;
    _isLocalAuth = true;
    final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final role = email.toLowerCase().contains('admin') ? 'admin' : 'user';

    _currentUserModel = UserModel(
      id: uid,
      email: email,
      role: role,
      teamId: null,
    );

    await _saveLocalSession(email: email, uid: uid, role: role);
    notifyListeners();
    return null; // Başarılı
  }

  Future<void> _saveLocalSession({
    required String email, 
    String? uid, 
    String? role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_email', email);
      if (uid != null) await prefs.setString('user_id', uid);
      if (role != null) await prefs.setString('user_role', role);

      final usersJson = prefs.getString('registered_users');
      List<dynamic> usersList = [];
      if (usersJson != null) {
        try {
          usersList = jsonDecode(usersJson);
        } catch (_) {}
      }
      final existingIndex = usersList.indexWhere((u) => u['email'] == email);
      final userMap = {
        'id': uid ?? 'local_${email.hashCode.abs()}',
        'email': email,
        'role': role ?? 'user',
        'teamId': prefs.getString('team_id'),
      };
      if (existingIndex >= 0) {
        usersList[existingIndex] = userMap;
      } else {
        usersList.add(userMap);
      }
      await prefs.setString('registered_users', jsonEncode(usersList));
    } catch (_) {}
  }

  Future<void> signOut() async {
    _isGuest = false;
    _isLocalAuth = false;
    _currentUserModel = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
      await prefs.remove('is_guest');
      await prefs.remove('user_email');
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      await prefs.remove('team_id');
    } catch (_) {}

    notifyListeners();
  }

  Future<void> updateUserTeam(String teamId) async {
    if (_currentUserModel != null) {
      _currentUserModel = UserModel(
        id: _currentUserModel!.id,
        email: _currentUserModel!.email,
        teamId: teamId,
        role: _currentUserModel!.role,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('team_id', teamId);
        final usersJson = prefs.getString('registered_users');
        if (usersJson != null) {
          List<dynamic> usersList = jsonDecode(usersJson);
          for (var u in usersList) {
            if (u['email'] == _currentUserModel!.email) {
              u['teamId'] = teamId;
            }
          }
          await prefs.setString('registered_users', jsonEncode(usersList));
        }
      } catch (_) {}

      notifyListeners();
    }
  }

  Future<void> clearTeam() async {
    if (_currentUserModel != null) {
      _currentUserModel = UserModel(
        id: _currentUserModel!.id,
        email: _currentUserModel!.email,
        teamId: null,
        role: _currentUserModel!.role,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('team_id');
      } catch (_) {}

      notifyListeners();
    }
  }
}

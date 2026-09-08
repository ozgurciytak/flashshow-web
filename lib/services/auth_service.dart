import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  UserModel? _currentUserModel;
  bool _isGuest = false;
  bool _isLocalAuth = false;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isAuthenticated => _isGuest || _isLocalAuth || (_auth?.currentUser != null);
  bool get isAdmin => _currentUserModel?.role == 'admin';
  bool get isGuest => _isGuest;
  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty && _auth != null;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    // 1. Try initializing Firebase safely if configured
    try {
      if (Firebase.apps.isNotEmpty) {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _auth?.authStateChanges().listen((User? user) async {
          if (user != null) {
            _isGuest = false;
            _isLocalAuth = false;
            await _fetchUserModel(user.uid);
          } else if (!_isGuest && !_isLocalAuth) {
            _currentUserModel = null;
          }
          notifyListeners();
        });
      }
    } catch (e) {
      print('Firebase erişim hatası: $e');
      _auth = null;
      _firestore = null;
    }

    // 2. Restore local saved session if any
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
      } else if (isLoggedIn && (_auth?.currentUser == null)) {
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
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchUserModel(String uid) async {
    try {
      if (_firestore != null) {
        DocumentSnapshot doc = await _firestore!.collection('users').doc(uid).get();
        if (doc.exists) {
          _currentUserModel = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }
      }
    } catch (e) {
      print('Kullanıcı bilgisi alınamadı: $e');
    }
  }

  Future<String?> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Lütfen e-posta ve şifrenizi girin.';
    }

    // Attempt Firebase Sign In if available
    if (isFirebaseAvailable) {
      try {
        await _auth!.signInWithEmailAndPassword(email: email, password: password);
        _isGuest = false;
        _isLocalAuth = false;
        _saveLocalSession(email: email, isLocal: false);
        return null; // Başarılı
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return 'Hatalı şifre veya e-posta.';
        }
        return e.message ?? 'Giriş yapılamadı.';
      } catch (e) {
        print('Firebase giriş hatası: $e');
      }
    }

    // Fallback: Local offline authentication
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

    _saveLocalSession(email: email, uid: uid, role: role, isLocal: true);
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

    // Attempt Firebase Sign Up if available
    if (isFirebaseAvailable) {
      try {
        UserCredential cred = await _auth!.createUserWithEmailAndPassword(
          email: email, 
          password: password,
        );
        if (cred.user != null && _firestore != null) {
          try {
            await _firestore!.collection('users').doc(cred.user!.uid).set({
              'email': email,
              'role': 'user',
              'teamId': null,
            });
          } catch (e) {
            print('Firestore kullanıcı kaydı hatası: $e');
          }
        }
        _isGuest = false;
        _isLocalAuth = false;
        _saveLocalSession(email: email, uid: cred.user?.uid, isLocal: false);
        return null; // Başarılı
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return 'Bu e-posta adresi zaten kullanımda.';
        } else if (e.code == 'weak-password') {
          return 'Şifre çok zayıf (en az 6 karakter).';
        } else if (e.code == 'invalid-email') {
          return 'Geçersiz e-posta formatı.';
        }
        return e.message ?? 'Kayıt sırasında bir hata oluştu.';
      } catch (e) {
        print('Firebase kayıt hatası: $e');
      }
    }

    // Fallback: Local offline registration
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

    _saveLocalSession(email: email, uid: uid, role: role, isLocal: true);
    notifyListeners();
    return null; // Başarılı
  }

  Future<void> _saveLocalSession({
    required String email, 
    String? uid, 
    String? role, 
    required bool isLocal,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_email', email);
      if (uid != null) await prefs.setString('user_id', uid);
      if (role != null) await prefs.setString('user_role', role);
    } catch (e) {
      // ignore
    }
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
    } catch (e) {
      // ignore
    }

    try {
      await _auth?.signOut();
    } catch (e) {
      // ignore
    }
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

      // Save locally
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('team_id', teamId);
      } catch (e) {
        // ignore
      }

      // Save to Firestore if available
      if (!_isGuest && !_isLocalAuth && _firestore != null && _auth?.currentUser != null) {
        try {
          await _firestore!.collection('users').doc(_auth!.currentUser!.uid).update({
            'teamId': teamId,
          });
        } catch (e) {
          print('Takım güncellenemedi: $e');
        }
      }
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
      } catch (e) {
        // ignore
      }

      if (!_isGuest && !_isLocalAuth && _firestore != null && _auth?.currentUser != null) {
        try {
          await _firestore!.collection('users').doc(_auth!.currentUser!.uid).update({
            'teamId': null,
          });
        } catch (e) {
          // ignore
        }
      }
      notifyListeners();
    }
  }
}

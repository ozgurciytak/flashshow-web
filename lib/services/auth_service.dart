import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  UserModel? _currentUserModel;
  bool _isGuest = false;
  
  UserModel? get currentUserModel => _currentUserModel;
  bool get isAuthenticated => _isGuest || (_auth?.currentUser != null);
  bool get isAdmin => _currentUserModel?.role == 'admin';

  AuthService() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _auth?.authStateChanges().listen((User? user) async {
        if (user != null) {
          _isGuest = false;
          await _fetchUserModel(user.uid);
        } else if (!_isGuest) {
          _currentUserModel = null;
        }
        notifyListeners();
      });
    } catch (e) {
      print('Firebase başlatılamadı: $e');
    }
  }

  void loginAsGuest() {
    _isGuest = true;
    _currentUserModel = UserModel(
      id: 'guest',
      email: 'misafir@flashshow.com',
      role: 'user',
      teamId: null,
    );
    notifyListeners();
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

  Future<bool> signIn(String email, String password) async {
    try {
      if (_auth == null) return false;
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
      _isGuest = false;
      return true;
    } catch (e) {
      print('Giriş hatası: $e');
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      if (_auth == null) return false;
      UserCredential cred = await _auth!.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null && _firestore != null) {
        await _firestore!.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'role': 'user',
          'teamId': null,
        });
      }
      _isGuest = false;
      return true;
    } catch (e) {
      print('Kayıt hatası: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _isGuest = false;
    _currentUserModel = null;
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
      if (!_isGuest && _firestore != null && _auth?.currentUser != null) {
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
}

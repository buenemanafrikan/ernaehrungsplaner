import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

import '../app/constants.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  StreamSubscription<User?>? _sub;
  User? _user;

  bool _googleInitialized = false;

  AuthController({
    FirebaseAuth? auth,
    GoogleSignIn? google,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn.instance {
    _user = _auth.currentUser;
    _sub = _auth.authStateChanges().listen((u) {
      _user = u;
      notifyListeners();
    });
  }

  User? get user => _user;

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await _google.initialize(serverClientId: kServerClientId);
    _googleInitialized = true;
  }

  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleInit();

      final googleUser = await _google.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Google Login: Kein idToken erhalten.");
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
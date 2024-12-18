import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProv extends ChangeNotifier {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance; // Inisialisasi Firestore

  AuthProv() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (_user != null) {
        _getUsername(); // Get username when the user is logged in
      }
      notifyListeners(); // Notifikasi perubahan pada UI
    });
  }

  String? _username;
  String? get username => _username;

  User? _user;
  User? get user => _user;

  String? get email => _user?.email;
  String? get userPhotoUrl => _user?.photoURL;

  // Function to get the username from Firestore
  Future<void> _getUsername() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists && doc.data() is Map<String, dynamic>) {
          _username = (doc.data() as Map<String, dynamic>)['username'];
        }
      } catch (e) {
        print("Error getting username: $e");
        _username = 'Guest'; // Default to 'Guest' if an error occurs
      }
      notifyListeners(); // Notify listeners after updating the username
    }
  }

  Future<User?> signInWithUsername(String username, String password) async {
    try {
      // 1. Cari pengguna berdasarkan username
      QuerySnapshot userSnapshot = await firestore.collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that username.',
        );
      }

      // 2. Ambil email dari dokumen pengguna
      String email = userSnapshot.docs.first['email'];

      // 3. Masuk dengan email dan password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Periksa apakah userCredential berhasil login dan tidak null
      if (userCredential.user == null) {
        throw Exception("Login failed, userCredential.user is null.");
      }

      // If successfully logged in, fetch the username
      await _getUsername();

      return userCredential.user; // Kembalikan user yang berhasil login
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected error: $e");
      throw Exception("An unexpected error occurred.");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _username = null; // Clear the username when signed out
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        _user = userCredential.user;

        // Get the username after Google login
        await _getUsername();

        notifyListeners();
      }
    } catch (e) {
      print("Google Sign-In failed: $e");
      throw Exception("Google Sign-In failed: $e");
    }
  }

  Future<void> register(String username, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
        });
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      throw e;
    } catch (e) {
      print("Error saving username to Firestore: $e");
      throw e;
    }
  }

  Future<String?> getUsername() async {
    // Simulate async operation, for example, getting username from storage or API
    await Future.delayed(Duration(seconds: 2)); // Simulating network delay
    return 'YourUsername'; // Replace with actual logic to fetch the username
  }

}

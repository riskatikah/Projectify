import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthProv extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? _user;
  String? _username;
  String? _major;
  String? _description;

  AuthProv() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (_user != null) {
        _fetchUserData();
      }
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  String? get username => _username;
  String? get major => _major;
  String? get description => _description;
  String? get email => _user?.email;

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists && doc.data() is Map<String, dynamic>) {
          final data = doc.data() as Map<String, dynamic>;
          _username = data['username'];
          _major = data['major'];
          _description = data['description'];
        }
      } catch (e) {
        print("Error fetching user data: $e");
        _username = 'Guest';
        _major = '';
        _description = '';
      }
      notifyListeners();
    }
  }

  // Sign in with username and password
  Future<User?> signInWithUsername(String username, String password) async {
    try {
      QuerySnapshot userSnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found for that username.',
        );
      }

      String email = userSnapshot.docs.first['email'];

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception("Login failed, userCredential.user is null.");
      }

      await _fetchUserData();

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected error: $e");
      throw Exception("An unexpected error occurred.");
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _username = null;
    _major = null;
    _description = null;
    notifyListeners();
  }

  // Register a new user
  Future<void> register(String username, String email, String password, String major, String description) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'major': major,
          'description': description,
        });

        await _fetchUserData();
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      throw e;
    } catch (e) {
      print("Error saving data to Firestore: $e");
      throw e;
    }
  }
}

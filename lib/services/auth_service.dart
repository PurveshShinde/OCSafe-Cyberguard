import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocsafe_cyberguard/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Create User Document
  Future<void> _createUserDocument(User user, String name) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: name,
        createdAt: DateTime.now(),
      );

      await docRef.set(userModel.toMap());
    }
  }

  // Email Sign Up
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName(name);
      await _createUserDocument(user, name);
    }

    return user;
  }

  // Email Sign In
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
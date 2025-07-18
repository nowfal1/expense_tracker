import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn googlesignin = GoogleSignIn(
    clientId:
        kIsWeb
            ? '428240672889-spmenv74m5mvnlhksgi6a0pt11pcqq7j.apps.googleusercontent.com'
            : null, // for web only
    scopes: ['email', 'profile'],
  );

  Future<String?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String address,
    required String expenseType,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullname': fullName.trim(),
        'address': address.trim(),
        'expenseType': expenseType,
        'email': email.trim(),
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Something went wrong. Please try again.";
    }
  }

  static Future<UserCredential?> _signingoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googlesignin.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}

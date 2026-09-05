// ─────────────────────────────────────────────────────────────
// firebase_service.dart — FIXED VERSION
// ─────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../models/scan_result.dart';
import '../constants.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final Uuid _uuid = const Uuid();

  // ── Auth ────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String get displayName => currentUser?.displayName ?? 'User';
  String? get photoUrl => currentUser?.photoURL;

  Future<User?> signInWithGoogle() async {
    try {
      // ✅ CORRECT MODERN SIGN-IN FLOW (v7.0+)
      await _googleSignIn.initialize(serverClientId: kGoogleWebClientId);
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) return null; // cancelled

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: null, // Use null if accessToken isn't needed for basic auth
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e, stack) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      debugPrint('STACKTRACE: $stack');
      throw FirebaseServiceException('Google Sign-In failed: $e');
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      throw FirebaseServiceException('Anonymous sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Storage ─────────────────────────────────────────────

  Future<String> uploadImage(File imageFile) async {
    final uid = currentUser?.uid ?? 'anonymous';
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref('$kStorageBucket/$uid/$fileName');

    try {
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw FirebaseServiceException('Image upload failed: $e');
    }
  }

  // ── Firestore ──────────────────────────────────────────

  Future<String> saveScan(ScanResult scan) async {
    try {
      final docRef =
          await _firestore.collection(kScansCollection).add(scan.toFirestore());
      return docRef.id;
    } catch (e) {
      throw FirebaseServiceException('Could not save scan: $e');
    }
  }

  Stream<List<ScanResult>> scanHistoryStream() {
    final uid = currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection(kScansCollection)
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => ScanResult.fromFirestore(d)).toList());
  }

  Future<void> deleteScan(ScanResult scan) async {
    await _firestore.collection(kScansCollection).doc(scan.id).delete();

    if (scan.imageUrl.isNotEmpty) {
      await _storage.refFromURL(scan.imageUrl).delete();
    }
  }

  // ── User Profile ────────────────────────────────────────

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection(kUsersCollection).doc(uid).set(
        {
          ...data,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw FirebaseServiceException('Could not update profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore.collection(kUsersCollection).doc(uid).get();
      return doc.data();
    } catch (e) {
      throw FirebaseServiceException('Could not fetch profile: $e');
    }
  }
}

// ── Exception ─────────────────────────────────────────────

class FirebaseServiceException implements Exception {
  final String message;
  const FirebaseServiceException(this.message);

  @override
  String toString() => message;
}

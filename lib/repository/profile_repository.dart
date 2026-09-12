import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerProfileModel {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String photoUrl;

  OwnerProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl = '',
  });

  factory OwnerProfileModel.fromDoc(DocumentSnapshot doc, String fallbackEmail) {
    if (!doc.exists) {
      return OwnerProfileModel(
        name: 'Owner',
        email: fallbackEmail,
        phone: 'Not set',
        role: 'Owner',
      );
    }
    final d = doc.data() as Map<String, dynamic>;
    return OwnerProfileModel(
      name: d['name'] ?? d['full_name'] ?? 'Owner',
      email: d['email'] ?? fallbackEmail,
      phone: d['phone'] ?? 'Not set',
      role: d['role'] ?? 'Owner',
      photoUrl: d['photoUrl'] ?? '',
    );
  }

  factory OwnerProfileModel.placeholder() {
    return OwnerProfileModel(
      name: 'Owner Name',
      email: 'owner@example.com',
      phone: 'Not set',
      role: 'Owner',
    );
  }
}

class ProfileRepository {
  // NOTE: fixed — Firestore console confirms only a 'users' collection
  // exists, not 'owners'. Reading from 'owners' meant this stream never
  // matched the doc that _saveChanges() writes to.
  Stream<OwnerProfileModel> getOwnerProfileStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(OwnerProfileModel.placeholder());
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => OwnerProfileModel.fromDoc(doc, user.email ?? ''));
  }
}
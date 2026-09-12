import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String action;
  final String performedBy;
  final String role;
  final String details;
  final String branch;
  final DateTime createdAt;

  ActivityLogModel({
    required this.action,
    required this.performedBy,
    required this.role,
    required this.details,
    required this.branch,
    required this.createdAt,
  });

  factory ActivityLogModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ActivityLogModel(
      action: d['action'] ?? '',
      performedBy: d['performed_by'] ?? 'Unknown',
      role: d['role'] ?? 'Unknown',
      details: d['details'] ?? '',
      branch: d['branch'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
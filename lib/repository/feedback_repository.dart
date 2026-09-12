import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String orderId;
  final String message;
  final int rating;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.orderId,
    required this.message,
    required this.rating,
    required this.createdAt,
  });

  // 👈 FIXED: collection is 'reviews', fields are 'comment', 'orderId',
  // 'rating', 'createdAt' — no 'customer_name' field exists on the review
  // itself, so it's resolved separately via FeedbackRepository.getOrderInfo().
  factory FeedbackModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      orderId: (d['orderId'] ?? '').toString(),
      message: (d['comment'] ?? '').toString(),
      rating: ((d['rating'] ?? 0) as num).toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FeedbackRepository {
  final _collection = FirebaseFirestore.instance.collection('reviews');

  /// Ordered by newest first (needs a Firestore index on createdAt if it
  /// errors — Firestore's console error will give a direct link to create it).
  Stream<List<FeedbackModel>> getFeedbackStreamOrdered({int limit = 30}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeedbackModel.fromDoc(d)).toList());
  }

  /// Fallback — only used if orderBy fails (missing field/index on some docs)
  Stream<List<FeedbackModel>> getFeedbackStreamUnordered() {
    return _collection
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeedbackModel.fromDoc(d)).toList());
  }

  // 👈 NEW: reviews only store an 'orderId', so the customer's name (and
  // branchId, in case branch-filtering feedback is wanted later) is pulled
  // from the matching 'orders' document.
  Future<Map<String, String>> getOrderInfo(String orderId) async {
    if (orderId.isEmpty) return {};
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!doc.exists) return {};
      final d = doc.data() as Map<String, dynamic>;
      return {
        'customerName': (d['customer_name'] ?? 'Anonymous').toString(),
        'branchId': (d['branchId'] ?? '').toString(),
      };
    } catch (_) {
      return {};
    }
  }
}
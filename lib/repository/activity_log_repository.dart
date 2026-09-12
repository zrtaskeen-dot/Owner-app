import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/activity_log_logic.dart';

class ActivityLogRepository {
  // FIX: Firestore console mein collection ka naam "system_log" hai,
  // "activity_logs" nahi hai — isi mismatch ki wajah se data fetch
  // nahi ho raha tha (stream hamesha empty aata tha).
  final _collection = FirebaseFirestore.instance.collection('system_log');

  Stream<List<ActivityLogModel>> getLogsStream({int limit = 50}) {
    return _collection
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ActivityLogModel.fromDoc(d)).toList());
  }
}

class ActivityLogService {
  final ActivityLogRepository _repo = ActivityLogRepository();

  Stream<List<ActivityLogModel>> get logsStream => _repo.getLogsStream();
}
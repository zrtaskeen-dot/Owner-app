import 'package:flutter/material.dart';
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
      performedBy: d['performedBy'] ?? 'Unknown',
      role: d['role'] ?? '',
      details: d['details'] ?? '',
      branch: d['branch'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ActivityLogRepository {
  
  final _collection = FirebaseFirestore.instance.collection('activity_logs');

  Stream<List<ActivityLogModel>> getLogsStream({int limit = 50}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ActivityLogModel.fromDoc(d)).toList(),
        );
  }
}

class ActivityLogService {
  final ActivityLogRepository _repo = ActivityLogRepository();

  Stream<List<ActivityLogModel>> get logsStream => _repo.getLogsStream();
}

class ActivityLogTab extends StatelessWidget {
  const ActivityLogTab({super.key});

  static const bgColor =
      Colors.white; 
  static const cardColor = Color(
    0xFFFFFDFA,
  ); 
  static const maroon = Color(0xFFA70000); 
  static const primary = Color(0xFFFF8A00); 
  static const lightMaroonBorder = Color(
    0x33A70000,
  ); 
  static const textDark = Colors.black;
  static const textMuted = Colors.black54;

  @override
  Widget build(BuildContext context) {
    final ActivityLogService activityLogService = ActivityLogService();

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabHeader(
              'ACTIVITY LOG',
              'Manager & Admin actions',
              Icons.receipt_long_rounded,
            ),
            Expanded(
              child: StreamBuilder<List<ActivityLogModel>>(
                stream: activityLogService.logsStream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _errorBody('Error: ${snap.error}');
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: maroon),
                    );
                  }
                  final logs = snap.data ?? [];
                  if (logs.isEmpty) {
                    return _emptyState(
                      'No activity yet',
                      Icons.receipt_long_rounded,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _logCard(logs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logCard(ActivityLogModel log) {
    final hasBranch = log.branch.isNotEmpty;
    final hasRole = log.role.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lightMaroonBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: maroon.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: maroon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.action,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (hasRole)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: maroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.role,
                          style: const TextStyle(
                            color: maroon,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.details,
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${log.performedBy}'
                  '${hasBranch ? ' | ${log.branch}' : ''}'
                  ' • ${_formatTime(log.createdAt)}',
                  style: TextStyle(
                    color: textDark.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabHeader(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: textDark, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBody(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textDark, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: maroon.withValues(alpha: 0.25), size: 56),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(
              color: textDark.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final pkt = dt.toUtc().add(const Duration(hours: 5));

    final hour = pkt.hour == 0
        ? 12
        : (pkt.hour > 12 ? pkt.hour - 12 : pkt.hour);
    final period = pkt.hour >= 12 ? 'PM' : 'AM';
    final minute = pkt.minute.toString().padLeft(2, '0');

    return '${pkt.day}/${pkt.month}/${pkt.year} • $hour:$minute $period';
  }
}
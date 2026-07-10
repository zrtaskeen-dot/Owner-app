import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../logic/feedback_logic.dart';
import '../repository/feedback_repository.dart';

class FeedbackTab extends StatefulWidget {
  const FeedbackTab({Key? key}) : super(key: key);

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

enum _TimeFilter { allTime, today, thisWeek }

class _ReviewDisplayInfo {
  final String customerName;
  final String branchName;
  _ReviewDisplayInfo({required this.customerName, required this.branchName});
}

class _FeedbackTabState extends State<FeedbackTab> {
  final FeedbackService _feedbackService = FeedbackService();

  final Map<String, String> _nameCache = {};
  final Map<String, Future<String>> _branchNameFutures = {};

  int? _ratingFilter; 
  _TimeFilter _timeFilter = _TimeFilter.allTime;

  // Theme 
  static const bgColor = Color(0xFFFCF8DD);
  static const cardColor = Color(0xFFFFFFF0); 
  static const maroon = Color(0xFFA70000); 
  static const gold = Color(0xFFFFC107); 
  static const textDark = Colors.black;
  static const textMuted = Colors.black54;
  static const borderColor = Color(0xFFEDE6D6);

  Future<_ReviewDisplayInfo> _loadReviewInfo(FeedbackModel f) async {
    final orderInfo = await _feedbackService.getOrderInfo(f.orderId);
    final customerName = (orderInfo['customerName'] ?? 'Anonymous');
    final branchId = orderInfo['branchId'] ?? '';
    final branchName = branchId.isEmpty ? 'Main Branch' : await _resolveBranchName(branchId);

    _nameCache[f.orderId] = customerName;
    return _ReviewDisplayInfo(customerName: customerName, branchName: branchName);
  }

  Future<String> _resolveBranchName(String branchId) {
    if (_branchNameFutures.containsKey(branchId)) {
      return _branchNameFutures[branchId]!;
    }
    final future = FirebaseFirestore.instance
        .collection('restaurant_info')
        .doc(branchId)
        .get()
        .then((doc) {
      if (!doc.exists) return 'Main Branch';
      final d = doc.data() as Map<String, dynamic>;
      return (d['branchName'] ?? 'Main Branch').toString();
    }).catchError((_) => 'Main Branch');
    _branchNameFutures[branchId] = future;
    return future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: bgColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabHeader(),
            Expanded(
              child: StreamBuilder<List<FeedbackModel>>(
                stream: _feedbackService.feedbackStreamOrdered,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return StreamBuilder<List<FeedbackModel>>(
                      stream: _feedbackService.feedbackStreamUnordered,
                      builder: (context, snap2) {
                        if (snap2.hasError) {
                          return _errorBody(
                            'No feedback collection found.\nCreate a "reviews" collection in Firestore.',
                          );
                        }
                        if (!snap2.hasData || snap2.data!.isEmpty) {
                          return _emptyState('No feedback yet');
                        }
                        return _feedbackContent(snap2.data!);
                      },
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: maroon),
                    );
                  }
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return _emptyState('No feedback yet');
                  }
                  return _feedbackContent(snap.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER 
  Widget _tabHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: textDark, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FEEDBACK',
                style: TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Customer reviews & ratings',
                style: TextStyle(
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

  // ════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ════════════════════════════════════════════════════════════
  Widget _feedbackContent(List<FeedbackModel> allFeedbacks) {
    final avgRating = _feedbackService.calculateAverageRating(allFeedbacks);
    final totalReviews = allFeedbacks.length;

    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final f in allFeedbacks) {
      if (breakdown.containsKey(f.rating)) breakdown[f.rating] = breakdown[f.rating]! + 1;
    }

    final filtered = _applyFilters(allFeedbacks);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      physics: const BouncingScrollPhysics(),
      children: [
        _summaryCard(avgRating, totalReviews, breakdown),
        const SizedBox(height: 10),
        _timeFilterRow(),
        const SizedBox(height: 8),
        _ratingFilterChips(),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'No reviews match your filters',
                style: TextStyle(color: textDark.withOpacity(0.5), fontSize: 12.5),
              ),
            ),
          )
        else
          ...filtered.map((f) => _reviewCard(f)),
      ],
    );
  }

  List<FeedbackModel> _applyFilters(List<FeedbackModel> feedbacks) {
    final now = DateTime.now();

    return feedbacks.where((f) {
      if (_ratingFilter != null && f.rating != _ratingFilter) return false;

      switch (_timeFilter) {
        case _TimeFilter.today:
          if (!(f.createdAt.year == now.year &&
              f.createdAt.month == now.month &&
              f.createdAt.day == now.day)) {
            return false;
          }
          break;
        case _TimeFilter.thisWeek:
          if (now.difference(f.createdAt).inDays > 7) return false;
          break;
        case _TimeFilter.allTime:
          break;
      }

      return true;
    }).toList();
  }

  // ════════════════════════════════════════════════════════════
  // SUMMARY CARD (avg rating + breakdown) — total-reviews circle removed
  // ════════════════════════════════════════════════════════════
  Widget _summaryCard(double avgRating, int totalReviews, Map<int, int> breakdown) {
    final maxCount = breakdown.values.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left — big average number + stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: maroon,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: gold,
                    size: 13,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Based on $totalReviews',
                style: TextStyle(color: textDark.withOpacity(0.5), fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Right — breakdown bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = breakdown[star] ?? 0;
                final ratio = count / maxCount;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(color: textDark.withOpacity(0.6), fontSize: 10),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.star_rounded, color: gold, size: 10),
                      const SizedBox(width: 5),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: maroon.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation(maroon),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 16,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: textDark.withOpacity(0.6), fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // TIME FILTER (search box removed)
  // ════════════════════════════════════════════════════════════
  Widget _timeFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PopupMenuButton<_TimeFilter>(
          initialValue: _timeFilter,
          onSelected: (v) => setState(() => _timeFilter = v),
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => const [
            PopupMenuItem(value: _TimeFilter.allTime, child: Text('All Time')),
            PopupMenuItem(value: _TimeFilter.today, child: Text('Today')),
            PopupMenuItem(value: _TimeFilter.thisWeek, child: Text('This Week')),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, color: maroon, size: 13),
                const SizedBox(width: 5),
                Text(_timeFilterLabel(_timeFilter), style: const TextStyle(fontSize: 11.5, color: textDark)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: textDark, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _timeFilterLabel(_TimeFilter f) {
    switch (f) {
      case _TimeFilter.allTime:
        return 'All Time';
      case _TimeFilter.today:
        return 'Today';
      case _TimeFilter.thisWeek:
        return 'This Week';
    }
  }

  // ════════════════════════════════════════════════════════════
  // RATING FILTER CHIPS
  // ════════════════════════════════════════════════════════════
  Widget _ratingFilterChips() {
    final options = <int?>[null, 5, 4, 3, 2, 1];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final value = options[i];
          final selected = _ratingFilter == value;
          final label = value == null ? 'All' : '$value Star${value == 1 ? '' : 's'}';

          return GestureDetector(
            onTap: () => setState(() => _ratingFilter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? maroon : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? maroon : borderColor),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null) ...[
                    Icon(Icons.star_rounded, size: 12, color: selected ? Colors.white : gold),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : textDark.withOpacity(0.7),
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // REVIEW CARD
  // ════════════════════════════════════════════════════════════
  Widget _reviewCard(FeedbackModel f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: FutureBuilder<_ReviewDisplayInfo>(
        future: _loadReviewInfo(f),
        builder: (context, snap) {
          final loading = snap.connectionState == ConnectionState.waiting;
          final name = loading ? '...' : (snap.data?.customerName ?? 'Anonymous');
          final branch = loading ? '' : (snap.data?.branchName ?? 'Main Branch');
          final initial = (!loading && name.isNotEmpty) ? name[0].toUpperCase() : '?';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: maroon.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(color: maroon, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: textDark, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 11, color: textDark.withOpacity(0.4)),
                            const SizedBox(width: 3),
                            Text(
                              'Order ID: #${_shortOrderId(f.orderId)}',
                              style: TextStyle(color: textDark.withOpacity(0.5), fontSize: 10.5),
                            ),
                          ],
                        ),
                        if (branch.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 11, color: textDark.withOpacity(0.4)),
                              const SizedBox(width: 3),
                              Text(branch, style: TextStyle(color: textDark.withOpacity(0.5), fontSize: 10.5)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < f.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: gold,
                            size: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDateTime(f.createdAt),
                        style: TextStyle(color: textDark.withOpacity(0.4), fontSize: 9.5),
                      ),
                    ],
                  ),
                ],
              ),
              if (f.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  f.message,
                  style: TextStyle(color: textDark.withOpacity(0.75), fontSize: 12, height: 1.3),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _shortOrderId(String orderId) {
    return orderId.length <= 8 ? orderId : orderId.substring(0, 8);
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour12:$minute $period';
  }

  // ════════════════════════════════════════════════════════════
  // EMPTY / ERROR STATES
  // ════════════════════════════════════════════════════════════
  Widget _errorBody(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: textDark.withOpacity(0.7), fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, color: maroon.withOpacity(0.25), size: 50),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: textDark.withOpacity(0.4), fontSize: 13)),
        ],
      ),
    );
  }
}
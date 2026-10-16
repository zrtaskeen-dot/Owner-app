// ignore_for_file: avoid_print, unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_log.dart';
import 'team.dart';
import 'feedback.dart';
import 'profile.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> fetchRawOrdersSnapshot() {
    try {
      return _firestore.collection('orders').snapshots();
    } catch (e) {
      print('Repository - fetchRawOrdersSnapshot error: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> fetchRawOrdersFuture() {
    try {
      return _firestore.collection('orders').get();
    } catch (e) {
      print('Repository - fetchRawOrdersFuture error: $e');
      rethrow;
    }
  }

  
  Stream<QuerySnapshot> fetchCollectionSnapshot(String path) {
    try {
      return _firestore.collection(path).snapshots();
    } catch (e) {
      print('Repository - fetchCollectionSnapshot($path) error: $e');
      rethrow;
    }
  }

  
  Stream<DocumentSnapshot> fetchRestaurantDocument() {
    try {
      return _firestore
          .collection('restaurant_info')
          .doc('main_branch') 
          .snapshots();
    } catch (e) {
      print('Repository - fetchRestaurantDocument error: $e');
      rethrow;
    }
  }

  
  Stream<QuerySnapshot> fetchAllBranchesSnapshot() {
    try {
      return _firestore.collection('restaurant_info').snapshots();
    } catch (e) {
      print('Repository - fetchAllBranchesSnapshot error: $e');
      rethrow;
    }
  }
}

class DashboardController {
  final DashboardRepository _repository = DashboardRepository();

  
  Stream<QuerySnapshot> get ordersStream =>
      _repository.fetchRawOrdersSnapshot();


  Stream<QuerySnapshot> getCollectionStream(String path) =>
      _repository.fetchCollectionSnapshot(path);

  
  Stream<DocumentSnapshot> get restaurantInfoStream =>
      _repository.fetchRestaurantDocument();
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final DashboardController _controller;
  int _selectedIndex = 0;

  String? _selectedBranchId;
  String _selectedBranchName = 'All Branches';

  
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

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
  void initState() {
    super.initState();
    _controller = DashboardController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          const ActivityLogTab(),
          const TeamTab(),
          const FeedbackTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Activity'},
      {'icon': Icons.group_rounded, 'label': 'Team'},
      {'icon': Icons.star_rounded, 'label': 'Feedback'},
      {'icon': Icons.person_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: maroon,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _selectedIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  
  Widget _buildBranchHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_info')
          .snapshots(),
      builder: (context, snap) {
        final branchDocs = snap.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: GestureDetector(
            onTap: () => _showBranchPicker(context, branchDocs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lightMaroonBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: maroon.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: maroon,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BRANCH',
                          style: TextStyle(
                            color: textDark.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          _selectedBranchName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: maroon,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBranchPicker(
    BuildContext context,
    List<QueryDocumentSnapshot> branchDocs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Select Branch',
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _branchTile('All Branches', null),
              ...branchDocs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['branchName'] ?? 'Branch').toString();
                return _branchTile(name, doc.id);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _branchTile(String name, String? id) {
    final isSelected = _selectedBranchId == id;
    return ListTile(
      onTap: () {
        setState(() {
          _selectedBranchId = id;
          _selectedBranchName = name;
        });
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: isSelected ? maroon : Colors.black38,
      ),
      title: Text(
        name,
        style: TextStyle(
          color: textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  
  bool get _hasCustomRange => _rangeStart != null && _rangeEnd != null;

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _rangeLabel() {
    if (!_hasCustomRange) return 'All Time • Tap to pick a date range';
    return '${_formatDate(_rangeStart!)}  →  ${_formatDate(_rangeEnd!)}';
  }

  bool _dateInRange(DateTime dt) {
    if (!_hasCustomRange) return true;
    final startOfDay = DateTime(
      _rangeStart!.year,
      _rangeStart!.month,
      _rangeStart!.day,
    );
    final endOfDay = DateTime(
      _rangeEnd!.year,
      _rangeEnd!.month,
      _rangeEnd!.day,
      23,
      59,
      59,
      999,
    );
    return !dt.isBefore(startOfDay) && !dt.isAfter(endOfDay);
  }

  
  DateTime? _extractOrderDate(Map<String, dynamic> d) {
    final raw =
        d['createdAt'] ??
        d['orderDate'] ??
        d['timestamp'] ??
        d['created_at'] ??
        d['orderTime'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  void _clearRange() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

 
  Future<DateTime?> _showThemedDatePicker(DateTime initial) {
    final today = DateTime.now();
    final safeInitial = initial.isAfter(today) ? today : initial;
    return showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: DateTime(2020),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: maroon,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: maroon),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightMaroonBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 18, color: maroon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? _formatDate(value) : 'Tap to select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value != null ? textDark : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  void _openCustomRangeSheet() {
    DateTime? tempStart = _rangeStart;
    DateTime? tempEnd = _rangeEnd;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dateField(
                      label: 'Start Date',
                      value: tempStart,
                      onTap: () async {
                        final picked = await _showThemedDatePicker(
                          tempStart ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() => tempStart = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _dateField(
                      label: 'End Date',
                      value: tempEnd,
                      onTap: () async {
                        final picked = await _showThemedDatePicker(
                          tempEnd ?? tempStart ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() => tempEnd = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_rangeStart != null || _rangeEnd != null)
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: maroon.withValues(alpha: 0.4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                _clearRange();
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  color: maroon,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (_rangeStart != null || _rangeEnd != null)
                          const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: maroon,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: (tempStart != null && tempEnd != null)
                                ? () {
                                    var s = tempStart!;
                                    var e = tempEnd!;
                                    if (e.isBefore(s)) {
                                      final t = s;
                                      s = e;
                                      e = t;
                                    }
                                    setState(() {
                                      _rangeStart = s;
                                      _rangeEnd = e;
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateRangeBar() {
    return GestureDetector(
      onTap: _openCustomRangeSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _hasCustomRange ? maroon.withValues(alpha: 0.08) : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasCustomRange ? maroon : lightMaroonBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded, size: 18, color: maroon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _rangeLabel(),
                style: TextStyle(
                  color: _hasCustomRange
                      ? textDark
                      : textDark.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: _hasCustomRange
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (_hasCustomRange)
              GestureDetector(
                onTap: _clearRange,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close_rounded, size: 18, color: maroon),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.ordersStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorBody('Firestore Error: ${snap.error}');
        }

        double totalRev = 0, onlineRev = 0, codRev = 0;
        double easypaisaRev = 0, jazzcashRev = 0;
        int totalOrders = 0, onlineOrders = 0, codOrders = 0;
        int easypaisaOrders = 0, jazzcashOrders = 0;

        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            var d = doc.data() as Map<String, dynamic>;

           
            if (_hasCustomRange) {
              final orderDate = _extractOrderDate(d);
              if (orderDate == null || !_dateInRange(orderDate)) {
                continue;
              }
            }

            
            final statuses = {
              _normStatus(d['orderStatus']),
              _normStatus(d['order_status']),
            };
            final isVoid = statuses.any(
              (st) => const {
                'cancelled',
                'canceled',
                'rejected',
                'incomplete',
                'undelivered',
              }.contains(st),
            );
            if (isVoid) continue;

            final amt = ((d['totalAmount'] ?? 0) as num).toDouble();
            final branchIdOfOrder = (d['branchId'] ?? '').toString();

            if (_selectedBranchId != null &&
                branchIdOfOrder != _selectedBranchId) {
              continue;
            }

            totalRev += amt;
            totalOrders++;

            final method = (d['payment_method'] ?? '').toString().toLowerCase();
            if (method.contains('easypaisa')) {
              easypaisaRev += amt;
              easypaisaOrders++;
              onlineRev += amt;
              onlineOrders++;
            } else if (method.contains('jazzcash')) {
              jazzcashRev += amt;
              jazzcashOrders++;
              onlineRev += amt;
              onlineOrders++;
            } else if (method == 'cod' || method.contains('cash on delivery')) {
              codRev += amt;
              codOrders++;
            } else if (method == 'online') {
              onlineRev += amt;
              onlineOrders++;
            }
          }
        }

        return SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildBranchHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _buildDateRangeBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildRevenueOrdersCard(
                    totalRev,
                    onlineRev,
                    codRev,
                    totalOrders,
                    onlineOrders,
                    codOrders,
                    easypaisaRev,
                    jazzcashRev,
                    easypaisaOrders,
                    jazzcashOrders,
                    snap.connectionState == ConnectionState.waiting,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverGrid(
                  key: ValueKey('stats_${_selectedBranchId ?? 'all'}'),
                  delegate: SliverChildListDelegate([
                    _buildStatCard(
                      'CUSTOMERS',
                      'roleId',
                      'R001',
                      Icons.person_rounded,
                      maroon,
                    ),
                    _buildStatCard(
                      'RIDERS',
                      'roleId',
                      'R002',
                      Icons.directions_bike,
                      maroon,
                    ),
                    _buildStatCard(
                      'MANAGERS',
                      'roleId',
                      'R003',
                      Icons.badge_rounded,
                      maroon,
                    ),
                    _buildBranchCountCard(),
                  ]),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildBranchesOverviewCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueOrdersCard(
    double total,
    double online,
    double cod,
    int orders,
    int onlineOrders,
    int codOrders,
    double easypaisa,
    double jazzcash,
    int easypaisaOrders,
    int jazzcashOrders,
    bool loading,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightMaroonBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL REVENUE',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '(Online + COD) • ${_hasCustomRange ? 'Selected Range' : 'All Time'}',
                      style: TextStyle(
                        color: textDark.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    loading
                        ? _shimmer(width: 120, height: 32)
                        : Text(
                            'Rs. ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: maroon.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: maroon.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: maroon,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL ORDERS',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  loading
                      ? _shimmer(width: 50, height: 32)
                      : Text(
                          '$orders',
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                  const Icon(
                    Icons.shopping_bag_rounded,
                    color: maroon,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: total > 0
                      ? (online / total * 100).round().clamp(1, 99)
                      : 1,
                  child: Container(height: 6, color: maroon),
                ),
                Expanded(
                  flex: total > 0
                      ? (cod / total * 100).round().clamp(1, 99)
                      : 1,
                  child: Container(
                    height: 6,
                    color: primary.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs. ${online.toStringAsFixed(0)} Online',
                style: TextStyle(
                  color: textDark.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                'Rs. ${cod.toStringAsFixed(0)} COD',
                style: TextStyle(
                  color: textDark.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: textDark.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderCountChip(
                icon: Icons.wifi_rounded,
                label: 'Online Paid Orders',
                count: onlineOrders,
              ),
              _buildOrderCountChip(
                icon: Icons.payments_rounded,
                label: 'COD Orders',
                count: codOrders,
              ),
            ],
          ),
          if (easypaisaOrders > 0 || jazzcashOrders > 0) ...[
            const SizedBox(height: 12),
            Divider(color: textDark.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 12),
            Text(
              'ONLINE BREAKDOWN',
              style: TextStyle(
                color: textDark.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGatewayChip(
                  label: 'Easypaisa',
                  amount: easypaisa,
                  count: easypaisaOrders,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 10),
                _buildGatewayChip(
                  label: 'JazzCash',
                  amount: jazzcash,
                  count: jazzcashOrders,
                  color: maroon,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGatewayChip({
    required String label,
    required double amount,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: lightMaroonBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textDark.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rs. ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '$count orders',
              style: TextStyle(
                color: textDark.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCountChip({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: maroon),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textDark.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String roleField,
    String roleValue,
    IconData icon,
    Color accent, {
    VoidCallback? onTap,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where(roleField, isEqualTo: roleValue);

    if (_selectedBranchId != null) {
      query = query.where('branchId', isEqualTo: _selectedBranchId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        final count = snap.hasError
            ? 'Err'
            : snap.connectionState == ConnectionState.waiting
            ? '...'
            : '${snap.data?.docs.length ?? 0}';

        final card = Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lightMaroonBorder),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textDark.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(icon, color: accent, size: 20),
                ],
              ),
              if (snap.hasError)
                Tooltip(
                  message: '${snap.error}',
                  child: const Text(
                    'Err',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Text(
                  count,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        );

        if (onTap == null) return card;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: card,
        );
      },
    );
  }

  Widget _buildBranchCountCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_info')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasError
            ? 'Err'
            : snap.connectionState == ConnectionState.waiting
            ? '...'
            : '${snap.data?.docs.length ?? 0}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lightMaroonBorder),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'BRANCHES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.store_mall_directory_rounded,
                    color: maroon,
                    size: 20,
                  ),
                ],
              ),
              Text(
                count,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchesOverviewCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_info')
          .snapshots(),
      builder: (context, snap) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lightMaroonBorder),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RESTAURANT INFO',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    snap.hasData
                        ? '${snap.data!.docs.length} Branch${snap.data!.docs.length == 1 ? '' : 'es'}'
                        : '',
                    style: TextStyle(
                      color: textDark.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: maroon))
              else if (snap.hasError || (snap.data?.docs.isEmpty ?? true))
                Text(
                  'No branches found',
                  style: TextStyle(
                    color: textDark.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                )
              else
                ...List.generate(snap.data!.docs.length, (i) {
                  final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                  final branchId = snap.data!.docs[i].id;
                  final name = (d['branchName'] ?? 'Branch ${i + 1}')
                      .toString();
                  final address = (d['address'] ?? '').toString();
                  final timing = (d['timing'] ?? '').toString();

                  return Column(
                    children: [
                      if (i > 0)
                        Divider(
                          color: textDark.withValues(alpha: 0.15),
                          height: 20,
                        ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _BranchOrdersScreen(
                              branchId: branchId,
                              branchName: name,
                              rangeStart: _rangeStart,
                              rangeEnd: _rangeEnd,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: maroon.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: maroon,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: textDark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (address.isNotEmpty)
                                      Text(
                                        address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textDark.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (timing.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: maroon.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    timing,
                                    style: const TextStyle(
                                      color: maroon,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: maroon,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _errorBody(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: textDark, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _shimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: maroon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}


String _normStatus(dynamic v) => (v ?? '').toString().toLowerCase().trim();

class _BranchOrdersScreen extends StatefulWidget {
  final String branchId;
  final String branchName;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const _BranchOrdersScreen({
    required this.branchId,
    required this.branchName,
    this.rangeStart,
    this.rangeEnd,
  });

  @override
  State<_BranchOrdersScreen> createState() => _BranchOrdersScreenState();
}

class _BranchOrdersScreenState extends State<_BranchOrdersScreen> {
  static const Color maroon = Color(0xFFA70000);
  static const Color orange = Color(0xFFFF8A00);
  static const Color green = Color(0xFF2E7D32);
  static const Color cardColor = Color(0xFFFFFDFA);
  static const Color border = Color(0x33A70000);
  static const Color muted = Colors.black54;

  String _selected = 'incomplete'; 

  late final Stream<QuerySnapshot> _stream = FirebaseFirestore.instance
      .collection('orders')
      .where('branchId', isEqualTo: widget.branchId)
      .snapshots();

  bool get _hasRange => widget.rangeStart != null && widget.rangeEnd != null;

  DateTime? _orderDate(Map<String, dynamic> d) {
    final raw =
        d['createdAt'] ??
        d['orderDate'] ??
        d['timestamp'] ??
        d['created_at'] ??
        d['orderTime'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  bool _inRange(DateTime? dt) {
    if (!_hasRange) return true;
    if (dt == null) return false;
    final s = widget.rangeStart!;
    final e = widget.rangeEnd!;
    final start = DateTime(s.year, s.month, s.day);
    final end = DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
    return !dt.isBefore(start) && !dt.isAfter(end);
  }

  String _bucket(Map<String, dynamic> d) {
    final st = {_normStatus(d['orderStatus']), _normStatus(d['order_status'])};
    if (st.contains('cancelled') || st.contains('canceled')) return 'cancelled';
    if (st.contains('incomplete')) return 'incomplete';
    if (st.contains('undelivered') || st.contains('rejected')) return 'other';
    if (st.contains('delivered')) return 'completed';
    return 'other';
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _fmtDateTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    return '${_fmtDate(d)}, $h:$mm ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _reasonOf(Map<String, dynamic> d, bool incomplete) {
    if (incomplete) {
      final r = (d['incompleteReason'] ?? '').toString().trim();
      return r.isNotEmpty ? r : 'No reason recorded.';
    }
    for (final key in const [
      'cancelReason',
      'cancellationReason',
      'cancelledReason',
    ]) {
      final r = (d[key] ?? '').toString().trim();
      if (r.isNotEmpty) return r;
    }
    return (d['cancelledBy'] ?? '').toString() == 'customer'
        ? 'Cancelled by the customer.'
        : 'Cancelled by the manager (invalid payment receipt).';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.branchName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Firestore Error: ${snap.error}',
                style: const TextStyle(fontSize: 13),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: maroon),
            );
          }

          int total = 0, completed = 0;
          final incomplete = <QueryDocumentSnapshot>[];
          final cancelled = <QueryDocumentSnapshot>[];

          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            if (!_inRange(_orderDate(d))) continue;
            total++;
            switch (_bucket(d)) {
              case 'completed':
                completed++;
                break;
              case 'incomplete':
                incomplete.add(doc);
                break;
              case 'cancelled':
                cancelled.add(doc);
                break;
            }
          }

          final showing = _selected == 'incomplete' ? incomplete : cancelled;
          showing.sort((a, b) {
            final da = _orderDate(a.data() as Map<String, dynamic>);
            final db = _orderDate(b.data() as Map<String, dynamic>);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da); 
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Text(
                _hasRange
                    ? '${_fmtDate(widget.rangeStart!)}  →  ${_fmtDate(widget.rangeEnd!)}'
                    : 'All Time',
                style: const TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statTile(
                    icon: Icons.receipt_long_rounded,
                    color: maroon,
                    label: 'Total Orders',
                    count: total,
                  ),
                  const SizedBox(width: 12),
                  _statTile(
                    icon: Icons.check_circle_rounded,
                    color: green,
                    label: 'Completed',
                    count: completed,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statTile(
                    icon: Icons.error_outline_rounded,
                    color: orange,
                    label: 'Incomplete',
                    count: incomplete.length,
                    selected: _selected == 'incomplete',
                    onTap: () => setState(() => _selected = 'incomplete'),
                  ),
                  const SizedBox(width: 12),
                  _statTile(
                    icon: Icons.cancel_outlined,
                    color: maroon,
                    label: 'Cancelled',
                    count: cancelled.length,
                    selected: _selected == 'cancelled',
                    onTap: () => setState(() => _selected = 'cancelled'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    _selected == 'incomplete'
                        ? 'Incomplete Orders'
                        : 'Cancelled Orders',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: maroon.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${showing.length}',
                      style: const TextStyle(
                        color: maroon,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (showing.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _selected == 'incomplete'
                          ? 'No incomplete orders'
                          : 'No cancelled orders',
                      style: const TextStyle(color: muted, fontSize: 14),
                    ),
                  ),
                )
              else
                ...showing.map(
                  (doc) => _orderCard(
                    doc,
                    doc.data() as Map<String, dynamic>,
                    _selected == 'incomplete',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.06) : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> d,
    bool incomplete,
  ) {
    final placed = _orderDate(d);
    final eventRaw = d[incomplete ? 'incompleteAt' : 'cancelledAt'];
    final eventAt = eventRaw is Timestamp ? eventRaw.toDate() : null;
    final amt = d['totalAmount'] is num
        ? (d['totalAmount'] as num).toDouble()
        : 0.0;
    final deliveryTime = (d['deliveryTime'] ?? '').toString().trim();
    final customer = (d['customerName'] ?? d['userName'] ?? d['name'] ?? '')
        .toString()
        .trim();
    final shortId = doc.id.length > 6
        ? doc.id.substring(0, 6).toUpperCase()
        : doc.id.toUpperCase();
    final accent = incomplete ? orange : maroon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #$shortId',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                'Rs. ${amt.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: maroon,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (customer.isNotEmpty)
            _infoRow(Icons.person_outline_rounded, customer),
          if (placed != null)
            _infoRow(
              Icons.event_note_rounded,
              'Placed: ${_fmtDateTime(placed)}',
            ),
          if (deliveryTime.isNotEmpty)
            _infoRow(Icons.schedule_rounded, 'Delivery: $deliveryTime'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: const Color(0xFFF7F4F1),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incomplete
                                  ? 'INCOMPLETE REASON'
                                  : 'CANCELLATION REASON',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _reasonOf(d, incomplete),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            if (eventAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _fmtDateTime(eventAt),
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

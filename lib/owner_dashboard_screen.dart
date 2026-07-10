import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'logic/dashboard_logic.dart';
import 'activity_log.dart';
import 'team.dart';
import 'feedback.dart';
import 'profile.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  late final DashboardController _controller;
  int _selectedIndex = 0;

  String? _selectedBranchId;
  String _selectedBranchName = 'All Branches';

  // Custom date range filter 
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Palette
  static const bgColor = Color(0xFFFCF8DD);
  static const cardColor = Color(
    0xFFFFFFF0,
  ); 
  static const maroon = Color(0xFFA70000); 
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

  // BOTTOM NAVIGATION 
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
                        ? Colors.white.withOpacity(0.18)
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
                            : Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
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

  // BRANCH DROPDOWN HEADER
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
                border: Border.all(color: maroon.withOpacity(0.3)),
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
                      color: maroon.withOpacity(0.08),
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
                            color: textDark.withOpacity(0.6),
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

  // DATE RANGE FILTER 
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
          border: Border.all(color: maroon.withOpacity(0.25)),
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
                                  color: maroon.withOpacity(0.4),
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
          color: _hasCustomRange ? maroon.withOpacity(0.08) : cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasCustomRange ? maroon : maroon.withOpacity(0.25),
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
                  color: _hasCustomRange ? textDark : textDark.withOpacity(0.6),
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

            // date range filter (replaces Today/Week/Month/All)
            if (_hasCustomRange) {
              final orderDate = _extractOrderDate(d);
              if (orderDate == null || !_dateInRange(orderDate)) {
                continue;
              }
            }

            final status = (d['order_status'] ?? '').toString().toLowerCase();
            final isVoid = status == 'cancelled' || status == 'rejected';
            if (isVoid) continue;

            final amt = ((d['totalAmount'] ?? 0) as num).toDouble();
            final branchIdOfOrder = (d['branchId'] ?? '').toString();

            // the summary card at the top respects the branch dropdown
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
                      'roleID',
                      'R001',
                      Icons.person_rounded,
                      maroon,
                    ),
                    _buildStatCard(
                      'RIDERS',
                      'role',
                      'rider',
                      Icons.directions_bike,
                      maroon,
                    ),
                    _buildStatCard(
                      'MANAGERS',
                      'role',
                      'manager',
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
        border: Border.all(color: maroon.withOpacity(0.25)),
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
                        color: textDark.withOpacity(0.6),
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
                  color: maroon.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: maroon.withOpacity(0.2)),
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
                  child: Container(height: 6, color: maroon.withOpacity(0.2)),
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
                  color: textDark.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                'Rs. ${cod.toStringAsFixed(0)} COD',
                style: TextStyle(
                  color: textDark.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: textDark.withOpacity(0.15), height: 1),
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
            Divider(color: textDark.withOpacity(0.15), height: 1),
            const SizedBox(height: 12),
            Text(
              'ONLINE BREAKDOWN',
              style: TextStyle(
                color: textDark.withOpacity(0.6),
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
          color: maroon.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: maroon.withOpacity(0.15)),
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
                    color: textDark.withOpacity(0.7),
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
              style: TextStyle(color: textDark.withOpacity(0.55), fontSize: 10),
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
                    color: textDark.withOpacity(0.6),
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
    Color accent,
  ) {
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

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: maroon.withOpacity(0.25)),
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
                        color: textDark.withOpacity(0.7),
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
            border: Border.all(color: maroon.withOpacity(0.25)),
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
            border: Border.all(color: maroon.withOpacity(0.25)),
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
                      color: textDark.withOpacity(0.7),
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
                    color: textDark.withOpacity(0.6),
                    fontSize: 13,
                  ),
                )
              else
                ...List.generate(snap.data!.docs.length, (i) {
                  final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                  final name = (d['branchName'] ?? 'Branch ${i + 1}')
                      .toString();
                  final address = (d['address'] ?? '').toString();
                  final timing = (d['timing'] ?? '').toString();

                  return Column(
                    children: [
                      if (i > 0)
                        Divider(color: textDark.withOpacity(0.15), height: 20),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: maroon.withOpacity(0.08),
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
                                      color: textDark.withOpacity(0.6),
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
                                color: maroon.withOpacity(0.08),
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
                        ],
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
        color: maroon.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/team_logic.dart'; // Check this path matches your project

class TeamTab extends StatelessWidget {
  const TeamTab({Key? key}) : super(key: key);

  // ── Palette: Cream Background + Maroon Cards + Cream Accent Icons ──
  static const bgColor = Color(0xFFFCF8DD);
  static const cardColor = Color(0xFFA70000); // Brand Maroon Card Background (unified)
  static const creamAccent = Color(0xFFFFFDF0); // Cream / Ivory for icons & badges
  static const maroon = Color(0xFFA70000); // unified brand maroon
  static const textDark = Colors.black;
  static const textMuted = Colors.black54;

  @override
  Widget build(BuildContext context) {
    final TeamService teamService = TeamService();

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tabHeader(
              'TEAM',
              'Managers & Riders Overview',
              Icons.group_rounded,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: teamService.getTeamStream('users'),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _errorBody('Firebase Error: ${snap.error}');
                  }

                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: maroon),
                    );
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, directSnap) {
                        if (directSnap.hasData &&
                            directSnap.data!.docs.isNotEmpty) {
                          return _buildTeamList(directSnap.data!.docs);
                        }
                        return _emptyState(
                          'No registered managers or riders found.',
                          Icons.group_rounded,
                        );
                      },
                    );
                  }

                  return _buildTeamList(snap.data!.docs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper that builds the filtered team list ──
  Widget _buildTeamList(List<QueryDocumentSnapshot> docs) {
    final filteredDocs = docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String role = (data['role'] ?? '').toString().toLowerCase().trim();
      return role == 'manager' || role == 'rider';
    }).toList();

    if (filteredDocs.isEmpty) {
      return _emptyState('No managers or riders found', Icons.group_rounded);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        var data = filteredDocs[i].data() as Map<String, dynamic>;
        return _teamCard(data);
      },
    );
  }

  Widget _teamCard(Map<String, dynamic> data) {
    String name = data['name'] ?? data['full_name'] ?? 'Unknown Member';
    String role = data['role'] ?? 'staff';
    String phone = data['phone'] ?? 'No contact';
    String email = data['email'] ?? '';
    bool isActive = data['is_active'] ?? true;

    IconData roleIcon = role.toLowerCase().trim() == 'rider'
        ? Icons.directions_bike_rounded
        : Icons.badge_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor, // Maroon Card Background
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: creamAccent, // Cream Circle Background
              shape: BoxShape.circle,
            ),
            child: Icon(roleIcon, color: cardColor, size: 24), // Maroon Icon inside Cream Circle
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${role.toUpperCase()} • $phone',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade700 : Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'INACTIVE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HEADER (icon ab BLACK hai — pehle maroon tha)
  // ════════════════════════════════════════════════════════════
  Widget _tabHeader(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: textDark, size: 24), // maroon -> black
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

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: maroon.withOpacity(0.3), size: 56),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(color: textDark.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
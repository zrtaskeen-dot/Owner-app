// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class TeamRepository {
 
  Stream<QuerySnapshot> getCollectionStream(String collectionName) {
    return FirebaseFirestore.instance.collection(collectionName).snapshots();
  }
}


class TeamService {
  final TeamRepository _repo = TeamRepository();

  Stream<QuerySnapshot> getTeamStream(String collectionName) {
    return _repo.getCollectionStream(collectionName);
  }
}


class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  
  String? _branchId;
  String? _branchName;

 
  static const bgColor = Colors.white; 
  static const cardColor = Color(0xFFFFFDFA);
  static const maroon = Color(0xFFA70000); 
  static const primary = Color(0xFFFF8A00); 
  static const lightMaroonBorder = Color(0x33A70000); 
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
              _branchName != null
                  ? 'Managers & Riders — $_branchName'
                  : 'Managers & Riders Overview',
              Icons.group_rounded,
            ),
            _buildBranchFilter(),
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

  
  Widget _buildBranchFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurant_info')
          .snapshots(),
      builder: (context, snap) {
        final branchDocs = snap.data?.docs ?? [];
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _branchChip('All Branches', null),
              ...branchDocs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final name = (d['branchName'] ?? 'Branch').toString();
                return _branchChip(name, doc.id);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _branchChip(String name, String? id) {
    final selected = _branchId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() {
          _branchId = id;
          _branchName = id == null ? null : name;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? maroon : cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? maroon : lightMaroonBorder),
          ),
          child: Text(
            name,
            style: TextStyle(
              color: selected ? Colors.white : textDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  
  static const Map<String, String> _roleNames = {
    'R002': 'Rider',
    'R003': 'Manager',
  };

  
  Widget _buildTeamList(List<QueryDocumentSnapshot> docs) {
    final filteredDocs = docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      String roleId = (data['roleId'] ?? '').toString().trim();
      final isTeamRole = roleId == 'R002' || roleId == 'R003';
      if (!isTeamRole) return false;
      if (_branchId != null) {
        
        final userBranchId = (data['branchId'] ?? '').toString();
        final userBranchName =
            (data['branchName'] ?? '').toString().trim().toLowerCase();
        final selectedName = (_branchName ?? '').trim().toLowerCase();
        final matches =
            userBranchId == _branchId ||
            (userBranchName.isNotEmpty && userBranchName == selectedName);
        if (!matches) return false;
      }
      return true;
    }).toList();

    if (filteredDocs.isEmpty) {
      return _emptyState(
        _branchName != null
            ? 'No managers or riders in $_branchName'
            : 'No managers or riders found',
        Icons.group_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        var data = filteredDocs[i].data() as Map<String, dynamic>;
        return _teamCard(data);
      },
    );
  }

  Widget _teamCard(Map<String, dynamic> data) {
    String name = data['name'] ?? data['full_name'] ?? 'Unknown Member';
    String roleId = (data['roleId'] ?? '').toString().trim();
    String role = _roleNames[roleId] ?? 'Staff';
    String phone = data['phone'] ?? 'No contact';
    String email = data['email'] ?? '';
    bool isActive = data['is_active'] ?? true;

    IconData roleIcon = roleId == 'R002'
        ? Icons.directions_bike_rounded
        : Icons.badge_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightMaroonBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: maroon.withValues(alpha: 0.08), 
              shape: BoxShape.circle,
            ),
            child: Icon(roleIcon, color: maroon, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: textDark, 
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${role.toUpperCase()} • $phone',
                  style: const TextStyle(color: textMuted, fontSize: 12),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      color: textDark.withValues(alpha: 0.45),
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
          Icon(icon, color: maroon.withValues(alpha: 0.3), size: 56),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(color: textDark.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
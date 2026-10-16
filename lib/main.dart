import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'owner_dashboard_screen.dart';
import 'login.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isOwner(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!userDoc.exists) return false;

      final roleId = (userDoc.data()?['roleId'] ?? '').toString().trim();
      if (roleId.isEmpty) return false;

      final roleDoc = await FirebaseFirestore.instance
          .collection('user_role')
          .doc(roleId)
          .get();
      final roleName = (roleDoc.data()?['rolename'] ?? '').toString();

      return roleName.trim().toLowerCase() == 'owner';
    } catch (e) {
      debugPrint('Owner check failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = authSnap.data;

        if (user == null) {
          return const LoginScreen(role: 'owner', allowSignup: false);
        }

      
        return FutureBuilder<bool>(
          future: _isOwner(user.uid),
          builder: (context, ownerSnap) {
            if (ownerSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final isOwner = ownerSnap.data ?? false;

            if (!user.emailVerified || !isOwner) {
              FirebaseAuth.instance.signOut();
              return const LoginScreen(role: 'owner', allowSignup: false);
            }

            return const OwnerDashboardScreen();
          },
        );
      },
    );
  }
}

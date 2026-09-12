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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Firebase abhi check kar raha hai ke persisted session hai ya nahi
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = authSnap.data;

        // Koi session nahi mili → Login screen
        if (user == null) {
          return const LoginScreen(
            role: 'owner',
            allowSignup: false,
          );
        }

        // Session mili — lekin owner role + emailVerified dobara verify karein
        // (login.dart wale checks yahan bhi zaroori hain, kyunke authStateChanges
        // sirf ye batata hai ke Firebase login hai, role/verification nahi)
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, docSnap) {
            if (docSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final doc = docSnap.data;
            final isOwner =
                doc != null && doc.exists && doc['role'] == 'owner';

            if (!user.emailVerified || !isOwner) {
              // Ghalat role ya unverified — sign out kar ke Login par bhej dein
              FirebaseAuth.instance.signOut();
              return const LoginScreen(
                role: 'owner',
                allowSignup: false,
              );
            }

            return const OwnerDashboardScreen();
          },
        );
      },
    );
  }
}
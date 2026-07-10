import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'forgot_password.dart';
import 'owner_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  final bool allowSignup;
  final bool skipFirestoreCheck;

  const LoginScreen({
    super.key,
    required this.role,
    required this.allowSignup,
    this.skipFirestoreCheck = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Theme 
  static const bgColor = Colors.white;
  static const Color themeColor = Color(0xFFA70000);
  static const Color creamColor = Color(0xFFFEF9E7);
  static const Color fieldColor = Color(0xFFFFFDFA);

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9]+([._%+\-][a-zA-Z0-9]+)*@(gmail|yahoo|hotmail|outlook)\.com$',
    caseSensitive: false,
  );

  static final List<TextInputFormatter> _emailInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._%+\-@]')),
  ];

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(v)) {
      return 'Use a valid Gmail, Yahoo, Hotmail or Outlook email';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAlertDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        content: Text(message, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // EMAIL & PASSWORD 
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      await user!.reload();

      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _showAlertDialog(
          "Email Not Verified",
          "Your email address has not been verified yet.\n\n"
              "Please check your email inbox and click the verification link "
              "to activate your account.",
        );
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();
        _showAlertDialog(
          "Account Not Found",
          "No account record was found for this user.\n\n"
              "Please contact the admin.",
        );
        return;
      }

      final roleId = (doc.data()?['roleId'] ?? '').toString();

      String roleName = '';
      if (roleId.isNotEmpty) {
        final roleDoc = await FirebaseFirestore.instance
            .collection('user_role')
            .doc(roleId)
            .get();
        roleName = (roleDoc.data()?['rolename'] ?? '').toString();
      }

      if (roleName.trim().toLowerCase() != 'owner') {
        await FirebaseAuth.instance.signOut();
        _showAlertDialog(
          "Access Denied",
          "This account does not have owner access.\n\n"
              "Please use a valid owner account to login.",
        );
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'emailVerified': true},
      );

      //  activity log
      try {
        final ownerName =
            (doc.data()?['name'] ??
                    doc.data()?['full_name'] ??
                    user.email ??
                    'Owner')
                .toString();

        await FirebaseFirestore.instance.collection("system_logs").add({
          'action': 'Owner Login',
          'performedBy': ownerName,
          'role': 'Owner',
          'details': 'Owner "$ownerName" logged in to the system',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Owner login log failed: $e');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No account found with this email address.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address entered is not valid.";
      } else if (e.code == 'user-disabled') {
        errorMessage =
            "This account has been disabled. Please contact the administrator.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many failed attempts. Please try again later.";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "Check your internet connection.";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "Invalid email or password.";
      }
      _showAlertDialog("Login Failed", errorMessage);
    } catch (e) {
      _showAlertDialog("Error", "An error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWaveHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.brown.shade900,
                        ),
                      ),
                      const SizedBox(height: 22),

                      _buildUnderlineField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: _emailInputFormatters,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 22),
                      _buildUnderlineField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.brown.shade300,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) => v != null && v.length < 6
                            ? 'Min 6 characters'
                            : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPassword(),
                            ),
                          ),
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: 220,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: creamColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: creamColor,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      if (widget.allowSignup) ...[
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.brown.shade400),
                            ),
                            TextButton(
                              onPressed: () {

                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Sign up",
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildWaveHeader(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.brown.shade900,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: creamColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: themeColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Welcome back, Owner',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.brown.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Log in to manage your restaurant',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {

    OutlineInputBorder box(Color color, [double width = 1.0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      validator: validator,
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
        border: box(Colors.black38),
        enabledBorder: box(Colors.black38),
        focusedBorder: box(themeColor, 1.6),
      ),
    );
  }
}
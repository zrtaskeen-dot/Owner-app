import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class OwnerProfileModel {
  final String name;
  final String email;
  final String phone;
  final String role;
  final String photoUrl;

  OwnerProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl = '',
  });

  factory OwnerProfileModel.fromDoc(
    DocumentSnapshot doc,
    String fallbackEmail,
  ) {
    if (!doc.exists) {
      return OwnerProfileModel(
        name: 'Owner',
        email: fallbackEmail,
        phone: 'Not set',
        role: 'Owner',
      );
    }
    final d = doc.data() as Map<String, dynamic>;
    return OwnerProfileModel(
      name: d['name'] ?? d['full_name'] ?? 'Owner',
      email: d['email'] ?? fallbackEmail,
      phone: d['phone'] ?? 'Not set',
      role: d['role'] ?? 'Owner',
      photoUrl: d['photoUrl'] ?? '',
    );
  }

  factory OwnerProfileModel.placeholder() {
    return OwnerProfileModel(
      name: 'Owner Name',
      email: 'owner@example.com',
      phone: 'Not set',
      role: 'Owner',
    );
  }
}

class ProfileRepository {
  
  Stream<OwnerProfileModel> getOwnerProfileStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(OwnerProfileModel.placeholder());
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => OwnerProfileModel.fromDoc(doc, user.email ?? ''));
  }
}

class ProfileService {
  final ProfileRepository _repo = ProfileRepository();

  Stream<OwnerProfileModel> get profileStream => _repo.getOwnerProfileStream();
}


class _CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < newValue.text.length; i++) {
      final ch = newValue.text[i];
      if (ch.trim().isEmpty) {
        buffer.write(ch);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(ch.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(ch.toLowerCase());
      }
    }

    return newValue.copyWith(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ProfileService _profileService = ProfileService();

  bool _isUploadingPhoto = false;
  bool _isLoggingOut = false;

  static const bgColor = Colors.white;
  static const cardColor = Color(0xFFFFFDFA);
  static const primary = Color(0xFFA70000); 


  static const int _maxPhoneDigits = 11;

  static const _cloudName = 'dqjqkwwwh';
  static const _uploadPreset = 'rider_profiles';

  
  String _phoneDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > _maxPhoneDigits) {
      // '+92xxxxxxxxxx' (12 digits) -> '0xxxxxxxxxx'
      if (digits.startsWith('92') && digits.length == 12) {
        digits = '0${digits.substring(2)}';
      } else {
        digits = digits.substring(digits.length - _maxPhoneDigits);
      }
    }
    return digits;
  }

  // Image picker
  Future<void> _pickAndUploadPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = user.uid
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final imageUrl = data['secure_url'] as String;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': imageUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile photo updated',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.black87,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // logout
  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Logged out successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primary,
        ),
      );

     
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  
  void _editField(String fieldKey, String fieldLabel, String currentValue) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isPhone = fieldKey == 'phone';
    final isName = fieldKey == 'name';

    var initial = currentValue == 'Not set' ? '' : currentValue;
    if (isPhone) initial = _phoneDigits(initial);
    final controller = TextEditingController(text: initial);

    final iconMap = {
      'name': Icons.person_outline_rounded,
      'phone': Icons.phone_outlined,
    };

    
    String? fieldError;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, _) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconMap[fieldKey] ?? Icons.edit_outlined,
                          color: Colors.black54,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Edit $fieldLabel',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Update your $fieldLabel below',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: isPhone
                            ? TextInputType.phone
                            : TextInputType.text,
                        textCapitalization: isName
                            ? TextCapitalization.words
                            : TextCapitalization.none,
                        maxLength: isPhone ? _maxPhoneDigits : null,
                        inputFormatters: isPhone
                            ? [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  _maxPhoneDigits,
                                ),
                              ]
                            : (isName ? [_CapitalizeWordsFormatter()] : null),
                        onChanged: (_) {
                          if (fieldError != null) {
                            setDialogState(() => fieldError = null);
                          }
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            iconMap[fieldKey] ?? Icons.edit_outlined,
                            color: Colors.black45,
                            size: 20,
                          ),
                          hintText: 'Enter $fieldLabel',
                          counterText: isPhone ? '' : null,
                          errorText: fieldError,
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFDDDDDD),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final newVal = controller.text.trim();

                                if (newVal.isEmpty) {
                                  setDialogState(
                                    () => fieldError =
                                        '$fieldLabel cannot be empty',
                                  );
                                  return;
                                }

                                Navigator.pop(ctx);

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                        fieldKey: newVal,
                                      }, SetOptions(merge: true));

                                 
                                  if (isName) {
                                    await user.updateDisplayName(newVal);
                                  }

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$fieldLabel updated successfully',
                                      ),
                                      backgroundColor: primary,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Update failed: $e'),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  
  static const TextStyle _fieldTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  InputDecoration _boxDecoration(
    String label,
    IconData icon, {
    bool locked = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1.0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: primary),
      suffixIcon: locked
          ? const Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: Colors.black26,
            )
          : null,
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: border(Colors.black38),
      enabledBorder: border(Colors.black38),
      disabledBorder: border(Colors.black38),
      focusedBorder: border(primary, 1.6),
    );
  }

  
  Widget _profileFieldBox({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final locked = onTap == null;
    final field = TextFormField(
      key: ValueKey('$label:$value'),
      initialValue: value,
      readOnly: true,
      enabled: !locked,
      style: _fieldTextStyle,
      decoration: _boxDecoration(label, icon, locked: locked).copyWith(
        suffixIcon: locked
            ? const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Colors.black26,
              )
            : const Icon(Icons.edit_outlined, size: 18, color: Colors.black38),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: locked
          ? field
          : GestureDetector(
              onTap: onTap,
              child: AbsorbPointer(child: field),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SafeArea(
        child: StreamBuilder<OwnerProfileModel>(
          stream: _profileService.profileStream,
          builder: (context, snap) {
            final profile = snap.data ?? OwnerProfileModel.placeholder();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),

                  
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: primary,
                          child: CircleAvatar(
                            radius: 49,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: profile.photoUrl.isNotEmpty
                                ? NetworkImage(profile.photoUrl)
                                : null,
                            child: profile.photoUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _profileFieldBox(
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: profile.name,
                          onTap: () =>
                              _editField('name', 'Full Name', profile.name),
                        ),
                        _profileFieldBox(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: profile.phone,
                          onTap: () => _editField(
                            'phone',
                            'Phone Number',
                            profile.phone,
                          ),
                        ),
                        _profileFieldBox(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: profile.email,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  //  Logout Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      fixedSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    icon: _isLoggingOut
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: _isLoggingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    onPressed: _isLoggingOut ? null : _logout,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

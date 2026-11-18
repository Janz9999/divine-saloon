// lib/customer/profile/edit_profile_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_store.dart';
import 'profile_ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profile = CustomerProfile.instance;
  final _formKey = GlobalKey<FormState>();
  late final _fullName = TextEditingController(text: _profile.fullName);
  late final _preferred = TextEditingController(text: _profile.preferredName);
  late final _about = TextEditingController(text: _profile.about);
  Uint8List? _newPhoto;

  @override
  void dispose() {
    _fullName.dispose();
    _preferred.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _newPhoto = bytes);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not open your photos');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _profile.update(() {
      _profile.fullName = _fullName.text.trim();
      _profile.preferredName = _preferred.text.trim();
      _profile.about = _about.text.trim();
      if (_newPhoto != null) _profile.photoBytes = _newPhoto;
    });
    Navigator.pop(context);
    showSnack(context, 'Profile saved');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ProfilePage(
        title: 'Edit profile',
        subtitle: 'A profile that feels like you.',
        buttonLabel: 'Save changes',
        onButton: _save,
        caption: 'Your details are only shared with your salon.',
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _changePhoto,
                  child: _newPhoto != null
                      ? ClipOval(
                          child: Image.memory(
                            _newPhoto!,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const ProfileAvatar(size: 112),
                ),
                const SizedBox(height: 8),
                LinkText('Change photo', onTap: _changePhoto),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PField(
            label: 'Full name',
            controller: _fullName,
            capitalization: TextCapitalization.words,
            validator: (v) =>
                (v ?? '').trim().length < 2 ? 'Please enter your name' : null,
          ),
          PField(
            label: 'Preferred name',
            controller: _preferred,
            hint: 'What should we call you?',
            capitalization: TextCapitalization.words,
          ),
          PField(
            label: 'A little about you',
            controller: _about,
            hint: 'e.g. A good hair day makes everything better.',
            maxLines: 3,
          ),
          const Text(
            'Your name and photo help your stylist recognise you.',
            style: TextStyle(fontSize: 13, color: PColors.muted),
          ),
          const SizedBox(height: 28),
          SoftBox(
            title: 'Part of the Divine circle',
            text: 'A little self-care, since ${_profile.memberSince}.',
          ),
        ],
      ),
    );
  }
}

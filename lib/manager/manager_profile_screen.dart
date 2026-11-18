// lib/manager/manager_profile_screen.dart
//
// Profile tab: the manager's photo, name, bio, position and skills.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'manager_store.dart';
import 'manager_ui.dart';
import '../theme/app_text.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final _p = ManagerProfile.instance;
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _p.fullName);
  late final _bio = TextEditingController(text: _p.bio);
  late final _position = TextEditingController(text: _p.position);
  late final _skills = TextEditingController(text: _p.skills);

  @override
  void dispose() {
    for (final c in [_name, _bio, _position, _skills]) {
      c.dispose();
    }
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
      _p.update(() => _p.photoBytes = bytes);
    } catch (_) {
      if (mounted) mSnack(context, 'Could not open your photos');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _p.update(() {
      _p.fullName = _name.text.trim();
      _p.bio = _bio.text.trim();
      _p.position = _position.text.trim();
      _p.skills = _skills.text.trim();
    });
    mSnack(context, 'Profile saved');
  }

  Future<void> _logOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MColors.card,
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay', style: TextStyle(color: MColors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: MColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.popUntil(context, (r) => r.isFirst); // back to Welcome
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          const Text('Edit profile', style: mTitle),
          const SizedBox(height: 10),
          const Text('Keep your manager details up to date.', style: mSubtitle),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: _p,
            builder: (context, _) => MCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _changePhoto,
                    child: const ManagerAvatar(size: 92),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _p.fullName,
                          style: const TextStyle(
                            fontFamily: AppFonts.heading,
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: MColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_p.position.isEmpty ? 'Manager' : _p.position} · Manager access',
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: MColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        MLink('Change photo', size: 14.5, onTap: _changePhoto),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('PERSONAL INFORMATION', style: mCaps),
          const SizedBox(height: 16),
          MField(
            label: 'Full name',
            controller: _name,
            capitalization: TextCapitalization.words,
            validator: (v) =>
                (v ?? '').trim().length < 2 ? 'Please enter your name' : null,
          ),
          MField(
            label: 'Bio',
            controller: _bio,
            hint: 'Add a short bio about yourself',
            maxLines: 3,
          ),
          MField(
            label: 'Position',
            controller: _position,
            hint: 'e.g. Owner',
            capitalization: TextCapitalization.words,
          ),
          MField(
            label: 'Skills',
            controller: _skills,
            hint: 'Add your areas of expertise',
          ),
          const SizedBox(height: 10),
          MPrimaryButton('Save changes', onPressed: _save),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Your team can see your name and position.',
              style: TextStyle(fontSize: 13.5, color: MColors.muted),
            ),
          ),
          const SizedBox(height: 26),
          Center(child: MLink('Log out', onTap: _logOut)),
        ],
      ),
    );
  }
}

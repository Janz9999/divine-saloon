// lib/worker/worker_profile_screen.dart
//
// Worker "Edit profile": photo, name, bio, position and skills.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../manager/manager_ui.dart' show MField;
import 'worker_ui.dart';
import '../theme/app_text.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  static const _suggested = [
    'Hair color',
    'Styling',
    'Cutting',
    'Blow dry',
    'Nails',
    'Makeup',
  ];

  final _p = WorkerProfile.instance;
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _p.name);
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

  List<String> get _skillList => _skills.text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _addSkill(String s) {
    if (_skillList.any((x) => x.toLowerCase() == s.toLowerCase())) return;
    setState(() => _skills.text = [..._skillList, s].join(', '));
  }

  Future<void> _changePhoto() async {
    try {
      final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      _p.update(() => _p.photoBytes = bytes);
    } catch (_) {
      if (mounted) wSnack(context, 'Could not open your photos');
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _p.update(() {
      _p.name = _name.text.trim();
      _p.bio = _bio.text.trim();
      _p.position = _position.text.trim();
      _p.skills = _skillList.join(', ');
    });
    wSnack(context, 'Profile saved');
  }

  Future<void> _logOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WColors.card,
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay', style: TextStyle(color: WColors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: WColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _suggested
        .where(
          (s) => !_skillList.any((x) => x.toLowerCase() == s.toLowerCase()),
        )
        .toList();
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Center(
            child: Text(
              'Edit profile',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: WColors.text,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _changePhoto,
              child: const WorkerAvatar(size: 116),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: _changePhoto,
              style: FilledButton.styleFrom(
                backgroundColor: WColors.primarySoft,
                foregroundColor: WColors.primary,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Change photo'),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your professional profile',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: WColors.primary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Add details so clients can get to know you.',
                  style: TextStyle(fontSize: 13, color: WColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          MField(
            label: 'Name',
            controller: _name,
            hint: 'Add…',
            capitalization: TextCapitalization.words,
            validator: (v) =>
                (v ?? '').trim().length < 2 ? 'Please enter your name' : null,
          ),
          MField(label: 'Bio', controller: _bio, hint: 'Add…', maxLines: 3),
          MField(
            label: 'Position',
            controller: _position,
            hint: 'Add…',
            capitalization: TextCapitalization.words,
          ),
          MField(
            label: 'Skills',
            controller: _skills,
            hint: 'e.g. Cutting, Hair color',
          ),
          if (remaining.isNotEmpty) ...[
            const Text(
              'Suggested skills',
              style: TextStyle(fontSize: 13, color: WColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in remaining)
                  ActionChip(
                    label: Text('+ $s'),
                    backgroundColor: WColors.card,
                    side: const BorderSide(color: WColors.border),
                    shape: const StadiumBorder(),
                    labelStyle: const TextStyle(
                      color: WColors.primary,
                      fontSize: 13,
                    ),
                    onPressed: () => _addSkill(s),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          WPrimaryButton('Save', onPressed: _save),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Your changes are saved when you tap Save.',
              style: TextStyle(fontSize: 12.5, color: WColors.muted),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton(
              onPressed: _logOut,
              child: const Text(
                'Log out',
                style: TextStyle(color: WColors.accent, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

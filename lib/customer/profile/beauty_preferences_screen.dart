// lib/customer/profile/beauty_preferences_screen.dart

import 'package:flutter/material.dart';

import 'profile_store.dart';
import 'profile_ui.dart';

class BeautyPreferencesScreen extends StatefulWidget {
  const BeautyPreferencesScreen({super.key});

  @override
  State<BeautyPreferencesScreen> createState() =>
      _BeautyPreferencesScreenState();
}

class _BeautyPreferencesScreenState extends State<BeautyPreferencesScreen> {
  static const List<String> _textures = ['Straight', 'Wavy', 'Curly', 'Coily'];

  final _profile = CustomerProfile.instance;
  late String _texture = _profile.hairTexture;
  late final _length = TextEditingController(text: _profile.hairLength);
  late final _goals = TextEditingController(text: _profile.hairGoals);
  late final _stylist = TextEditingController(text: _profile.preferredStylist);
  late final _allergies = TextEditingController(text: _profile.allergies);
  late final _notes = TextEditingController(text: _profile.stylistNotes);

  @override
  void dispose() {
    for (final c in [_length, _goals, _stylist, _allergies, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    _profile.update(() {
      _profile.hairTexture = _texture;
      _profile.hairLength = _length.text.trim();
      _profile.hairGoals = _goals.text.trim();
      _profile.preferredStylist = _stylist.text.trim();
      _profile.allergies = _allergies.text.trim();
      _profile.stylistNotes = _notes.text.trim();
    });
    Navigator.pop(context);
    showSnack(context, 'Preferences saved');
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePage(
      title: 'Beauty preferences',
      subtitle: 'Your hair, your way. We’ll remember the details.',
      buttonLabel: 'Save preferences',
      onButton: _save,
      caption: 'Your stylist can review these before your visit.',
      children: [
        const Text(
          'Hair texture',
          style: TextStyle(fontSize: 13.5, color: PColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _textures)
              ChoiceChip(
                label: Text(t),
                selected: _texture == t,
                showCheckmark: false,
                onSelected: (on) => setState(() => _texture = on ? t : ''),
                backgroundColor: Colors.white,
                selectedColor: PColors.green,
                labelStyle: TextStyle(
                  fontSize: 14.5,
                  color: _texture == t ? Colors.white : PColors.text,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: _texture == t ? PColors.green : PColors.border,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        PField(
          label: 'Hair length',
          controller: _length,
          hint: 'e.g. Shoulder length',
        ),
        PField(
          label: 'Hair goals',
          controller: _goals,
          hint: 'e.g. Healthy shine · Less frizz',
        ),
        PField(
          label: 'Preferred stylist',
          controller: _stylist,
          hint: 'Anyone is fine',
          capitalization: TextCapitalization.words,
        ),
        PField(
          label: 'Allergies & sensitivities',
          controller: _allergies,
          hint: 'e.g. Sensitive scalp. Please use fragrance-free products.',
          maxLines: 3,
        ),
        PField(
          label: 'Anything else for your stylist?',
          controller: _notes,
          hint: 'e.g. I love a soft, natural finish.',
          maxLines: 3,
        ),
      ],
    );
  }
}

// lib/customer/profile/personal_details_screen.dart

import 'package:flutter/material.dart';

import 'profile_store.dart';
import 'profile_ui.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  static const List<String> _genders = [
    'Woman',
    'Man',
    'Non-binary',
    'Prefer not to say',
  ];

  final _profile = CustomerProfile.instance;
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: _profile.email);
  late final _phone = TextEditingController(text: _profile.phone);
  late final _address = TextEditingController(text: _profile.address);
  late final _birthdayText = TextEditingController(
    text: _profile.birthday == null ? '' : _birthdayLabel(_profile.birthday!),
  );
  late DateTime? _birthday = _profile.birthday;
  late String? _gender = _profile.gender.isEmpty ? null : _profile.gender;

  static String _birthdayLabel(DateTime d) =>
      '${d.day} ${monthsLong[d.month - 1]} ${d.year}';

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _birthdayText.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayText.text = _birthdayLabel(picked);
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _profile.update(() {
      _profile.email = _email.text.trim();
      _profile.phone = _phone.text.trim();
      _profile.birthday = _birthday;
      _profile.gender = _gender ?? '';
      _profile.address = _address.text.trim();
    });
    Navigator.pop(context);
    showSnack(context, 'Details saved');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ProfilePage(
        title: 'Personal details',
        subtitle: 'So we can take better care of you.',
        buttonLabel: 'Save details',
        onButton: _save,
        caption: 'You can update your information at any time.',
        children: [
          PField(
            label: 'Email address',
            controller: _email,
            keyboard: TextInputType.emailAddress,
            capitalization: TextCapitalization.none,
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                ? null
                : 'Enter a valid email',
          ),
          PField(
            label: 'Phone number',
            controller: _phone,
            hint: '07123 456789',
            keyboard: TextInputType.phone,
          ),
          PField(
            label: 'Birthday',
            controller: _birthdayText,
            hint: 'Choose a date',
            readOnly: true,
            onTap: _pickBirthday,
            suffix: const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: PColors.muted,
            ),
            helper: 'A little birthday treat, just for you.',
          ),
          const Text(
            'Gender (optional)',
            style: TextStyle(fontSize: 13.5, color: PColors.muted),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            hint: const Text('Select'),
            icon: const Icon(Icons.keyboard_arrow_down, color: PColors.muted),
            decoration: pInputDecoration(),
            style: const TextStyle(fontSize: 15.5, color: PColors.text),
            items: [
              for (final g in _genders)
                DropdownMenuItem(value: g, child: Text(g)),
            ],
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 18),
          PField(
            label: 'Home address (optional)',
            controller: _address,
            hint: 'Street, town, postcode',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your information stays private.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: PColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We use these details for appointment updates and a more personal salon experience.',
            style: TextStyle(fontSize: 13, color: PColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

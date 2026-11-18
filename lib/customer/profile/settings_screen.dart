// lib/customer/profile/settings_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_store.dart';
import 'profile_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.bg,
        title: Text('Log out?', style: serif(22)),
        content: const Text('You can sign back in at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: PColors.brown),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.popUntil(
        context,
        (r) => r.isFirst,
      ); // back to the welcome screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = CustomerProfile.instance;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => ProfilePage(
        title: 'Settings',
        subtitle: 'Make Divine work for you.',
        children: [
          Text('Notifications', style: serif(22)),
          const SizedBox(height: 12),
          PCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Column(
              children: [
                _toggle(
                  'Appointment reminders',
                  'Stay on top of your next visit',
                  p.appointmentReminders,
                  (v) => p.update(() => p.appointmentReminders = v),
                ),
                const Divider(height: 1, color: PColors.border),
                _toggle(
                  'Offers & salon news',
                  'A little inspiration in your inbox',
                  p.offersAndNews,
                  (v) => p.update(() => p.offersAndNews = v),
                ),
                const Divider(height: 1, color: PColors.border),
                _toggle(
                  'Rewards updates',
                  'Know when a treat is ready',
                  p.rewardsUpdates,
                  (v) => p.update(() => p.rewardsUpdates = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text('Account & support', style: serif(22)),
          const SizedBox(height: 12),
          PCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Column(
              children: [
                _link(context, 'Password & security', 'Manage your sign-in'),
                const Divider(height: 1, color: PColors.border),
                _link(context, 'Language', 'English (UK)'),
                const Divider(height: 1, color: PColors.border),
                _link(context, 'Help & support', 'We’re here for you'),
                const Divider(height: 1, color: PColors.border),
                _link(context, 'Privacy & terms', 'How we care for your data'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          OutlinedButton(
            onPressed: () => _logOut(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: PColors.brown,
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: PColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Log out'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Divine Aesthetics & Beauty · Version 1.0.0',
            style: TextStyle(fontSize: 12.5, color: PColors.muted),
          ),
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'A little care, every day.',
              style: TextStyle(color: PColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, color: PColors.text),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: PColors.muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: PColors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String title, String subtitle) {
    return InkWell(
      onTap: () => showSnack(context, '$title — coming soon'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, color: PColors.text),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: PColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PColors.text),
          ],
        ),
      ),
    );
  }
}

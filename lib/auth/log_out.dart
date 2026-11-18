// lib/auth/log_out.dart
//
// Shared "Log out?" confirm → Firebase sign-out → back to the Welcome screen.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> confirmAndLogOut(
  BuildContext context, {
  Color? dialogColor,
  Color? accentColor,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: dialogColor,
      title: const Text('Log out?'),
      content: const Text('You can sign back in at any time.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Log out',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  if (ok != true) return;
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    Navigator.popUntil(context, (r) => r.isFirst); // back to Welcome
  }
}

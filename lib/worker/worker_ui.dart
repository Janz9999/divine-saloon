// lib/worker/worker_ui.dart
//
// Worker (stylist) colours, profile and small shared widgets.
// Workers see bookings once the manager has confirmed them.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import '../data/session.dart';
import '../manager/manager_ui.dart' show initialsOf;
import '../theme/app_text.dart';

class WColors {
  WColors._();
  static const bg = Color(0xFFF3F5F4);
  static const card = Color(0xFFFFFFFF);
  static const dark = Color(0xFF1F3D3A); // stats card
  static const primary = Color(0xFF2E6B62); // buttons
  static const primarySoft = Color(0xFFE5EFEC);
  static const accent = Color(0xFFD9663F); // active tab, highlights
  static const accentSoft = Color(0xFFFBE8E0);
  static const amber = Color(0xFFB7791F);
  static const amberSoft = Color(0xFFFBF1DC);
  static const text = Color(0xFF1A2230);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFFA3A9B3);
  static const border = Color(0xFFE3E7E5);
}

// ───────────────────────── Worker profile ─────────────────────────

/// Saved in the worker's own users/{uid} document (photo in Firebase Storage).
class WorkerProfile extends ChangeNotifier with FirestoreProfile {
  WorkerProfile._() {
    bindToSession();
  }
  static final WorkerProfile instance = WorkerProfile._();

  String name = '';
  String bio = '';
  String position = 'Stylist';
  String skills = '';
  Uint8List? photoBytes;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  // update(change) comes from FirestoreProfile: applies, rebuilds, saves.

  @override
  Uint8List? get photo => photoBytes;
  @override
  set photo(Uint8List? bytes) => photoBytes = bytes;

  @override
  void resetFields() {
    name = '';
    bio = '';
    position = 'Stylist';
    skills = '';
  }

  @override
  void applyData(SessionUser user) {
    final d = user.data;
    name = d['name'] as String? ?? user.email.split('@').first;
    bio = d['bio'] as String? ?? '';
    position = d['position'] as String? ?? 'Stylist';
    skills = d['skills'] as String? ?? '';
  }

  @override
  Map<String, dynamic> toData() => {
    'name': name.trim(),
    'bio': bio.trim(),
    'position': position.trim(),
    'skills': skills.trim(),
  };
}

// ───────────────────────── Worker alerts ─────────────────────────

/// Which salon updates matter to workers, and which ones they've seen.
/// "Seen" is saved per worker in users/{uid}.seenAlerts.
class WorkerAlerts {
  WorkerAlerts._() {
    Session.instance.user.addListener(_load);
    _load(); // catch up if someone is already signed in
  }

  void _load() {
    final ids =
        Session.instance.user.value?.data['seenAlerts'] as List<dynamic>?;
    seen.value = {...?ids?.whereType<String>()};
  }

  static final WorkerAlerts instance = WorkerAlerts._();

  final ValueNotifier<Set<String>> seen = ValueNotifier<Set<String>>(
    <String>{},
  );

  /// New confirmed bookings, changes to confirmed bookings, team & inventory events.
  List<SalonActivity> items() {
    final all = BookingStore.instance.activity.value;
    final accepted = {
      for (final a in all)
        if (a.kind == ActivityKind.accepted) a.bookingRef,
    };
    return all.where((a) {
      switch (a.kind) {
        case ActivityKind.accepted:
        case ActivityKind.team:
        case ActivityKind.inventory:
          return true;
        case ActivityKind.cancelled:
        case ActivityKind.rescheduled:
          return accepted.contains(
            a.bookingRef,
          ); // only bookings the team was told about
        default:
          return false;
      }
    }).toList();
  }

  int unread() => items().where((a) => !seen.value.contains(a.id)).length;

  void markAllSeen() {
    // Only keep ids that are still in the feed, so the saved list stays small.
    _save({for (final a in items()) a.id});
  }

  void markSeen(String id) {
    if (seen.value.contains(id)) return;
    final current = {
      for (final a in BookingStore.instance.activity.value) a.id,
    };
    _save({...seen.value.where(current.contains), id});
  }

  void _save(Set<String> ids) {
    seen.value = ids;
    Session.instance.userDoc
        ?.set({'seenAlerts': ids.toList()}, SetOptions(merge: true))
        .catchError((Object e) => debugPrint('WorkerAlerts: save failed: $e'));
  }
}

// ───────────────────────── Formatting ─────────────────────────

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Mon, Oct 12"
String wDate(DateTime d) =>
    '${_wd[d.weekday - 1]}, ${_mo[d.month - 1]} ${d.day}';

/// "14:00" → "02:00 PM"
String wTime12(String hhmm) {
  final p = hhmm.split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = p.length > 1 ? p[1].padLeft(2, '0') : '00';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '${h12.toString().padLeft(2, '0')}:$m ${h < 12 ? 'AM' : 'PM'}';
}

void wSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: WColors.dark,
      ),
    );
}

// ───────────────────────── Widgets ─────────────────────────

class WPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double size;
  const WPill(
    this.text, {
    super.key,
    this.bg = WColors.primarySoft,
    this.fg = WColors.primary,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: size, vertical: size * 0.4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: size, color: fg, fontWeight: FontWeight.w600),
    ),
  );
}

/// Status of a booking from the worker's point of view.
class WorkStatusPill extends StatelessWidget {
  final Booking booking;
  const WorkStatusPill(this.booking, {super.key});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    if (b.isDone) {
      return const WPill('Done', bg: Color(0xFFE9ECEB), fg: WColors.muted);
    }
    if (!b.startsAt.isAfter(DateTime.now())) {
      return const WPill(
        'To complete',
        bg: WColors.amberSoft,
        fg: WColors.amber,
      );
    }
    return const WPill('Confirmed');
  }
}

class WPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  const WPrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: WColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: WColors.primary.withValues(alpha: 0.4),
      disabledForegroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(trailingIcon, size: 20),
        ],
      ],
    ),
  );
}

class WChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const WChip(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? WColors.primarySoft : WColors.card,
    shape: StadiumBorder(
      side: BorderSide(color: selected ? WColors.primarySoft : WColors.border),
    ),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: selected ? WColors.primary : WColors.text,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

/// The worker's photo, or their initials.
class WorkerAvatar extends StatelessWidget {
  final double size;
  const WorkerAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final p = WorkerProfile.instance;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final fallback = Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: WColors.accentSoft,
          child: Text(
            initialsOf(p.name),
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              color: WColors.accent,
            ),
          ),
        );
        final Widget img = p.photoBytes != null
            ? Image.memory(
                p.photoBytes!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Image.asset(
                'lib/assets/images/worker.jpg',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              );
        return ClipOval(
          child: SizedBox(width: size, height: size, child: img),
        );
      },
    );
  }
}

/// Screen header with a round back button and a title.
class WBackHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const WBackHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Material(
        color: WColors.card,
        shape: const CircleBorder(side: BorderSide(color: WColors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.maybePop(context),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.arrow_back, size: 20, color: WColors.text),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.heading,
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: WColors.text,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

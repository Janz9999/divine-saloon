// lib/manager/manager_ui.dart
//
// Colours, helpers and small widgets shared by the manager screens.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../customer/booking_store.dart';
import 'manager_store.dart';

class MColors {
  MColors._();
  static const bg = Color(0xFFF4F5F7);
  static const card = Color(0xFFFFFFFF);
  static const navy = Color(0xFF1E2A38);
  static const accent = Color(0xFFC9573D); // terracotta — main actions
  static const accentSoft = Color(0xFFFBE9E3);
  static const teal = Color(0xFF3E8E7E);
  static const tealSoft = Color(0xFFE3F1EE);
  static const amber = Color(0xFF9A7428);
  static const amberSoft = Color(0xFFF6EDD6);
  static const text = Color(0xFF1A2230);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFFA3A9B3);
  static const border = Color(0xFFE6E8EC);
  static const greyBtn = Color(0xFFEDEFF2);
}

// ───────────────────────── Formatting ─────────────────────────

const List<String> mMonthsShort = [
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
const List<String> mMonthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const List<String> mWeekdaysLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String mMoney(num v) => v == v.roundToDouble()
    ? '£${v.toStringAsFixed(0)}'
    : '£${v.toStringAsFixed(2)}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Tomorrow", "Yesterday" or "Wed 27 May".
String relativeDay(DateTime d) {
  final diff = dayOnly(d).difference(dayOnly(DateTime.now())).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return '${mWeekdaysLong[d.weekday - 1].substring(0, 3)} ${d.day} ${mMonthsShort[d.month - 1]}';
}

/// "3m ago", "2h", "2d".
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

void mSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: MColors.navy,
      ),
    );
}

// ───────────────────────── Text styles ─────────────────────────

const TextStyle mTitle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: MColors.text,
  height: 1.1,
);
const TextStyle mSubtitle = TextStyle(fontSize: 15, color: MColors.muted);
const TextStyle mSection = TextStyle(
  fontSize: 21,
  fontWeight: FontWeight.w600,
  color: MColors.text,
);
const TextStyle mCaps = TextStyle(
  fontSize: 12,
  color: MColors.muted,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.4,
);

// ───────────────────────── Widgets ─────────────────────────

class MCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  const MCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color = MColors.card,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class MPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double size;
  const MPill(
    this.text, {
    super.key,
    this.bg = MColors.accentSoft,
    this.fg = MColors.accent,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: size * 0.95,
      vertical: size * 0.45,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: size, color: fg, fontWeight: FontWeight.w500),
    ),
  );
}

/// White rounded pill used as a small dropdown / toggle ("Monthly", "Weekly").
class MChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool selected;
  const MChipButton(
    this.label, {
    super.key,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? MColors.navy : MColors.card,
    borderRadius: BorderRadius.circular(30),
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: selected ? Colors.white : MColors.text,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class MPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool compact;
  const MPrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: MColors.accent,
      foregroundColor: Colors.white,
      minimumSize: compact ? const Size(0, 42) : const Size.fromHeight(56),
      padding: EdgeInsets.symmetric(horizontal: compact ? 22 : 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 30 : 16),
      ),
      textStyle: TextStyle(
        fontSize: compact ? 15 : 17,
        fontWeight: FontWeight.w600,
      ),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

class MSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const MSecondaryButton(this.label, {super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: MColors.greyBtn,
      foregroundColor: MColors.text,
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    child: Text(label),
  );
}

class MLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double size;
  const MLink(this.text, {super.key, required this.onTap, this.size = 15});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          color: MColors.accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

/// Round initials avatar (customers have no photos).
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color bg;
  final Color fg;
  const InitialsAvatar(
    this.name, {
    super.key,
    this.size = 48,
    this.bg = MColors.tealSoft,
    this.fg = MColors.teal,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Text(
      initialsOf(name),
      style: TextStyle(
        fontSize: size * 0.38,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    ),
  );
}

/// The manager's photo, or their initials.
class ManagerAvatar extends StatelessWidget {
  final double size;
  const ManagerAvatar({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final p = ManagerProfile.instance;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final fallback = Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: MColors.accentSoft,
          child: Text(
            initialsOf(p.fullName),
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w600,
              color: MColors.accent,
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
                'lib/assets/images/manager.jpg',
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

/// Status pill for a booking, as the manager sees it.
class BookingStatusPill extends StatelessWidget {
  final Booking booking;
  final double size;
  const BookingStatusPill(this.booking, {super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final (String label, Color bg, Color fg) = switch (b.status) {
      BookingStatus.pending => (
        b.isUpcoming ? 'Pending' : 'Expired',
        MColors.accentSoft,
        MColors.accent,
      ),
      BookingStatus.confirmed => (
        b.isUpcoming ? 'Confirmed' : 'Completed',
        MColors.tealSoft,
        MColors.teal,
      ),
      BookingStatus.declined => ('Declined', MColors.greyBtn, MColors.muted),
      BookingStatus.cancelled => ('Cancelled', MColors.greyBtn, MColors.muted),
    };
    return MPill(label, bg: bg, fg: fg, size: size);
  }
}

/// Grey label above a form field + white field.
class MField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final TextInputType? keyboard;

  const MField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.capitalization = TextCapitalization.sentences,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: MColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines > 1 ? maxLines : 1,
            validator: validator,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboard,
            textCapitalization: capitalization,
            style: const TextStyle(fontSize: 17, color: MColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: MColors.faint, fontSize: 17),
              filled: true,
              fillColor: MColors.card,
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: border(MColors.border),
              enabledBorder: border(MColors.border),
              focusedBorder: border(MColors.accent, 1.4),
              errorBorder: border(Colors.red.shade300),
              focusedErrorBorder: border(Colors.red, 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple screen header with a back arrow (for pushed screens).
class MBackHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const MBackHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.maybePop(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new, size: 16, color: MColors.text),
              SizedBox(width: 6),
              Text('Back', style: TextStyle(fontSize: 15, color: MColors.text)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: Text(title, style: mTitle)),
          ?trailing,
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(subtitle!, style: mSubtitle),
      ],
    ],
  );
}

// ───────────────────────── Customer phone ─────────────────────────

Future<void> _launchPhone(
  BuildContext context,
  String scheme,
  String phone,
) async {
  final number = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final ok = await launchUrl(Uri(scheme: scheme, path: number));
  if (!ok && context.mounted) {
    mSnack(
      context,
      scheme == 'tel' ? 'Could not start a call' : 'Could not open messages',
    );
  }
}

Future<void> callCustomer(BuildContext context, String phone) =>
    _launchPhone(context, 'tel', phone);
Future<void> textCustomer(BuildContext context, String phone) =>
    _launchPhone(context, 'sms', phone);

/// The customer's phone number with Call / Text / Copy.
class CustomerPhoneCard extends StatelessWidget {
  final String phone;
  const CustomerPhoneCard({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    final has = phone.trim().isNotEmpty;
    Widget action(IconData icon, String tip, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: MColors.accentSoft),
      icon: Icon(icon, size: 20, color: MColors.accent),
    );
    return MCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, color: MColors.muted, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone number',
                  style: TextStyle(fontSize: 13, color: MColors.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  has ? phone : 'Not provided',
                  style: TextStyle(
                    fontSize: 17,
                    color: has ? MColors.text : MColors.faint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (has) ...[
            action(
              Icons.call_outlined,
              'Call',
              () => callCustomer(context, phone),
            ),
            const SizedBox(width: 6),
            action(
              Icons.sms_outlined,
              'Text',
              () => textCustomer(context, phone),
            ),
            const SizedBox(width: 6),
            action(Icons.copy_rounded, 'Copy', () {
              Clipboard.setData(ClipboardData(text: phone));
              mSnack(context, 'Phone number copied');
            }),
          ],
        ],
      ),
    );
  }
}

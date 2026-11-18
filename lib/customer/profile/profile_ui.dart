// lib/customer/profile/profile_ui.dart
//
// Colours, text styles and small widgets shared by all profile screens.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../customer_nav.dart';

import 'package:google_fonts/google_fonts.dart';

import '../activity_screen.dart';
import '../customer_home_screen.dart';
import '../salon_detail_screen.dart';
import 'profile_screen.dart';
import 'profile_store.dart';

class PColors {
  static const bg = AppColors.bg;
  static const brown = AppColors.accent; // links & small accents
  static const green = AppColors.accent; // buttons & feature cards
  static const beige = AppColors.surface;
  static const chip = Color(0xFFEFEFEF);
  static const text = AppColors.text;
  static const muted = AppColors.muted;
  static const border = AppColors.border;
}

TextStyle serif(double size, {Color color = PColors.text}) =>
    GoogleFonts.playfairDisplay(
      fontSize: size,
      color: color,
      fontWeight: FontWeight.w400,
      height: 1.2,
    );

const List<String> monthsShort = [
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
const List<String> monthsLong = [
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
const List<String> weekdaysShort = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> weekdaysLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String money(num v) => v == v.roundToDouble()
    ? '£${v.toStringAsFixed(0)}'
    : '£${v.toStringAsFixed(2)}';
String shortDate(DateTime d) =>
    '${weekdaysShort[d.weekday - 1]}, ${d.day} ${monthsShort[d.month - 1]}';
String fullDate(DateTime d) => '${d.day} ${monthsShort[d.month - 1]} ${d.year}';

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
}

/// Opens "Book a visit" (the treatments home screen).
void openBooking(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
    isCustomerRoot,
  );
}

/// Opens the profile from any bottom bar.
void openProfile(BuildContext context) {
  openCustomerTab(context, const ProfileScreen());
}

/// Standard layout for a profile sub-page: "← My profile", serif title,
/// subtitle, content and an optional fixed button at the bottom.
class ProfilePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final VoidCallback? onButton;
  final String? caption;
  final String backLabel;
  final Widget? bottomNav;

  const ProfilePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.buttonLabel,
    this.buttonIcon,
    this.onButton,
    this.caption,
    this.backLabel = 'My profile',
    this.bottomNav,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PColors.bg,
      bottomNavigationBar: bottomNav,
      body: SafeArea(
        bottom: bottomNav == null,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                children: [
                  BackRow(label: backLabel),
                  const SizedBox(height: 24),
                  Text(title, style: serif(32)),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: PColors.muted),
                  ),
                  const SizedBox(height: 26),
                  ...children,
                ],
              ),
            ),
            if (buttonLabel != null)
              Container(
                decoration: const BoxDecoration(
                  color: PColors.bg,
                  border: Border(top: BorderSide(color: PColors.border)),
                ),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: buttonLabel!,
                      icon: buttonIcon,
                      onPressed: onButton,
                    ),
                    if (caption != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        caption!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: PColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BackRow extends StatelessWidget {
  final String label;
  const BackRow({super.key, this.label = 'My profile'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.maybePop(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: PColors.text, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: PColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool small;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: PColors.brown,
      foregroundColor: Colors.white,
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          : null,
      minimumSize: small ? Size.zero : const Size.fromHeight(54),
      tapTargetSize: small ? MaterialTapTargetSize.shrinkWrap : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(small ? 10 : 12),
      ),
      textStyle: TextStyle(
        fontSize: small ? 13 : 16,
        fontWeight: FontWeight.w600,
      ),
    );
    return icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
  }
}

class LinkText extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double size;
  const LinkText(this.text, {super.key, this.onTap, this.size = 14});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          color: PColors.brown,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// White rounded card with a soft border.
class PCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const PCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PColors.border),
    ),
    child: child,
  );
}

/// Beige box with a serif heading — used for notes and tips.
class SoftBox extends StatelessWidget {
  final String title;
  final String? text;
  final Widget? action;
  final bool serifTitle;
  const SoftBox({
    super.key,
    required this.title,
    this.text,
    this.action,
    this.serifTitle = true,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: PColors.beige,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: serifTitle
              ? serif(19)
              : const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: PColors.text,
                ),
        ),
        if (text != null) ...[
          const SizedBox(height: 8),
          Text(
            text!,
            style: const TextStyle(
              fontSize: 13.5,
              color: PColors.muted,
              height: 1.45,
            ),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 6), action!],
      ],
    ),
  );
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(
    this.text, {
    super.key,
    this.bg = PColors.chip,
    this.fg = PColors.brown,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
    ),
  );
}

/// Beige "NOV / 18" date badge.
class DateBadge extends StatelessWidget {
  final DateTime date;
  const DateBadge(this.date, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: PColors.beige,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Text(
          monthsShort[date.month - 1].toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: PColors.brown,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 26,
            color: PColors.text,
            height: 1.15,
          ),
        ),
      ],
    ),
  );
}

/// Label + text field in the profile style.
class PField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final int maxLines;
  final TextInputType? keyboard;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;

  const PField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.maxLines = 1,
    this.keyboard,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.validator,
    this.capitalization = TextCapitalization.sentences,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: PColors.muted),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines > 1 ? maxLines : null,
            keyboardType: maxLines > 1 ? TextInputType.multiline : keyboard,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            textCapitalization: capitalization,
            style: const TextStyle(fontSize: 15.5, color: PColors.text),
            decoration: pInputDecoration(hint: hint, suffix: suffix),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: const TextStyle(fontSize: 12, color: PColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

InputDecoration pInputDecoration({String? hint, Widget? suffix}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    suffixIcon: suffix,
    enabledBorder: border(PColors.border),
    focusedBorder: border(PColors.brown, 1.4),
    errorBorder: border(AppColors.danger.withValues(alpha: 0.6)),
    focusedErrorBorder: border(AppColors.danger, 1.4),
  );
}

/// Round profile photo: picked photo → asset photo → initials.
class ProfileAvatar extends StatelessWidget {
  final double size;
  const ProfileAvatar({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final p = CustomerProfile.instance;
    final initials = Container(
      color: PColors.beige,
      alignment: Alignment.center,
      child: Text(p.initials, style: serif(size * 0.36, color: PColors.brown)),
    );
    final Widget image = p.photoBytes != null
        ? Image.memory(p.photoBytes!, fit: BoxFit.cover)
        : Image.asset(
            CustomerProfile.defaultPhotoAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => initials,
          );
    return ClipOval(
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

enum NavTab { home, bookings, explore, profile }

/// Bottom bar for the profile area: Home · Bookings · Explore · Profile.
class ProfileBottomNav extends StatelessWidget {
  final NavTab active;
  const ProfileBottomNav({super.key, this.active = NavTab.profile});

  void _go(BuildContext context, NavTab tab) {
    if (tab == active) return;
    final Widget screen = switch (tab) {
      NavTab.home => const CustomerHomeScreen(),
      NavTab.bookings => const ActivityScreen(),
      NavTab.explore => const SalonDetailScreen(),
      NavTab.profile => const ProfileScreen(),
    };
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      isCustomerRoot,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget item(NavTab tab, IconData icon, String label) {
      final on = tab == active;
      return Expanded(
        child: InkWell(
          onTap: () => _go(context, tab),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: on ? PColors.beige : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: on ? PColors.brown : PColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: on ? PColors.brown : PColors.muted,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              item(NavTab.home, Icons.home_outlined, 'Home'),
              item(NavTab.bookings, Icons.event_available_outlined, 'Bookings'),
              item(NavTab.explore, Icons.explore_outlined, 'Explore'),
              item(NavTab.profile, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

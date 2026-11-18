// lib/customer/profile/profile_screen.dart
//
// "My profile" — the customer's home for their details, rewards,
// next visit, preferences, payment methods and settings.

import 'package:flutter/material.dart';

import '../booking_store.dart';
import 'appointment_details_screen.dart';
import 'beauty_preferences_screen.dart';
import 'edit_profile_screen.dart';
import 'my_bookings_screen.dart';
import 'personal_details_screen.dart';
import 'profile_store.dart';
import 'profile_ui.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import '../../theme/app_text.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final profile = CustomerProfile.instance;
    return Scaffold(
      backgroundColor: PColors.bg,
      bottomNavigationBar: const ProfileBottomNav(active: NavTab.profile),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            profile,
            BookingStore.instance.bookings,
          ]),
          builder: (context, _) {
            final upcoming =
                BookingStore.instance.bookings.value
                    .where((b) => b.isUpcoming)
                    .toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              children: [
                // Title + settings
                Row(
                  children: [
                    Expanded(child: Text('My profile', style: serif(28))),
                    Material(
                      color: PColors.beige,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: PColors.text,
                        ),
                        onPressed: () => _push(context, const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Photo, name, email
                Row(
                  children: [
                    const ProfileAvatar(size: 96),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: serif(26)),
                          const SizedBox(height: 4),
                          Text(
                            profile.email,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: PColors.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Pill('MEMBER SINCE ${profile.memberSince}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _push(context, const EditProfileScreen()),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PColors.text,
                    backgroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: PColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                _RewardsCard(
                  onView: () => _push(context, const RewardsScreen()),
                ),
                const SizedBox(height: 28),

                // Next visit
                Row(
                  children: [
                    Expanded(child: Text('Your next visit', style: serif(22))),
                    LinkText(
                      'See all',
                      size: 13,
                      onTap: () => _push(context, const MyBookingsScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (upcoming.isEmpty)
                  SoftBox(
                    title: 'No upcoming visits',
                    text: 'Your next appointment will appear here once it’s booked.',
                    action: LinkText(
                      'Book a visit',
                      onTap: () => openBooking(context),
                    ),
                  )
                else
                  NextVisitCard(
                    booking: upcoming.first,
                    onManage: () => _push(
                      context,
                      AppointmentDetailsScreen(
                        reference: upcoming.first.reference,
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                // Made for you
                Text('Made for you', style: serif(22)),
                const SizedBox(height: 12),
                PCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      _MenuRow(
                        icon: Icons.person_outline,
                        title: 'Personal details',
                        subtitle: 'Contact info & birthday',
                        onTap: () =>
                            _push(context, const PersonalDetailsScreen()),
                      ),
                      const Divider(height: 1, color: PColors.border),
                      _MenuRow(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Beauty preferences',
                        subtitle: 'Your hair, your way',
                        onTap: () =>
                            _push(context, const BeautyPreferencesScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  final VoidCallback onView;
  const _RewardsCard({required this.onView});

  @override
  Widget build(BuildContext context) {
    final points = Rewards.totalPoints();
    final next = Rewards.nextTier(points);
    final left = (next.points - points).clamp(0, next.points);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: PColors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DIVINE CIRCLE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A little care, on us.',
                      style: serif(22, color: Colors.white),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 12.5,
                  ),
                ),
                child: const Text('View rewards'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$points',
                style: const TextStyle(fontSize: 30, color: Colors.white),
              ),
              Text(
                '  / ${next.points} points',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RewardsProgressBar(value: points / next.points),
          const SizedBox(height: 10),
          Text(
            left == 0
                ? 'Your £${next.discount} treat is ready!'
                : '$left points to your next £${next.discount} treat',
            style: const TextStyle(fontSize: 11.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class RewardsProgressBar extends StatelessWidget {
  final double value;
  const RewardsProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: 5,
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      valueColor: const AlwaysStoppedAnimation(Colors.white),
    ),
  );
}

/// Upcoming visit card with date badge and "Manage visit".
class NextVisitCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onManage;
  const NextVisitCard({
    super.key,
    required this.booking,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateBadge(booking.date),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: PColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${shortDate(booking.date)} · ${booking.time}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: PColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ref ${booking.reference}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: PColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: PColors.border),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Divine Aesthetics · Crewe',
                  style: TextStyle(fontSize: 12.5, color: PColors.muted),
                ),
              ),
              PrimaryButton(
                label: 'Manage visit',
                small: true,
                onPressed: onManage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: PColors.brown, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, color: PColors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: PColors.muted),
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

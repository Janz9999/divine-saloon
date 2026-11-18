// lib/customer/profile/appointment_details_screen.dart
//
// One booking: date, service, salon, plus reschedule / cancel.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../activity_screen.dart' show openSalonDirections;
import '../booking_store.dart';
import 'profile_ui.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String reference;
  const AppointmentDetailsScreen({super.key, required this.reference});

  static const List<String> _times = [
    '9:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  Future<void> _reschedule(BuildContext context, Booking b) async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: b.date.isBefore(today) ? today : b.date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Choose a new date',
    );
    if (date == null || !context.mounted) return;

    final time = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: PColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final now = DateTime.now();
        bool isPast(String t) {
          final h = int.parse(t.split(':').first);
          return DateTime(date.year, date.month, date.day, h).isBefore(now);
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose a time', style: serif(22)),
                const SizedBox(height: 4),
                Text(
                  shortDate(date),
                  style: const TextStyle(color: PColors.muted),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _times)
                      OutlinedButton(
                        onPressed: isPast(t)
                            ? null
                            : () => Navigator.pop(ctx, t),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PColors.text,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: PColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(t),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (time == null || !context.mounted) return;
    BookingStore.instance.reschedule(b.reference, date, time);
    showSnack(context, 'Moved to ${shortDate(date)} at $time');
  }

  Future<void> _cancel(BuildContext context, Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PColors.bg,
        title: Text('Cancel appointment?', style: serif(22)),
        content: Text('${b.serviceName}\n${shortDate(b.date)} · ${b.time}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel appointment',
              style: TextStyle(color: PColors.brown),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    BookingStore.instance.cancel(b.reference);
    Navigator.pop(context);
    showSnack(context, 'Appointment cancelled');
  }

  void _contactSalon(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Booking.salonName, style: serif(22)),
              const SizedBox(height: 8),
              const Text(
                Booking.salonAddress,
                style: TextStyle(color: PColors.muted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please quote your booking reference when you get in touch.',
                style: TextStyle(color: PColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Booking>>(
      valueListenable: BookingStore.instance.bookings,
      builder: (context, _, _) {
        final b = BookingStore.instance.find(reference);
        if (b == null) {
          return const ProfilePage(
            title: 'Appointment details',
            subtitle: 'This appointment is no longer booked.',
            children: [],
          );
        }
        final upcoming = b.isUpcoming;
        final d = b.date;
        final balance = b.balanceDue;
        return ProfilePage(
          title: 'Appointment details',
          subtitle: '',
          buttonLabel: upcoming ? 'Reschedule appointment' : 'Book again',
          onButton: upcoming
              ? () => _reschedule(context, b)
              : () => openBooking(context),
          caption: upcoming
              ? 'The rest is paid at the salon after your service.'
              : null,
          children: [
            Row(
              children: [
                Pill(
                  b.statusLabel,
                  bg: b.isActive ? AppColors.accentSoft : PColors.chip,
                  fg: b.isActive ? PColors.green : PColors.muted,
                ),
                const Spacer(),
                Text(
                  'Booking #${b.reference}',
                  style: const TextStyle(fontSize: 13, color: PColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: PColors.beige,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weekdaysLong[d.weekday - 1]}, ${d.day} ${monthsLong[d.month - 1]}',
                    style: serif(24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    b.time,
                    style: const TextStyle(fontSize: 15, color: PColors.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text('Your service', style: serif(22)),
            const SizedBox(height: 12),
            PCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          b.serviceName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PColors.text,
                          ),
                        ),
                      ),
                      Text(
                        b.servicePrice == null ? 'POA' : money(b.servicePrice!),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: PColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deposit paid ${money(b.depositPaid)} · ${b.paymentMethod}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: PColors.muted,
                    ),
                  ),
                  if (balance != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${money(balance)} to pay at the salon',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: PColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text('Divine Aesthetics & Beauty', style: serif(22)),
            const SizedBox(height: 12),
            PCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crewe',
                    style: TextStyle(fontSize: 16, color: PColors.text),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '32 West St\nCrewe CW1 3HA',
                    style: TextStyle(
                      fontSize: 14,
                      color: PColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinkText(
                    'Get directions',
                    onTap: () => openSalonDirections(context),
                  ),
                ],
              ),
            ),
            if (upcoming) ...[
              const SizedBox(height: 24),
              const SoftBox(
                title: 'Plans change. We understand.',
                serifTitle: false,
                text: 'Reschedule or cancel at least 24 hours before your visit to avoid a late cancellation fee.',
              ),
              const SizedBox(height: 22),
              LinkText('Cancel appointment', onTap: () => _cancel(context, b)),
            ],
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _contactSalon(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Need help? Contact the salon',
                  style: TextStyle(fontSize: 13, color: PColors.muted),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

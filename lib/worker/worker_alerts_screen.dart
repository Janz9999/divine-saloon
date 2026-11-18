// lib/worker/worker_alerts_screen.dart
//
// Worker alerts: new confirmed bookings, changes to them, and team events.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import '../manager/manager_ui.dart' show timeAgo;
import 'worker_mark_done_screen.dart';
import 'worker_ui.dart';

class WorkerAlertsScreen extends StatelessWidget {
  const WorkerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = WorkerAlerts.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        BookingStore.instance.activity,
        alerts.seen,
      ]),
      builder: (context, _) {
        final items = alerts.items();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Alerts',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: WColors.text,
                    ),
                  ),
                ),
                if (alerts.unread() > 0)
                  TextButton(
                    onPressed: alerts.markAllSeen,
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: WColors.accent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'New bookings and team updates.',
              style: TextStyle(fontSize: 14.5, color: WColors.muted),
            ),
            const SizedBox(height: 20),
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: WColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Nothing yet. When the manager confirms a booking, you’ll see it here.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: WColors.muted,
                    height: 1.4,
                  ),
                ),
              )
            else
              for (final a in items)
                _AlertTile(
                  activity: a,
                  unread: !alerts.seen.value.contains(a.id),
                ),
          ],
        );
      },
    );
  }
}

class _AlertTile extends StatelessWidget {
  final SalonActivity activity;
  final bool unread;
  const _AlertTile({required this.activity, required this.unread});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final (IconData icon, Color fg, Color bg, String title) = switch (a.kind) {
      ActivityKind.accepted => (
        Icons.event_available,
        WColors.primary,
        WColors.primarySoft,
        'New booking',
      ),
      ActivityKind.cancelled => (
        Icons.event_busy,
        WColors.accent,
        WColors.accentSoft,
        'Booking cancelled',
      ),
      ActivityKind.rescheduled => (
        Icons.update,
        WColors.amber,
        WColors.amberSoft,
        'Booking moved',
      ),
      ActivityKind.inventory => (
        Icons.inventory_2_outlined,
        WColors.amber,
        WColors.amberSoft,
        a.title,
      ),
      _ => (
        Icons.groups_outlined,
        WColors.primary,
        WColors.primarySoft,
        a.title,
      ),
    };
    final booking = a.bookingRef == null
        ? null
        : BookingStore.instance.find(a.bookingRef!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: WColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            WorkerAlerts.instance.markSeen(a.id);
            if (booking != null && booking.isConfirmed) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WorkerMarkDoneScreen(reference: booking.reference),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: WColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        a.subtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: WColors.muted,
                          height: 1.35,
                        ),
                      ),
                      if (booking != null &&
                          booking.customerPhone.isNotEmpty &&
                          a.kind == ActivityKind.accepted) ...[
                        const SizedBox(height: 4),
                        Text(
                          booking.customerPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: WColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo(a.at),
                      style: const TextStyle(
                        fontSize: 12,
                        color: WColors.muted,
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: WColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

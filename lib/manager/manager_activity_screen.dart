// lib/manager/manager_activity_screen.dart
//
// Alerts tab: new booking requests (Accept / Decline), payments,
// cancellations, moved bookings and team / inventory events.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import 'manager_booking_screens.dart';
import 'manager_ui.dart';

class ManagerActivityScreen extends StatefulWidget {
  const ManagerActivityScreen({super.key});

  @override
  State<ManagerActivityScreen> createState() => _ManagerActivityScreenState();
}

class _ManagerActivityScreenState extends State<ManagerActivityScreen> {
  int _filter = 0; // 0 all, 1 bookings, 2 team

  @override
  Widget build(BuildContext context) {
    final store = BookingStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([store.activity, store.bookings]),
      builder: (context, _) {
        final items = store.activity.value.where((a) {
          if (_filter == 1) return a.isBooking;
          if (_filter == 2) return !a.isBooking;
          return true;
        }).toList();

        final now = DateTime.now();
        final today = items.where((a) => sameDay(a.at, now)).toList();
        final week = items
            .where(
              (a) => !sameDay(a.at, now) && now.difference(a.at).inDays < 7,
            )
            .toList();
        final earlier = items
            .where(
              (a) => !sameDay(a.at, now) && now.difference(a.at).inDays >= 7,
            )
            .toList();
        final actionNeeded = store.bookings.value
            .where((b) => b.isPending && b.isUpcoming)
            .length;

        Widget group(
          String title,
          List<SalonActivity> list, {
          Widget? trailing,
        }) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Text(title, style: mCaps)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityItem(activity: a),
              ),
          ],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          children: [
            Row(
              children: [
                const Expanded(child: Text('Activity', style: mTitle)),
                if (store.unreadCount > 0)
                  MLink('Mark all read', onTap: store.markAllRead),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Stay on top of your salon.', style: mSubtitle),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MChipButton(
                    'All activity',
                    selected: _filter == 0,
                    onTap: () => setState(() => _filter = 0),
                  ),
                  const SizedBox(width: 10),
                  MChipButton(
                    'Bookings',
                    selected: _filter == 1,
                    onTap: () => setState(() => _filter = 1),
                  ),
                  const SizedBox(width: 10),
                  MChipButton(
                    'Team',
                    selected: _filter == 2,
                    onTap: () => setState(() => _filter = 2),
                  ),
                ],
              ),
            ),
            if (items.isEmpty) ...[
              const SizedBox(height: 26),
              MCard(
                child: Text(
                  _filter == 2
                      ? 'No team updates yet. Events you add to the calendar show here.'
                      : 'Nothing yet. When a customer books, you’ll see the request here.',
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: MColors.muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (today.isNotEmpty)
              group(
                'TODAY',
                today,
                trailing: actionNeeded > 0
                    ? MPill(
                        '$actionNeeded action${actionNeeded == 1 ? '' : 's'} needed',
                        size: 14,
                      )
                    : null,
              ),
            if (week.isNotEmpty) group('THIS WEEK', week),
            if (earlier.isNotEmpty) group('EARLIER', earlier),
          ],
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final SalonActivity activity;
  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final booking = a.bookingRef == null
        ? null
        : BookingStore.instance.find(a.bookingRef!);

    // A request that still needs an answer gets the big card with buttons.
    if (a.kind == ActivityKind.request &&
        booking != null &&
        booking.isPending &&
        booking.isUpcoming) {
      return _RequestCard(activity: a, booking: booking);
    }

    final (Widget icon, Color bg) = switch (a.kind) {
      ActivityKind.request => (
        Text(
          initialsOf(booking?.customerName ?? '?'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: MColors.teal,
          ),
        ),
        MColors.tealSoft,
      ),
      ActivityKind.payment => (
        const Text(
          '£',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MColors.teal,
          ),
        ),
        MColors.tealSoft,
      ),
      ActivityKind.accepted => (
        const Icon(Icons.check, color: MColors.teal),
        MColors.tealSoft,
      ),
      ActivityKind.declined => (
        const Icon(Icons.close, color: MColors.muted, size: 20),
        MColors.greyBtn,
      ),
      ActivityKind.cancelled => (
        const Icon(Icons.close, color: MColors.accent, size: 20),
        MColors.accentSoft,
      ),
      ActivityKind.rescheduled => (
        const Icon(Icons.update, color: MColors.amber, size: 22),
        MColors.amberSoft,
      ),
      ActivityKind.team => (
        const Icon(Icons.groups_outlined, color: MColors.teal, size: 22),
        MColors.tealSoft,
      ),
      ActivityKind.inventory => (
        const Icon(Icons.inventory_2_outlined, color: MColors.amber, size: 21),
        MColors.amberSoft,
      ),
      ActivityKind.note => (
        const Icon(Icons.info_outline, color: MColors.muted, size: 21),
        MColors.greyBtn,
      ),
      ActivityKind.completed => (
        const Icon(Icons.task_alt, color: MColors.teal, size: 22),
        MColors.tealSoft,
      ),
      ActivityKind.message => (
        const Icon(Icons.chat_bubble_outline, color: MColors.teal, size: 20),
        MColors.tealSoft,
      ),
    };

    final title = switch (a.kind) {
      ActivityKind.request =>
        booking == null
            ? a.title
            : '${booking.customerName} · ${booking.statusLabel}',
      _ => a.title,
    };
    final subtitle = a.kind == ActivityKind.request && booking != null
        ? '${booking.serviceName} · ${relativeDay(booking.date)} ${booking.time}'
        : a.subtitle;

    return MCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      onTap: () {
        BookingStore.instance.markRead(a.id);
        if (a.bookingRef != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ManagerBookingDetailScreen(reference: a.bookingRef!),
            ),
          );
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: icon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w500,
                    color: MColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: a.kind == ActivityKind.message ? 2 : null,
                  overflow: a.kind == ActivityKind.message
                      ? TextOverflow.ellipsis
                      : null,
                  style: const TextStyle(
                    fontSize: 14,
                    color: MColors.muted,
                    height: 1.35,
                  ),
                ),
                // Confirmed customer → quick "Message" action.
                if (a.kind == ActivityKind.accepted &&
                    booking != null &&
                    booking.isConfirmed &&
                    booking.isUpcoming)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: MLink(
                      'Message customer',
                      size: 14,
                      onTap: () => showMessageSheet(context, booking),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo(a.at),
                style: const TextStyle(fontSize: 12.5, color: MColors.muted),
              ),
              if (!a.read) ...[
                const SizedBox(height: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final SalonActivity activity;
  final Booking booking;
  const _RequestCard({required this.activity, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return MCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerBookingDetailScreen(reference: b.reference),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 22),
              color: MColors.accent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const MPill('Booking request', size: 15),
                        const Spacer(),
                        Text(
                          timeAgo(activity.at),
                          style: const TextStyle(
                            fontSize: 13,
                            color: MColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.customerName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: MColors.text,
                            ),
                          ),
                        ),
                        Text(
                          b.servicePrice == null
                              ? 'POA'
                              : mMoney(b.servicePrice!),
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: MColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${b.serviceName} · ${relativeDay(b.date)} ${b.time}',
                      style: const TextStyle(
                        fontSize: 15.5,
                        color: MColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mMoney(b.depositPaid)} deposit paid',
                      style: const TextStyle(fontSize: 13, color: MColors.teal),
                    ),
                    if (b.customerPhone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => callCustomer(context, b.customerPhone),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: MColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              b.customerPhone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: MColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MSecondaryButton(
                            'Decline',
                            onPressed: () => declineBooking(context, b),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: MPrimaryButton(
                            'Accept booking',
                            compact: true,
                            onPressed: () => acceptBooking(context, b),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/manager/manager_booking_screens.dart
//
//  • ManagerBookingsScreen      — all bookings: Requests / Upcoming / Past.
//  • ManagerBookingDetailScreen — one booking, with Accept / Decline / Cancel.
//  • acceptBooking / declineBooking — shared actions (also used by Alerts).
//  • showMessageSheet — write a message the customer sees in their app.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import 'manager_ui.dart';

/// Accepts the booking, then offers to send the customer a confirmation message.
Future<void> acceptBooking(BuildContext context, Booking b) async {
  BookingStore.instance.accept(b.reference);
  final sent = await showMessageSheet(
    context,
    b,
    initial: _confirmText(b),
    title: 'Booking accepted',
  );
  if (!sent && context.mounted) {
    mSnack(
      context,
      'Booking accepted — ${b.customerName} can see it’s confirmed',
    );
  }
}

String _firstName(Booking b) =>
    b.customerName.trim().split(RegExp(r'\s+')).first;

String _confirmText(Booking b) =>
    'Hi ${_firstName(b)}, your ${b.serviceName} on ${relativeDay(b.date)} at ${b.time} is confirmed. '
    'We look forward to seeing you!';

/// Bottom sheet to write a message to the customer.
/// Returns true when a message was sent.
Future<bool> showMessageSheet(
  BuildContext context,
  Booking b, {
  String? initial,
  String? title,
}) async {
  final text = TextEditingController(text: initial ?? '');
  final templates = <String, String>{
    'Confirmed': _confirmText(b),
    'Reminder':
        'Hi ${_firstName(b)}, just a reminder of your ${b.serviceName} on ${relativeDay(b.date)} at ${b.time}. '
        'Please arrive 5 minutes early.',
    'Running late':
        'Hi ${_firstName(b)}, we’re running about 15 minutes behind today. Sorry for the wait!',
  };

  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          22 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: MColors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: MColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text('Message ${b.customerName}', style: mSection),
              const SizedBox(height: 6),
              Text(
                '${b.serviceName} · ${relativeDay(b.date)} ${b.time}',
                style: mSubtitle,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in templates.entries)
                    ActionChip(
                      label: Text(e.key),
                      backgroundColor: MColors.card,
                      side: const BorderSide(color: MColors.border),
                      shape: const StadiumBorder(),
                      labelStyle: const TextStyle(color: MColors.text),
                      onPressed: () => setSheet(() => text.text = e.value),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              MField(
                label: 'Message',
                controller: text,
                hint: 'Write a message…',
                maxLines: 4,
              ),
              const Text(
                'The customer sees this in their app, on this booking.',
                style: TextStyle(fontSize: 13, color: MColors.muted),
              ),
              const SizedBox(height: 18),
              MPrimaryButton(
                'Send message',
                icon: Icons.send_rounded,
                onPressed: () {
                  if (text.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    title != null ? 'Not now' : 'Cancel',
                    style: const TextStyle(color: MColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (sent == true) {
    BookingStore.instance.sendMessage(b.reference, text.text);
    if (context.mounted) mSnack(context, 'Message sent to ${b.customerName}');
    return true;
  }
  return false;
}

Future<void> declineBooking(BuildContext context, Booking b) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MColors.card,
      title: const Text('Decline this booking?'),
      content: Text(
        '${b.customerName} · ${b.serviceName}\n${relativeDay(b.date)} at ${b.time}\n\n'
        'The customer will see it was declined. Remember to refund the ${mMoney(b.depositPaid)} deposit.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep', style: TextStyle(color: MColors.text)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Decline',
            style: TextStyle(
              color: MColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    BookingStore.instance.decline(b.reference);
    mSnack(context, 'Booking declined');
  }
}

// ───────────────────────── All bookings ─────────────────────────

class ManagerBookingsScreen extends StatefulWidget {
  const ManagerBookingsScreen({super.key});

  @override
  State<ManagerBookingsScreen> createState() => _ManagerBookingsScreenState();
}

class _ManagerBookingsScreenState extends State<ManagerBookingsScreen> {
  int _tab = 0; // 0 requests, 1 upcoming, 2 past

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MColors.bg,
      body: SafeArea(
        child: ValueListenableBuilder<List<Booking>>(
          valueListenable: BookingStore.instance.bookings,
          builder: (context, all, _) {
            final requests =
                all.where((b) => b.isPending && b.isUpcoming).toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final upcoming =
                all.where((b) => b.isConfirmed && b.isUpcoming).toList()
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final past = all.where((b) => !b.isUpcoming).toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
            final shown = [requests, upcoming, past][_tab];

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              children: [
                const MBackHeader(
                  title: 'Bookings',
                  subtitle: 'Every booking made by your customers.',
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      MChipButton(
                        'Requests (${requests.length})',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 10),
                      MChipButton(
                        'Upcoming (${upcoming.length})',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      const SizedBox(width: 10),
                      MChipButton(
                        'Past',
                        selected: _tab == 2,
                        onTap: () => setState(() => _tab = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (shown.isEmpty)
                  MCard(
                    child: Text(
                      [
                        'No requests waiting.',
                        'No confirmed bookings coming up.',
                        'No past bookings yet.',
                      ][_tab],
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: MColors.muted,
                      ),
                    ),
                  )
                else
                  for (final b in shown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BookingListTile(booking: b),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BookingListTile extends StatelessWidget {
  final Booking booking;
  const BookingListTile({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return MCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerBookingDetailScreen(reference: b.reference),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(b.customerName, size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.customerName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: MColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${b.serviceName}\n${relativeDay(b.date)} · ${b.time}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: MColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusPill(b, size: 13),
            ],
          ),
          if (b.isPending && b.isUpcoming) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MSecondaryButton(
                    'Decline',
                    onPressed: () => declineBooking(context, b),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MPrimaryButton(
                    'Accept',
                    compact: true,
                    onPressed: () => acceptBooking(context, b),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Booking detail ─────────────────────────

class ManagerBookingDetailScreen extends StatelessWidget {
  final String reference;
  const ManagerBookingDetailScreen({super.key, required this.reference});

  Future<void> _cancel(BuildContext context, Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MColors.card,
        title: const Text('Cancel this booking?'),
        content: Text(
          '${b.customerName} will see that the salon cancelled it. '
          'Remember to refund the ${mMoney(b.depositPaid)} deposit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep', style: TextStyle(color: MColors.text)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel booking',
              style: TextStyle(
                color: MColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      BookingStore.instance.cancel(b.reference, byManager: true);
      mSnack(context, 'Booking cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MColors.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            BookingStore.instance.bookings,
            BookingStore.instance.messages,
          ]),
          builder: (context, _) {
            final b = BookingStore.instance.find(reference);
            if (b == null) {
              return const Padding(
                padding: EdgeInsets.all(22),
                child: MBackHeader(
                  title: 'Booking',
                  subtitle: 'This booking no longer exists.',
                ),
              );
            }
            final d = b.date;
            final balance = b.balanceDue;

            Widget row(String label, String value, {bool strong = false}) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: MColors.muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15,
                            color: MColors.text,
                            fontWeight: strong
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
              children: [
                MBackHeader(title: 'Booking', trailing: BookingStatusPill(b)),
                const SizedBox(height: 22),
                MCard(
                  child: Row(
                    children: [
                      InitialsAvatar(b.customerName, size: 58),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.customerName,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                color: MColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.serviceName,
                              style: const TextStyle(
                                fontSize: 15,
                                color: MColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CustomerPhoneCard(phone: b.customerPhone),
                const SizedBox(height: 14),
                if (b.isDone) ...[
                  MCard(
                    color: MColors.tealSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.task_alt,
                              color: MColors.teal,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Done by ${b.doneBy}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: MColors.teal,
                                ),
                              ),
                            ),
                            Text(
                              timeAgo(b.doneAt!),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: MColors.teal,
                              ),
                            ),
                          ],
                        ),
                        if (b.doneNotes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            b.doneNotes,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: MColors.text,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: MColors.navy,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${mWeekdaysLong[d.weekday - 1]}, ${d.day} ${mMonthsLong[d.month - 1]}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.time,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      row(
                        'Price',
                        b.servicePrice == null
                            ? 'POA'
                            : mMoney(b.servicePrice!),
                        strong: true,
                      ),
                      const Divider(height: 1, color: MColors.border),
                      row(
                        'Deposit paid',
                        '${mMoney(b.depositPaid)} · ${b.paymentMethod}',
                      ),
                      if (balance != null) ...[
                        const Divider(height: 1, color: MColors.border),
                        row('Pay at salon', mMoney(balance)),
                      ],
                      const Divider(height: 1, color: MColors.border),
                      row('Reference', b.reference),
                      const Divider(height: 1, color: MColors.border),
                      row(
                        'Booked',
                        '${relativeDay(b.createdAt)} · ${timeAgo(b.createdAt)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                if (b.isPending && b.isUpcoming)
                  Row(
                    children: [
                      Expanded(
                        child: MSecondaryButton(
                          'Decline',
                          onPressed: () => declineBooking(context, b),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MPrimaryButton(
                          'Accept booking',
                          compact: true,
                          onPressed: () => acceptBooking(context, b),
                        ),
                      ),
                    ],
                  )
                else if (b.isConfirmed && b.isUpcoming) ...[
                  MPrimaryButton(
                    'Message customer',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => showMessageSheet(context, b),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: MLink(
                      'Cancel booking',
                      onTap: () => _cancel(context, b),
                    ),
                  ),
                ],
                _SentMessages(reference: b.reference),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Messages already sent for this booking (newest first).
class _SentMessages extends StatelessWidget {
  final String reference;
  const _SentMessages({required this.reference});

  @override
  Widget build(BuildContext context) {
    final list = BookingStore.instance.messagesFor(reference);
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Text('MESSAGES SENT', style: mCaps),
        const SizedBox(height: 12),
        for (final m in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: MColors.text,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${timeAgo(m.at)} · ${m.readByCustomer ? 'Seen' : 'Delivered'}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: MColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

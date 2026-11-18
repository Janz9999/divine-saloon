// lib/customer/salon_messages.dart
//
// Messages the salon (manager) sent to the customer.
//  • SalonMessagesSection — on the Activity screen, newest messages first.
//  • BookingMessages      — on a booking's page; marks them as read.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'activity_screen.dart' show BookingDetailScreen;
import 'booking_store.dart';

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

class _MessageBubble extends StatelessWidget {
  final SalonMessage message;
  final String? subtitle;
  final VoidCallback? onTap;
  const _MessageBubble({required this.message, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !message.readByCustomer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: unread ? AppColors.accentSoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: unread
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 20,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Booking.salonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Text(
                            _ago(message.at),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.text,
                          height: 1.4,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Activity screen: the latest messages from the salon (hidden when there are none).
class SalonMessagesSection extends StatelessWidget {
  const SalonMessagesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SalonMessage>>(
      valueListenable: BookingStore.instance.messages,
      builder: (context, all, _) {
        if (all.isEmpty) return const SizedBox.shrink();
        final unread = all.where((m) => !m.readByCustomer).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Messages from the salon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$unread new',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final m in all.take(3))
              Builder(
                builder: (context) {
                  final b = BookingStore.instance.find(m.bookingRef);
                  return _MessageBubble(
                    message: m,
                    subtitle: b == null
                        ? null
                        : 'About: ${b.serviceName} · ${b.time}',
                    onTap: b == null
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(booking: b),
                            ),
                          ),
                  );
                },
              ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }
}

/// Booking page: all messages for this booking. Opening it marks them read.
class BookingMessages extends StatefulWidget {
  final String reference;
  const BookingMessages({super.key, required this.reference});

  @override
  State<BookingMessages> createState() => _BookingMessagesState();
}

class _BookingMessagesState extends State<BookingMessages> {
  void _markRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) BookingStore.instance.markMessagesRead(widget.reference);
    });
  }

  @override
  void initState() {
    super.initState();
    _markRead();
    BookingStore.instance.messages.addListener(
      _markRead,
    ); // new message while open
  }

  @override
  void dispose() {
    BookingStore.instance.messages.removeListener(_markRead);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SalonMessage>>(
      valueListenable: BookingStore.instance.messages,
      builder: (context, _, _) {
        final list = BookingStore.instance.messagesFor(widget.reference);
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const Text(
              'Messages from the salon',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            for (final m in list) _MessageBubble(message: m),
          ],
        );
      },
    );
  }
}

/// Wraps the bottom-bar bookmark icon with a dot count of unread salon messages.
class MessageBadge extends StatelessWidget {
  final Widget child;
  const MessageBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<SalonMessage>>(
        valueListenable: BookingStore.instance.messages,
        builder: (context, all, _) {
          final n = all.where((m) => !m.readByCustomer).length;
          return Badge(
            isLabelVisible: n > 0,
            label: Text('$n'),
            backgroundColor: AppColors.accent,
            child: child,
          );
        },
      );
}

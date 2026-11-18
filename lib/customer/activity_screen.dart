// lib/customer/activity_screen.dart
//
// "Activity" tab (bookmark icon in the bottom bar).
//  • ActivityScreen       — list of the customer's paid bookings, or "No bookings".
//  • BookingDetailScreen  — "Booking confirmed" details for one booking
//                           (also shown straight after a successful payment).

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'customer_nav.dart';
import 'profile/profile_ui.dart' show openProfile;

import 'package:url_launcher/url_launcher.dart';

import 'booking_store.dart';
import 'salon_messages.dart';

// Colours from the design
const Color _bg = AppColors.bg;
const Color _blue = AppColors.accent;
const Color _text = AppColors.text;
const Color _muted = AppColors.muted;
const Color _border = AppColors.border;
const Color _infoBg = AppColors.accentSoft;

const List<String> _months = [
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
const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String _formatDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

String _money(num v) => v == v.roundToDouble()
    ? '£${v.toStringAsFixed(0)}'
    : '£${v.toStringAsFixed(2)}';

/// Opens Google Maps with directions to the salon.
Future<void> openSalonDirections(BuildContext context) async {
  final dest = Uri.encodeComponent(
    '${Booking.salonName}, ${Booking.salonAddress}',
  );
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$dest',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not open maps')));
  }
}

/// Opens the Activity screen from any bottom bar.
void openActivity(BuildContext context) {
  openCustomerTab(context, const ActivityScreen());
}

// =========================================================
// ACTIVITY SCREEN (bookings list)
// =========================================================
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        child: ValueListenableBuilder<List<Booking>>(
          valueListenable: BookingStore.instance.bookings,
          builder: (context, all, _) {
            final upcoming = all.where((b) => b.isUpcoming).toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final past = all.where((b) => !b.isUpcoming).toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your bookings',
                  style: TextStyle(fontSize: 14, color: _muted),
                ),
                const SizedBox(height: 20),
                const SalonMessagesSection(),
                if (all.isEmpty)
                  const _EmptyBookings()
                else ...[
                  if (upcoming.isNotEmpty) ...[
                    const _SectionTitle('Upcoming'),
                    for (final b in upcoming) _BookingTile(booking: b),
                  ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const _SectionTitle('Past'),
                    for (final b in past) _BookingTile(booking: b),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _text,
      ),
    ),
  );
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _infoBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.bookmark_border, color: _blue, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'No bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'When you book and pay for a treatment,\nit will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => goCustomerHome(context),
            child: const Text(
              'Browse treatments',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: booking),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const _ServiceIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatDate(booking.date)} · ${booking.time}',
                        style: const TextStyle(fontSize: 12.5, color: _muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.reference,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(booking.statusLabel, active: booking.isActive),
                const Icon(Icons.chevron_right, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// BOOKING DETAIL SCREEN ("Booking confirmed")
// =========================================================
String _headerTitle(Booking b) => switch (b.status) {
  BookingStatus.pending => b.isUpcoming ? 'Booking requested' : 'Not confirmed',
  BookingStatus.confirmed =>
    b.isUpcoming ? 'Booking confirmed' : 'Booking completed',
  BookingStatus.declined => 'Booking declined',
  BookingStatus.cancelled => 'Booking cancelled',
};

String _headerText(Booking b) => switch (b.status) {
  BookingStatus.pending =>
    b.isUpcoming
        ? "Your deposit is paid. We'll let you know as soon as the salon confirms your appointment."
        : 'The salon did not confirm this appointment in time.',
  BookingStatus.confirmed =>
    b.isUpcoming
        ? "You're all set. Here are the details of your upcoming appointment."
        : 'Here are the details of your past appointment.',
  BookingStatus.declined => 'Sorry, the salon could not take this booking. Your deposit will be refunded.',
  BookingStatus.cancelled => 'This appointment was cancelled.',
};

IconData _headerIcon(Booking b) => switch (b.status) {
  BookingStatus.pending => Icons.hourglass_top_rounded,
  BookingStatus.confirmed =>
    b.isUpcoming ? Icons.check_circle_outline : Icons.history,
  _ => Icons.cancel_outlined,
};

class BookingDetailScreen extends StatelessWidget {
  final Booking booking;

  /// True when opened right after paying — the back arrow then goes to
  /// "My bookings" instead of back to the payment form.
  final bool justBooked;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    this.justBooked = false,
  });

  void _back(BuildContext context) {
    if (justBooked) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ActivityScreen()),
        isCustomerRoot,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-read so a status change by the salon (accept / decline) shows here.
    final booking =
        BookingStore.instance.find(this.booking.reference) ?? this.booking;
    final upcoming = booking.isUpcoming;
    return PopScope(
      canPop: !justBooked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: Scaffold(
        backgroundColor: _bg,
        bottomNavigationBar: const _BottomNav(),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Top bar
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _back(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back, color: _text, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My bookings',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Header
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _infoBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_headerIcon(booking), color: _blue, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                _headerTitle(booking),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _text,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _headerText(booking),
                style: const TextStyle(
                  fontSize: 15,
                  color: _muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bookmark_border, color: _blue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saved to My bookings for easy access.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Your appointment
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your appointment',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                  ),
                  _StatusChip(booking.statusLabel, active: booking.isActive),
                ],
              ),
              const SizedBox(height: 12),
              _AppointmentCard(booking: booking),
              BookingMessages(reference: booking.reference),
              const SizedBox(height: 26),

              // Getting there
              const Text(
                'Getting there',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: _MapPreview(),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.location_on_outlined,
                            color: _muted,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Booking.salonName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _text,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  Booking.salonAddress,
                                  style: TextStyle(fontSize: 14, color: _muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () => openSalonDirections(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.near_me_outlined, size: 20),
                          label: const Text(
                            'Get directions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (upcoming) ...[
                const SizedBox(height: 14),
                const Text(
                  'Please arrive 5 minutes early for your appointment.',
                  style: TextStyle(fontSize: 13, color: _muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Booking booking;
  const _AppointmentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final price = booking.servicePrice;
    final balance = booking.balanceDue;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ServiceIcon(size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'In-store appointment',
                      style: TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: _border),
          _infoRow(
            Icons.person_outline,
            'Provider',
            Booking.salonName,
            bold: true,
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.calendar_today_outlined,
            'Date & time',
            '${_formatDate(booking.date)} · ${booking.time}',
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.confirmation_number_outlined,
            'Booking reference',
            booking.reference,
          ),
          const Divider(height: 32, color: _border),
          _priceRow('Treatment price', price == null ? 'POA' : _money(price)),
          if (balance != null) ...[
            const SizedBox(height: 8),
            _priceRow('Pay at salon', _money(balance)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Deposit paid',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
              ),
              Text(
                _money(booking.depositPaid),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${booking.paymentMethod} · GBP',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(icon, color: _muted, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.5,
                  color: _text,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: _muted),
        ),
      ),
      Text(value, style: const TextStyle(fontSize: 13.5, color: _muted)),
    ],
  );
}

// =========================================================
// Small shared widgets
// =========================================================
class _ServiceIcon extends StatelessWidget {
  final double size;
  const _ServiceIcon({this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _infoBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(Icons.content_cut, color: _blue, size: size * 0.5),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;
  const _StatusChip(this.label, {required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: active ? _infoBg : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: active ? _blue : _muted,
      ),
    ),
  );
}

/// Simple drawn map preview (no Google Maps API key needed).
class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _MapPainter())),
        const Positioned(
          left: 14,
          top: 12,
          child: Text(
            'CREWE',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE5533D), size: 46),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Text(
                  'Divine Aesthetics',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 12,
          bottom: 8,
          child: Text(
            'Map preview',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEBE6),
    );

    final park = Paint()..color = const Color(0xFFD6E4CC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.78, -10, size.width * 0.3, 60),
        const Radius.circular(14),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-10, size.height * 0.7, 70, 80),
        const Radius.circular(14),
      ),
      park,
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.square;
    // Slightly tilted horizontal streets
    for (final y in [0.22, 0.52, 0.85]) {
      canvas.drawLine(
        Offset(0, size.height * (y + 0.08)),
        Offset(size.width, size.height * (y - 0.08)),
        road,
      );
    }
    // Vertical streets
    for (final x in [0.15, 0.42, 0.7, 0.92]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * (x + 0.04), size.height),
        road,
      );
    }

    final label = TextPainter(
      text: const TextSpan(
        text: 'West St',
        style: TextStyle(fontSize: 11, color: AppColors.muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(size.width * 0.72, size.height * 0.36));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom bar with the bookmark (Activity) tab active.
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.search, color: AppColors.muted),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.home_outlined, color: AppColors.muted),
                onPressed: () => goCustomerHome(context),
              ),
              IconButton(
                icon: const MessageBadge(
                  child: Icon(Icons.bookmark, color: Colors.black),
                ),
                onPressed: () {
                  // Already on Activity — go to the list if on a detail page.
                  if (context.findAncestorWidgetOfExactType<ActivityScreen>() ==
                      null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivityScreen()),
                      isCustomerRoot,
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.muted,
                ),
                onPressed: () => openProfile(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

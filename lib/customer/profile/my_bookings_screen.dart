// lib/customer/profile/my_bookings_screen.dart

import 'package:flutter/material.dart';

import '../booking_store.dart';
import 'appointment_details_screen.dart';
import 'profile_screen.dart' show NextVisitCard;
import 'profile_ui.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _showPast = false;

  void _openDetails(Booking b) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AppointmentDetailsScreen(reference: b.reference),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Booking>>(
      valueListenable: BookingStore.instance.bookings,
      builder: (context, all, _) {
        final upcoming = all.where((b) => b.isUpcoming).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final past = all.where((b) => !b.isUpcoming).toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

        return ProfilePage(
          title: 'My bookings',
          subtitle: 'A little time set aside for you.',
          bottomNav: const ProfileBottomNav(active: NavTab.profile),
          children: [
            _Tabs(
              upcomingCount: upcoming.length,
              showPast: _showPast,
              onChanged: (v) => setState(() => _showPast = v),
            ),
            const SizedBox(height: 20),
            if (!_showPast) ...[
              if (upcoming.isEmpty)
                const SoftBox(
                  title: 'No upcoming visits',
                  text: 'Book a treatment and it will appear here.',
                )
              else
                for (final b in upcoming)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NextVisitCard(
                      booking: b,
                      onManage: () => _openDetails(b),
                    ),
                  ),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Recent visits', style: serif(22)),
                const SizedBox(height: 12),
                _PastList(visits: past.take(3).toList(), onTap: _openDetails),
              ],
            ] else ...[
              if (past.isEmpty)
                const SoftBox(
                  title: 'No past visits yet',
                  text: 'Your completed visits will show here.',
                )
              else
                _PastList(visits: past, onTap: _openDetails),
            ],
            const SizedBox(height: 24),
            SoftBox(
              title: 'Ready for your next treat?',
              action: LinkText(
                'Book another visit',
                onTap: () => openBooking(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  final int upcomingCount;
  final bool showPast;
  final ValueChanged<bool> onChanged;
  const _Tabs({
    required this.upcomingCount,
    required this.showPast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, bool value) => Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              color: selected ? PColors.text : PColors.muted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PColors.beige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab('Upcoming ($upcomingCount)', !showPast, false),
          tab('Past visits', showPast, true),
        ],
      ),
    );
  }
}

class _PastList extends StatelessWidget {
  final List<Booking> visits;
  final ValueChanged<Booking> onTap;
  const _PastList({required this.visits, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          for (int i = 0; i < visits.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: PColors.border),
            InkWell(
              onTap: () => onTap(visits[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${visits[i].date.day.toString().padLeft(2, '0')} ${monthsShort[visits[i].date.month - 1].toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: PColors.brown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visits[i].serviceName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              color: PColors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            visits[i].servicePrice == null
                                ? 'POA'
                                : money(visits[i].servicePrice!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: PColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LinkText(
                      'Rebook',
                      size: 13,
                      onTap: () => openBooking(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// lib/customer/profile/rewards_screen.dart
//
// Points come from completed visits: 1 point per £1 (see Rewards in profile_store.dart).

import 'package:flutter/material.dart';

import '../booking_store.dart';
import 'profile_screen.dart' show RewardsProgressBar;
import 'profile_store.dart';
import 'profile_ui.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Booking>>(
      valueListenable: BookingStore.instance.bookings,
      builder: (context, _, _) {
        final points = Rewards.totalPoints();
        final next = Rewards.nextTier(points);
        final left = (next.points - points).clamp(0, next.points);
        final visits = Rewards.completedVisits();
        return ProfilePage(
          title: 'Your rewards',
          subtitle: 'A little thank-you for choosing yourself.',
          buttonLabel: 'Book a visit & earn points',
          onButton: () => openBooking(context),
          caption: 'Points are added after your completed visit.',
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: BoxDecoration(
                color: PColors.green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIVINE CIRCLE',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$points',
                        style: const TextStyle(
                          fontSize: 56,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Text(
                        '  points',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    left == 0
                        ? 'Your treat is ready.'
                        : 'Your next treat is getting closer.',
                    style: serif(19, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  RewardsProgressBar(value: points / next.points),
                  const SizedBox(height: 12),
                  Text(
                    left == 0
                        ? 'Ask for your £${next.discount} reward at the salon'
                        : '$left points to your £${next.discount} reward',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text('Your next rewards', style: serif(22)),
            const SizedBox(height: 12),
            PCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  for (int i = 0; i < Rewards.tiers.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: PColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '£${Rewards.tiers[i].discount} off your next visit',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    color: PColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Rewards.tiers[i].note,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: PColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          points >= Rewards.tiers[i].points
                              ? const Pill('Ready')
                              : Pill('${Rewards.tiers[i].points} pts'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text('Points activity', style: serif(22)),
            const SizedBox(height: 12),
            if (visits.isEmpty)
              const SoftBox(
                title: 'No points yet',
                text: 'You’ll earn 1 point for every £1 once your first visit is completed.',
              )
            else
              PCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < visits.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: PColors.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    visits[i].serviceName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: PColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    fullDate(visits[i].date),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: PColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${Rewards.pointsFor(visits[i])}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: PColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

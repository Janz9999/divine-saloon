// lib/worker/worker_shell.dart
//
// Worker home: Home · Calendar · Alerts · Profile, with the bottom bar.
// Opened from the login screen when signing in as a worker.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import '../manager/manager_calendar_screen.dart';
import 'worker_alerts_screen.dart';
import 'worker_home_screen.dart';
import 'worker_mark_done_screen.dart';
import 'worker_profile_screen.dart';
import 'worker_ui.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        backgroundColor: WColors.bg,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              WorkerHomeScreen(onOpenAlerts: () => _go(2)),
              // Same calendar as the manager, but only confirmed bookings,
              // and tapping one opens Mark as Done.
              ManagerCalendarScreen(
                title: 'My Calendar',
                subtitle: 'Confirmed bookings and team events.',
                showRequests: false,
                onOpenBooking: (ctx, b) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkerMarkDoneScreen(reference: b.reference),
                  ),
                ),
              ),
              const WorkerAlertsScreen(),
              const WorkerProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar: _BottomBar(current: _tab, onTap: _go),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget item(int i, IconData icon, String label, {int badge = 0}) {
      final on = i == current;
      return Expanded(
        child: InkWell(
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: on ? WColors.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    backgroundColor: WColors.accent,
                    child: Icon(
                      icon,
                      size: 24,
                      color: on ? WColors.accent : WColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: on ? WColors.accent : WColors.muted,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: WColors.card,
        border: Border(top: BorderSide(color: WColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            BookingStore.instance.activity,
            WorkerAlerts.instance.seen,
          ]),
          builder: (context, _) => Row(
            children: [
              item(0, Icons.home_outlined, 'Home'),
              item(1, Icons.calendar_today_outlined, 'Calendar'),
              item(
                2,
                Icons.notifications_none,
                'Alerts',
                badge: WorkerAlerts.instance.unread(),
              ),
              item(3, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

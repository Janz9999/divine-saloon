// lib/manager/manager_shell.dart
//
// Manager home: Overview · Calendar · Gallery · Alerts · Profile, with the bottom bar.
// Opened from the login screen when signing in as the manager.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import 'manager_activity_screen.dart';
import 'manager_calendar_screen.dart';
import 'manager_gallery_screen.dart';
import 'manager_overview_screen.dart';
import 'manager_profile_screen.dart';
import 'manager_ui.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from Calendar / Alerts / Profile returns to Overview first.
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        backgroundColor: MColors.bg,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              ManagerOverviewScreen(onOpenAlerts: () => _go(3)),
              const ManagerCalendarScreen(),
              const ManagerGalleryScreen(),
              const ManagerActivityScreen(),
              const ManagerProfileScreen(),
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
    Widget item(
      int i,
      IconData icon,
      IconData activeIcon,
      String label, {
      int badge = 0,
    }) {
      final on = i == current;
      return Expanded(
        child: InkWell(
          onTap: () => onTap(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: on ? MColors.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    backgroundColor: MColors.accent,
                    child: Icon(
                      on ? activeIcon : icon,
                      size: 24,
                      color: on ? MColors.accent : MColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: on ? MColors.accent : MColors.muted,
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
        color: MColors.card,
        border: Border(top: BorderSide(color: MColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<SalonActivity>>(
          valueListenable: BookingStore.instance.activity,
          builder: (context, _, _) => Row(
            children: [
              item(0, Icons.home_outlined, Icons.home_rounded, 'Overview'),
              item(
                1,
                Icons.calendar_today_outlined,
                Icons.calendar_today,
                'Calendar',
              ),
              item(
                2,
                Icons.photo_library_outlined,
                Icons.photo_library,
                'Gallery',
              ),
              item(
                3,
                Icons.notifications_none,
                Icons.notifications,
                'Alerts',
                badge: BookingStore.instance.unreadCount,
              ),
              item(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/worker/worker_home_screen.dart
//
// Worker home: stats, search, filters and the list of confirmed bookings.
// Each booking has a "Done" button that opens Mark as Done.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import '../manager/manager_ui.dart' show callCustomer, sameDay, dayOnly;
import 'worker_mark_done_screen.dart';
import 'worker_ui.dart';
import '../theme/app_text.dart';

class WorkerHomeScreen extends StatefulWidget {
  final VoidCallback onOpenAlerts;
  const WorkerHomeScreen({super.key, required this.onOpenAlerts});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

enum _Show { all, todo, done }

enum _Range { today, week, all }

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final _search = TextEditingController();
  _Show _show = _Show.all;
  _Range _range = _Range.today;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _inRange(Booking b) {
    final today = dayOnly(DateTime.now());
    return switch (_range) {
      _Range.today => sameDay(b.date, today),
      _Range.week =>
        !b.date.isBefore(today) &&
            b.date.isBefore(today.add(const Duration(days: 7))),
      _Range.all => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BookingStore.instance.bookings,
        BookingStore.instance.activity,
        WorkerAlerts.instance.seen,
        WorkerProfile.instance,
        _search,
      ]),
      builder: (context, _) {
        // Workers only see bookings the manager has confirmed.
        final mine = BookingStore.instance.bookings.value
            .where((b) => b.isConfirmed)
            .toList();
        final done = mine.where((b) => b.isDone).length;
        final q = _search.text.trim().toLowerCase();

        final list =
            mine.where((b) {
              if (_show == _Show.todo && b.isDone) return false;
              if (_show == _Show.done && !b.isDone) return false;
              if (q.isNotEmpty) {
                return b.customerName.toLowerCase().contains(q) ||
                    b.serviceName.toLowerCase().contains(q);
              }
              return _inRange(b);
            }).toList()..sort((a, b) {
              if (a.isDone != b.isDone) return a.isDone ? 1 : -1; // to-do first
              return a.startsAt.compareTo(b.startsAt);
            });
        final unread = WorkerAlerts.instance.unread();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Row(
              children: [
                const WorkerAvatar(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(fontSize: 13, color: WColors.muted),
                      ),
                      Text(
                        WorkerProfile.instance.firstName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: WColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Alerts',
                  onPressed: widget.onOpenAlerts,
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: WColors.accent,
                    child: const Icon(
                      Icons.notifications_none,
                      color: WColors.text,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: WColors.dark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _Stat('${mine.length}', 'Total bookings'),
                  _Stat('${mine.length - done}', 'To do'),
                  _Stat('$done', 'Done'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              style: const TextStyle(fontSize: 15, color: WColors.text),
              decoration: InputDecoration(
                hintText: 'Search clients or services',
                hintStyle: const TextStyle(
                  color: WColors.muted,
                  fontSize: 14.5,
                ),
                filled: true,
                fillColor: WColors.card,
                prefixIcon: const Icon(
                  Icons.search,
                  color: WColors.muted,
                  size: 20,
                ),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _search.clear,
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: WColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 0,
              runSpacing: 8,
              children: [
                WChip(
                  'All bookings',
                  selected: _show == _Show.all,
                  onTap: () => setState(() => _show = _Show.all),
                ),
                const SizedBox(width: 8),
                WChip(
                  'To do',
                  selected: _show == _Show.todo,
                  onTap: () => setState(() => _show = _Show.todo),
                ),
                const SizedBox(width: 8),
                WChip(
                  'Done',
                  selected: _show == _Show.done,
                  onTap: () => setState(() => _show = _Show.done),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
              decoration: BoxDecoration(
                color: WColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          q.isEmpty ? 'Upcoming Bookings' : 'Search results',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: WColors.text,
                          ),
                        ),
                      ),
                      if (q.isEmpty)
                        _RangeButton(
                          value: _range,
                          onChanged: (r) => setState(() => _range = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        mine.isEmpty
                            ? 'No confirmed bookings yet. They appear here once the manager accepts them.'
                            : 'Nothing here. Try another filter or “All”.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: WColors.muted,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    for (final b in list) _BookingCard(booking: b),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    ),
  );
}

class _RangeButton extends StatelessWidget {
  final _Range value;
  final ValueChanged<_Range> onChanged;
  const _RangeButton({required this.value, required this.onChanged});

  static const _labels = {
    _Range.today: 'Today',
    _Range.week: 'Next 7 days',
    _Range.all: 'All',
  };

  @override
  Widget build(BuildContext context) => PopupMenuButton<_Range>(
    initialValue: value,
    onSelected: onChanged,
    color: WColors.card,
    itemBuilder: (_) => [
      for (final r in _Range.values)
        PopupMenuItem(value: r, child: Text(_labels[r]!)),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _labels[value]!,
            style: const TextStyle(fontSize: 13.5, color: WColors.primary),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: WColors.primary,
          ),
        ],
      ),
    ),
  );
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    void open() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerMarkDoneScreen(reference: b.reference),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: b.isDone
            ? const Color(0xFFF6F7F7)
            : WColors.primarySoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 82,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wTime12(b.time),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: WColors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            wDate(b.date),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: WColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: WColors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            b.serviceName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: WColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (b.customerPhone.isNotEmpty)
                      IconButton(
                        tooltip: 'Call ${b.customerPhone}',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => callCustomer(context, b.customerPhone),
                        icon: const Icon(
                          Icons.call_outlined,
                          size: 19,
                          color: WColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    WorkStatusPill(b),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.isDone
                            ? 'Done by: ${b.doneBy}'
                            : (b.customerPhone.isEmpty ? '' : b.customerPhone),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: WColors.muted,
                        ),
                      ),
                    ),
                    if (!b.isDone)
                      FilledButton(
                        onPressed: open,
                        style: FilledButton.styleFrom(
                          backgroundColor: WColors.primary,
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Done'),
                      )
                    else
                      const Icon(
                        Icons.task_alt,
                        color: WColors.primary,
                        size: 22,
                      ),
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

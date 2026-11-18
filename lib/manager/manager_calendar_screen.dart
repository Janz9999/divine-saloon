// lib/manager/manager_calendar_screen.dart
//
// Calendar tab: month / week view. Each day lists the manager's own events
// (team, inventory, other) and the customer bookings for that day.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import 'manager_booking_screens.dart';
import 'manager_store.dart';
import 'manager_ui.dart';

class ManagerCalendarScreen extends StatefulWidget {
  /// Worker mode: only confirmed bookings, different title, and tapping a
  /// booking calls [onOpenBooking] instead of opening the manager's page.
  final String title;
  final String subtitle;
  final bool showRequests;
  final void Function(BuildContext context, Booking booking)? onOpenBooking;

  const ManagerCalendarScreen({
    super.key,
    this.title = 'Calendar',
    this.subtitle = 'Your team, bookings and daily tasks.',
    this.showRequests = true,
    this.onOpenBooking,
  });

  @override
  State<ManagerCalendarScreen> createState() => _ManagerCalendarScreenState();
}

/// One row in the day list — either a calendar event or a booking.
class _DayItem {
  final int minutes;
  final String time;
  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final Color soft;
  final CalendarEvent? event;
  final Booking? booking;
  const _DayItem({
    required this.minutes,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.soft,
    this.event,
    this.booking,
  });
}

class _ManagerCalendarScreenState extends State<ManagerCalendarScreen> {
  DateTime _selected = dayOnly(DateTime.now());
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _weekView = false;

  static (Color, Color) _tagColors(EventTag t) => switch (t) {
    EventTag.team => (MColors.teal, MColors.tealSoft),
    EventTag.inventory => (MColors.amber, MColors.amberSoft),
    EventTag.other => (MColors.navy, MColors.greyBtn),
  };

  List<_DayItem> _itemsFor(DateTime day) {
    final items = <_DayItem>[
      for (final e in ManagerStore.instance.events.value)
        if (sameDay(e.date, day))
          _DayItem(
            minutes: e.minutes,
            time: e.time,
            title: e.title,
            subtitle: e.note,
            tag: e.tag.label,
            color: _tagColors(e.tag).$1,
            soft: _tagColors(e.tag).$2,
            event: e,
          ),
      for (final b in BookingStore.instance.bookings.value)
        if ((widget.showRequests ? b.isActive : b.isConfirmed) &&
            sameDay(b.date, day))
          _DayItem(
            minutes: b.startsAt.hour * 60 + b.startsAt.minute,
            time: b.time,
            title: '${b.serviceName} · ${b.customerName}',
            subtitle: b.isPending
                ? 'Waiting for your answer'
                : b.isDone
                ? 'Done by ${b.doneBy}'
                : 'Confirmed · ${b.servicePrice == null ? 'POA' : mMoney(b.servicePrice!)}',
            tag: b.isPending ? 'Request' : (b.isDone ? 'Done' : 'Booking'),
            color: MColors.accent,
            soft: MColors.accentSoft,
            booking: b,
          ),
    ]..sort((a, b) => a.minutes.compareTo(b.minutes));
    return items;
  }

  void _shift(int dir) => setState(() {
    if (_weekView) {
      _selected = _selected.add(Duration(days: 7 * dir));
      _month = DateTime(_selected.year, _selected.month);
    } else {
      _month = DateTime(_month.year, _month.month + dir);
    }
  });

  void _select(DateTime d) => setState(() {
    _selected = dayOnly(d);
    _month = DateTime(d.year, d.month);
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ManagerStore.instance.events,
        BookingStore.instance.bookings,
      ]),
      builder: (context, _) {
        final dayItems = _itemsFor(_selected);
        final s = _selected;
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.title, style: mTitle)),
                MPrimaryButton(
                  'Add event',
                  icon: Icons.add,
                  compact: true,
                  onPressed: () => showAddEventSheet(context, _selected),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(widget.subtitle, style: mSubtitle),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${mMonthsLong[_month.month - 1]} ${_month.year}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: MColors.text,
                      ),
                    ),
                  ),
                ),
                _ArrowButton(Icons.chevron_left, () => _shift(-1)),
                _ArrowButton(Icons.chevron_right, () => _shift(1)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                MChipButton(
                  'Month',
                  selected: !_weekView,
                  onTap: () => setState(() => _weekView = false),
                ),
                const SizedBox(width: 10),
                MChipButton(
                  'Week',
                  selected: _weekView,
                  onTap: () => setState(() => _weekView = true),
                ),
                const Spacer(),
                if (!sameDay(_selected, DateTime.now()))
                  MLink('Today', onTap: () => _select(DateTime.now())),
              ],
            ),
            const SizedBox(height: 16),
            MCard(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
              child: _CalendarGrid(
                month: _month,
                selected: _selected,
                weekOnly: _weekView,
                hasItems: (d) => _itemsFor(d).isNotEmpty,
                onSelect: _select,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${mWeekdaysLong[s.weekday - 1]}, ${s.day} ${mMonthsShort[s.month - 1]}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: MColors.text,
                    ),
                  ),
                ),
                Text(
                  '${dayItems.length} event${dayItems.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 14, color: MColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dayItems.isEmpty)
              MCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nothing planned for this day.',
                        style: TextStyle(fontSize: 14.5, color: MColors.muted),
                      ),
                    ),
                    MLink(
                      'Add event',
                      onTap: () => showAddEventSheet(context, _selected),
                    ),
                  ],
                ),
              )
            else
              for (final item in dayItems)
                _DayRow(item: item, onOpenBooking: widget.onOpenBooking),
          ],
        );
      },
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    style: IconButton.styleFrom(backgroundColor: MColors.card),
    icon: Icon(icon, color: MColors.text),
  );
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final bool weekOnly;
  final bool Function(DateTime) hasItems;
  final ValueChanged<DateTime> onSelect;
  const _CalendarGrid({
    required this.month,
    required this.selected,
    required this.weekOnly,
    required this.hasItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Monday-first grid.
    final List<DateTime> days;
    if (weekOnly) {
      final start = selected.subtract(Duration(days: selected.weekday - 1));
      days = [for (int i = 0; i < 7; i++) start.add(Duration(days: i))];
    } else {
      final first = DateTime(month.year, month.month, 1);
      final start = first.subtract(Duration(days: first.weekday - 1));
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final cells = ((first.weekday - 1 + daysInMonth) / 7).ceil() * 7;
      days = [
        for (int i = 0; i < cells; i++)
          DateTime(start.year, start.month, start.day + i),
      ];
    }
    final today = DateTime.now();

    Widget cell(DateTime d) {
      final isSel = sameDay(d, selected);
      final inMonth = weekOnly || d.month == month.month;
      final isToday = sameDay(d, today);
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(d),
          child: SizedBox(
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel ? MColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !isSel
                        ? Border.all(color: MColors.accent)
                        : null,
                  ),
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSel || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSel
                          ? Colors.white
                          : (inMonth ? MColors.text : MColors.faint),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: hasItems(d) ? MColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(fontSize: 14, color: MColors.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (int r = 0; r < days.length; r += 7)
          Row(children: [for (final d in days.sublist(r, r + 7)) cell(d)]),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final _DayItem item;
  final void Function(BuildContext context, Booking booking)? onOpenBooking;
  const _DayRow({required this.item, this.onOpenBooking});

  Future<void> _eventOptions(BuildContext context, CalendarEvent e) async {
    final delete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: MColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.title, style: mSection),
              const SizedBox(height: 6),
              Text(
                '${relativeDay(e.date)} · ${e.time} · ${e.tag.label}',
                style: mSubtitle,
              ),
              if (e.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  e.note,
                  style: const TextStyle(fontSize: 15, color: MColors.text),
                ),
              ],
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_outline,
                  color: MColors.accent,
                ),
                title: const Text(
                  'Delete event',
                  style: TextStyle(color: MColors.accent),
                ),
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (delete == true) {
      ManagerStore.instance.removeEvent(e.id);
      if (context.mounted) mSnack(context, 'Event deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                item.time,
                style: const TextStyle(fontSize: 15, color: MColors.muted),
              ),
            ),
          ),
          Expanded(
            child: MCard(
              padding: EdgeInsets.zero,
              onTap: () {
                if (item.booking != null && onOpenBooking != null) {
                  onOpenBooking!(context, item.booking!);
                } else if (item.booking != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagerBookingDetailScreen(
                        reference: item.booking!.reference,
                      ),
                    ),
                  );
                } else if (item.event != null) {
                  _eventOptions(context, item.event!);
                }
              },
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      color: item.color,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: MColors.text,
                              ),
                            ),
                            if (item.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: MColors.muted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            MPill(
                              item.tag,
                              bg: item.soft,
                              fg: item.color,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Add event ─────────────────────────

Future<void> showAddEventSheet(
  BuildContext context,
  DateTime initialDate,
) async {
  final title = TextEditingController();
  final note = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime date = initialDate;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  EventTag tag = EventTag.team;

  String fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  final saved = await showModalBottomSheet<bool>(
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
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add event', style: mSection),
                const SizedBox(height: 18),
                MField(
                  label: 'Title',
                  controller: title,
                  hint: 'e.g. Staff meeting',
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Please add a title' : null,
                ),
                MField(
                  label: 'Details (optional)',
                  controller: note,
                  hint: 'e.g. Morning briefing with salon crew',
                ),
                const Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 15,
                    color: MColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final t in EventTag.values)
                      MChipButton(
                        t.label,
                        selected: tag == t,
                        onTap: () => setSheet(() => tag = t),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PickerBox(
                        icon: Icons.calendar_today_outlined,
                        label:
                            '${date.day} ${mMonthsShort[date.month - 1]} ${date.year}',
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 2),
                          );
                          if (d != null) setSheet(() => date = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerBox(
                        icon: Icons.schedule,
                        label: fmt(time),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: time,
                          );
                          if (t != null) setSheet(() => time = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                MPrimaryButton(
                  'Save event',
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (saved == true) {
    ManagerStore.instance.addEvent(
      title: title.text.trim(),
      note: note.text.trim(),
      date: date,
      time: fmt(time),
      tag: tag,
    );
    if (context.mounted) mSnack(context, 'Event added');
  }
}

class _PickerBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: MColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: MColors.border),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: MColors.muted),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: MColors.text),
            ),
          ],
        ),
      ),
    ),
  );
}

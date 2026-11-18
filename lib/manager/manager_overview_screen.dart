// lib/manager/manager_overview_screen.dart
//
// Overview tab: welcome, business numbers, earnings chart, today's bookings.
// Everything is worked out from the real bookings customers have made.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/log_out.dart';
import '../customer/booking_store.dart';
import 'manager_booking_screens.dart';
import 'manager_store.dart';
import 'manager_ui.dart';

class ManagerOverviewScreen extends StatefulWidget {
  final VoidCallback onOpenAlerts;
  const ManagerOverviewScreen({super.key, required this.onOpenAlerts});

  @override
  State<ManagerOverviewScreen> createState() => _ManagerOverviewScreenState();
}

class _ManagerOverviewScreenState extends State<ManagerOverviewScreen> {
  bool _businessMonthly = true;
  bool _earningsWeekly = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BookingStore.instance.bookings,
        ManagerStore.instance.expenses,
        ManagerProfile.instance,
      ]),
      builder: (context, _) {
        final all = BookingStore.instance.bookings.value;
        final today =
            all
                .where((b) => b.isActive && sameDay(b.date, DateTime.now()))
                .toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final pending = all.where((b) => b.isPending && b.isUpcoming).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          children: [
            _Header(name: ManagerProfile.instance.fullName),
            if (pending > 0) ...[
              const SizedBox(height: 18),
              _PendingBanner(count: pending, onTap: widget.onOpenAlerts),
            ],
            const SizedBox(height: 26),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Business overview',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: MColors.text,
                    ),
                  ),
                ),
                MChipButton(
                  _businessMonthly ? 'Monthly' : 'Weekly',
                  onTap: () =>
                      setState(() => _businessMonthly = !_businessMonthly),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BusinessStats(bookings: all, monthly: _businessMonthly),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text('Earnings overview', style: mSection),
                ),
                MChipButton(
                  _earningsWeekly ? 'Weekly' : 'Monthly',
                  onTap: () =>
                      setState(() => _earningsWeekly = !_earningsWeekly),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EarningsCard(bookings: all, weekly: _earningsWeekly),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text('Today’s bookings', style: mSection),
                ),
                MLink(
                  'View all',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManagerBookingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (today.isEmpty)
              const MCard(
                child: Text(
                  'No bookings today. New customer bookings will show here.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: MColors.muted,
                    height: 1.4,
                  ),
                ),
              )
            else
              for (final b in today)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TodayBookingCard(booking: b),
                ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const ManagerAvatar(size: 56),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WELCOME BACK', style: mCaps),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                color: MColors.text,
              ),
            ),
          ],
        ),
      ),
      const MPill('Manager', bg: MColors.tealSoft, fg: MColors.teal, size: 15),
      const SizedBox(width: 6),
      IconButton(
        tooltip: 'Log out',
        icon: const Icon(Icons.logout_rounded, color: MColors.text),
        onPressed: () => confirmAndLogOut(
          context,
          dialogColor: MColors.card,
          accentColor: MColors.accent,
        ),
      ),
    ],
  );
}

class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => MCard(
    color: MColors.accentSoft,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    onTap: onTap,
    child: Row(
      children: [
        const Icon(Icons.notifications_active_outlined, color: MColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            count == 1
                ? '1 booking request needs your answer'
                : '$count booking requests need your answer',
            style: const TextStyle(
              fontSize: 14.5,
              color: MColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(Icons.chevron_right, color: MColors.accent),
      ],
    ),
  );
}

// ───────────────────────── Business stats ─────────────────────────

class _BusinessStats extends StatelessWidget {
  final List<Booking> bookings;
  final bool monthly;
  const _BusinessStats({required this.bookings, required this.monthly});

  static (DateTime, DateTime) period(bool monthly, int offset) {
    final now = DateTime.now();
    if (monthly) {
      return (
        DateTime(now.year, now.month + offset, 1),
        DateTime(now.year, now.month + offset + 1, 1),
      );
    }
    final start = dayOnly(now)
        .subtract(Duration(days: now.weekday % 7)); // Sunday
    final s = start.add(Duration(days: 7 * offset));
    return (s, s.add(const Duration(days: 7)));
  }

  static bool _inRange(DateTime t, (DateTime, DateTime) r) =>
      !t.isBefore(r.$1) && t.isBefore(r.$2);

  static String _change(int now, int before, String unit) {
    if (before == 0) {
      return now == 0 ? 'No change vs last $unit' : 'New this $unit';
    }
    final pct = ((now - before) / before * 100).round();
    return '${pct >= 0 ? '+' : ''}$pct% vs last $unit';
  }

  @override
  Widget build(BuildContext context) {
    final cur = period(monthly, 0);
    final prev = period(monthly, -1);
    final unit = monthly ? 'month' : 'week';

    // Incoming = booking requests received in the period.
    int incoming((DateTime, DateTime) r) =>
        bookings.where((b) => _inRange(b.createdAt, r)).length;
    // Past = completed visits in the period.
    int past((DateTime, DateTime) r) =>
        bookings.where((b) => b.isCompleted && _inRange(b.startsAt, r)).length;

    final inNow = incoming(cur), inBefore = incoming(prev);
    final pastNow = past(cur), pastBefore = past(prev);

    Widget card(String label, int value, String change, bool dark) => Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 16, 22),
        decoration: BoxDecoration(
          color: dark ? MColors.navy : MColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                color: dark ? Colors.white70 : MColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : MColors.text,
                height: 1,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              change,
              style: TextStyle(
                fontSize: 13,
                color: dark
                    ? Colors.white.withValues(alpha: 0.85)
                    : MColors.teal,
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        card('Incoming bookings', inNow, _change(inNow, inBefore, unit), true),
        const SizedBox(width: 16),
        card(
          'Past bookings',
          pastNow,
          _change(pastNow, pastBefore, unit),
          false,
        ),
      ],
    );
  }
}

// ───────────────────────── Earnings chart ─────────────────────────

class _EarningsCard extends StatelessWidget {
  final List<Booking> bookings;
  final bool weekly;
  const _EarningsCard({required this.bookings, required this.weekly});

  Future<void> _addExpense(BuildContext context) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          22,
          22,
          22 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add expense', style: mSection),
              const SizedBox(height: 18),
              MField(
                label: 'Amount (£)',
                controller: amount,
                hint: 'e.g. 45',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (double.tryParse((v ?? '').trim()) ?? 0) <= 0
                    ? 'Enter an amount'
                    : null,
              ),
              MField(
                label: 'What was it for?',
                controller: note,
                hint: 'e.g. Hair dye stock',
              ),
              MPrimaryButton(
                'Save expense',
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
    );
    if (ok == true) {
      ManagerStore.instance.addExpense(
        amount: double.parse(amount.text.trim()),
        note: note.text.trim(),
        date: DateTime.now(),
      );
      if (context.mounted) mSnack(context, 'Expense added');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = ManagerStore.instance.expenses.value;
    late final List<String> labels;
    late final int Function(DateTime) bucket; // -1 = outside the range

    if (weekly) {
      final start = dayOnly(now)
          .subtract(Duration(days: now.weekday % 7)); // Sunday
      labels = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      bucket = (t) {
        final d = dayOnly(t).difference(start).inDays;
        return d >= 0 && d < 7 ? d : -1;
      };
    } else {
      labels = const [
        'J',
        'F',
        'M',
        'A',
        'M',
        'J',
        'J',
        'A',
        'S',
        'O',
        'N',
        'D',
      ];
      bucket = (t) => t.year == now.year ? t.month - 1 : -1;
    }

    final income = List<double>.filled(labels.length, 0);
    final expense = List<double>.filled(labels.length, 0);
    for (final b in bookings) {
      // Income = confirmed visits (deposits only for bookings still waiting).
      final i = bucket(b.date);
      if (i < 0) continue;
      if (b.isConfirmed) {
        income[i] += b.value;
      } else if (b.isPending) {
        income[i] += b.depositPaid;
      }
    }
    for (final e in expenses) {
      final i = bucket(e.date);
      if (i >= 0) expense[i] += e.amount;
    }
    final totalIn = income.fold<double>(0, (a, b) => a + b);
    final totalOut = expense.fold<double>(0, (a, b) => a + b);

    Widget legend(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontSize: 15, color: MColors.muted)),
      ],
    );

    return MCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    legend(MColors.teal, 'Income'),
                    legend(MColors.accent, 'Expense'),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _addExpense(context),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16, color: MColors.accent),
                      Text(
                        ' Expense',
                        style: TextStyle(fontSize: 13, color: MColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                labels: labels,
                income: income,
                expense: expense,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${weekly ? 'This week' : 'This year'}: ${mMoney(totalIn)} in · ${mMoney(totalOut)} out',
              style: const TextStyle(fontSize: 12.5, color: MColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> income;
  final List<double> expense;
  _LineChartPainter({
    required this.labels,
    required this.income,
    required this.expense,
  });

  static double _niceMax(double v) {
    if (v <= 0) return 400;
    final step = math.pow(10, (math.log(v / 3) / math.ln10).floor()).toDouble();
    for (final m in [1, 2, 2.5, 4, 5, 10]) {
      if (step * m * 3 >= v) return step * m * 3;
    }
    return step * 30;
  }

  void _text(
    Canvas c,
    String s,
    Offset at, {
    TextAlign align = TextAlign.left,
    double size = 12,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, color: MColors.muted),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(c, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0, bottom = 26.0, top = 6.0, right = 8.0;
    final chartW = size.width - left - right;
    final chartH = size.height - bottom - top;
    final maxV = _niceMax([...income, ...expense].fold<double>(0, math.max));

    final grid = Paint()
      ..color = MColors.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = top + chartH - chartH * i / 3;
      for (double x = left; x < size.width - right; x += 6) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 3, size.width - right), y),
          grid,
        );
      }
      _text(
        canvas,
        mMoney((maxV * i / 3).round()),
        Offset(left - 8, y),
        align: TextAlign.right,
      );
    }

    final n = labels.length;
    double xAt(int i) => left + (n == 1 ? chartW / 2 : chartW * i / (n - 1));
    double yAt(double v) => top + chartH - (v / maxV) * chartH;

    for (int i = 0; i < n; i++) {
      _text(
        canvas,
        labels[i],
        Offset(xAt(i), size.height - 8),
        align: TextAlign.center,
        size: 12.5,
      );
    }

    Path line(List<double> vals) {
      final p = Path()..moveTo(xAt(0), yAt(vals[0]));
      for (int i = 1; i < n; i++) {
        p.lineTo(xAt(i), yAt(vals[i]));
      }
      return p;
    }

    // Expense — dotted terracotta.
    final expPaint = Paint()
      ..color = MColors.accent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final metric in line(expense).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 3, metric.length)),
          expPaint,
        );
      }
    }

    // Income — solid teal.
    canvas.drawPath(
      line(income),
      Paint()
        ..color = MColors.teal
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.labels != labels ||
      !listEquals(old.income, income) ||
      !listEquals(old.expense, expense);
}

bool listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ───────────────────────── Today's booking card ─────────────────────────

class TodayBookingCard extends StatelessWidget {
  final Booking booking;
  const TodayBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    void open() {
      HapticFeedback.selectionClick();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ManagerBookingDetailScreen(reference: booking.reference),
        ),
      );
    }

    return MCard(
      onTap: open,
      child: Row(
        children: [
          InitialsAvatar(booking.customerName, size: 54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: MColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.serviceName} · ${booking.time}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, color: MColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BookingStatusPill(booking),
              const SizedBox(height: 10),
              MLink('View details', size: 14, onTap: open),
            ],
          ),
        ],
      ),
    );
  }
}

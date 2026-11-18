// lib/worker/worker_mark_done_screen.dart
//
// "Mark as Done": the worker confirms the visit is finished, adds notes,
// and can send the customer an aftercare reminder. The manager gets an alert.

import 'package:flutter/material.dart';

import '../customer/booking_store.dart';
import '../manager/manager_ui.dart'
    show InitialsAvatar, MField, callCustomer, textCustomer;
import 'worker_ui.dart';

class WorkerMarkDoneScreen extends StatefulWidget {
  final String reference;
  const WorkerMarkDoneScreen({super.key, required this.reference});

  @override
  State<WorkerMarkDoneScreen> createState() => _WorkerMarkDoneScreenState();
}

class _WorkerMarkDoneScreenState extends State<WorkerMarkDoneScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _doneBy = TextEditingController(text: WorkerProfile.instance.name);
  final _notes = TextEditingController();
  bool _serviceCompleted = false;
  bool _clientHappy = false;
  bool _aftercare = false;

  @override
  void dispose() {
    _doneBy.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _confirm(Booking b) {
    if (!_formKey.currentState!.validate()) return;
    if (!_serviceCompleted) {
      wSnack(context, 'Please tick “Service completed” first');
      return;
    }
    final notes = [
      if (_notes.text.trim().isNotEmpty) _notes.text.trim(),
      if (_clientHappy) 'Client happy with the result.',
    ].join(' ');
    BookingStore.instance.markDone(
      b.reference,
      doneBy: _doneBy.text,
      notes: notes,
    );
    if (_aftercare) {
      final first = b.customerName.trim().split(RegExp(r'\s+')).first;
      BookingStore.instance.sendMessage(
        b.reference,
        'Hi $first, thank you for visiting us today! To keep your ${b.serviceName} looking its best, '
        'avoid washing for 48 hours, use a gentle sulphate-free shampoo and protect it from heat. '
        'Any questions, just get in touch.',
      );
    }
    Navigator.pop(context);
    wSnack(context, 'Marked as done — the manager has been notified');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WColors.bg,
      body: SafeArea(
        child: ValueListenableBuilder<List<Booking>>(
          valueListenable: BookingStore.instance.bookings,
          builder: (context, _, _) {
            final b = BookingStore.instance.find(widget.reference);
            if (b == null || !b.isConfirmed) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: WBackHeader('This booking is no longer active'),
              );
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  WBackHeader(b.isDone ? 'Booking done' : 'Mark as Done'),
                  const SizedBox(height: 22),
                  _Banner(done: b.isDone),
                  const SizedBox(height: 22),
                  const Text(
                    'BOOKING DETAILS',
                    style: TextStyle(
                      fontSize: 13,
                      color: WColors.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DetailsCard(booking: b),
                  const SizedBox(height: 22),
                  if (b.isDone)
                    _DoneSummary(booking: b)
                  else ...[
                    MField(
                      label: 'Done by *',
                      controller: _doneBy,
                      capitalization: TextCapitalization.words,
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Who did this service?'
                          : null,
                    ),
                    MField(
                      label: 'Notes (optional)',
                      controller: _notes,
                      hint: 'Add any notes…',
                      maxLines: 4,
                    ),
                    _Box(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Before you complete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: WColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _Check(
                            'Service completed',
                            _serviceCompleted,
                            (v) => setState(() => _serviceCompleted = v),
                          ),
                          _Check(
                            'Client happy with the result',
                            _clientHappy,
                            (v) => setState(() => _clientHappy = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      decoration: BoxDecoration(
                        color: WColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Send aftercare reminder',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: WColors.text,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Help your client care for their new look.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: WColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _aftercare,
                            activeTrackColor: WColors.primary,
                            onChanged: (v) => setState(() => _aftercare = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    WPrimaryButton(
                      'Confirm Done',
                      trailingIcon: Icons.check,
                      onPressed: () => _confirm(b),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final bool done;
  const _Banner({required this.done});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WColors.primarySoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          done ? 'All wrapped up' : 'Ready to wrap up?',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: WColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          done
              ? 'This visit is complete and the manager has been notified.'
              : 'Review the details before completing this visit.',
          style: const TextStyle(fontSize: 13.5, color: WColors.muted),
        ),
      ],
    ),
  );
}

class _Box extends StatelessWidget {
  final Widget child;
  const _Box({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: WColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: WColors.border),
    ),
    child: child,
  );
}

class _DetailsCard extends StatelessWidget {
  final Booking booking;
  const _DetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final hasPhone = b.customerPhone.isNotEmpty;
    return _Box(
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(
                b.customerName,
                size: 50,
                bg: WColors.accentSoft,
                fg: WColors.accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.customerName,
                      style: const TextStyle(fontSize: 18, color: WColors.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      b.serviceName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: WColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              WorkStatusPill(b),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: WColors.border),
          ),
          Row(
            children: [
              const Icon(Icons.schedule, size: 19, color: WColors.muted),
              const SizedBox(width: 8),
              Text(
                wTime12(b.time),
                style: const TextStyle(fontSize: 16, color: WColors.text),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.calendar_today_outlined,
                size: 17,
                color: WColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wDate(b.date),
                  style: const TextStyle(fontSize: 16, color: WColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 19, color: WColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPhone ? b.customerPhone : 'No phone number',
                  style: TextStyle(
                    fontSize: 16,
                    color: hasPhone ? WColors.text : WColors.faint,
                  ),
                ),
              ),
              if (hasPhone) ...[
                _RoundIcon(
                  Icons.call_outlined,
                  'Call',
                  () => callCustomer(context, b.customerPhone),
                ),
                const SizedBox(width: 8),
                _RoundIcon(
                  Icons.sms_outlined,
                  'Text',
                  () => textCustomer(context, b.customerPhone),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  const _RoundIcon(this.icon, this.tip, this.onTap);

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tip,
    onPressed: onTap,
    style: IconButton.styleFrom(backgroundColor: WColors.primarySoft),
    icon: Icon(icon, size: 19, color: WColors.primary),
  );
}

class _Check extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Check(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              activeColor: WColors.primary,
              side: const BorderSide(color: WColors.faint, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (v) => onChanged(v ?? false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: WColors.text),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DoneSummary extends StatelessWidget {
  final Booking booking;
  const _DoneSummary({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final t = b.doneAt!;
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, color: WColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Done by ${b.doneBy}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: WColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${wDate(t)} at ${wTime12('${t.hour}:${t.minute.toString().padLeft(2, '0')}')}',
            style: const TextStyle(fontSize: 13.5, color: WColors.muted),
          ),
          if (b.doneNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              b.doneNotes,
              style: const TextStyle(
                fontSize: 15,
                color: WColors.text,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

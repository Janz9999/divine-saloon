// lib/manager/manager_store.dart
//
// Manager-only data: profile, calendar events and expenses.
// Bookings and the Alerts feed live in BookingStore (shared with customers).
//
// Stored in Firestore:
//   profile          → the manager's own users/{uid} document (+ photo in Storage)
//   calendar events  → events/{id}    (manager only)
//   expenses         → expenses/{id}  (manager only)

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../customer/booking_store.dart';
import '../data/session.dart';

// ───────────────────────── Profile ─────────────────────────

class ManagerProfile extends ChangeNotifier with FirestoreProfile {
  ManagerProfile._() {
    bindToSession();
  }
  static final ManagerProfile instance = ManagerProfile._();

  String fullName = '';
  String bio = '';
  String position = 'Owner';
  String skills = '';
  Uint8List? photoBytes;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  // update(change) comes from FirestoreProfile: applies, rebuilds, saves.

  @override
  Uint8List? get photo => photoBytes;
  @override
  set photo(Uint8List? bytes) => photoBytes = bytes;

  @override
  void resetFields() {
    fullName = '';
    bio = '';
    position = 'Owner';
    skills = '';
  }

  @override
  void applyData(SessionUser user) {
    final d = user.data;
    fullName = d['name'] as String? ?? user.email.split('@').first;
    bio = d['bio'] as String? ?? '';
    position = d['position'] as String? ?? 'Owner';
    skills = d['skills'] as String? ?? '';
  }

  @override
  Map<String, dynamic> toData() => {
    'name': fullName.trim(),
    'bio': bio.trim(),
    'position': position.trim(),
    'skills': skills.trim(),
  };
}

// ───────────────────────── Calendar events ─────────────────────────

enum EventTag { team, inventory, other }

extension EventTagLabel on EventTag {
  String get label => switch (this) {
    EventTag.team => 'Team',
    EventTag.inventory => 'Inventory',
    EventTag.other => 'Other',
  };
}

class CalendarEvent {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final String time; // "09:00"
  final EventTag tag;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.time,
    required this.tag,
  });

  static CalendarEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final p = (d['date'] as String? ?? '').split('-');
    final date = p.length == 3
        ? DateTime(
            int.tryParse(p[0]) ?? 2000,
            int.tryParse(p[1]) ?? 1,
            int.tryParse(p[2]) ?? 1,
          )
        : DateTime.now();
    return CalendarEvent(
      id: doc.id,
      title: d['title'] as String? ?? '',
      note: d['note'] as String? ?? '',
      date: date,
      time: d['time'] as String? ?? '00:00',
      tag: EventTag.values.asNameMap()[d['tag']] ?? EventTag.other,
    );
  }

  int get minutes {
    final p = time.split(':');
    return (int.tryParse(p[0]) ?? 0) * 60 +
        (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }
}

// ───────────────────────── Expenses ─────────────────────────

class Expense {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  const Expense({
    required this.id,
    required this.amount,
    required this.note,
    required this.date,
  });

  static Expense fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Expense(
      id: doc.id,
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      note: d['note'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ───────────────────────── Store ─────────────────────────

class ManagerStore {
  ManagerStore._() {
    Session.instance.user.addListener(_onSessionChanged);
    _onSessionChanged(); // catch up if someone is already signed in
  }
  static final ManagerStore instance = ManagerStore._();

  final ValueNotifier<List<CalendarEvent>> events =
      ValueNotifier<List<CalendarEvent>>(const []);
  final ValueNotifier<List<Expense>> expenses = ValueNotifier<List<Expense>>(
    const [],
  );

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _eventsCol =>
      _db.collection('events');
  CollectionReference<Map<String, dynamic>> get _expensesCol =>
      _db.collection('expenses');

  final List<StreamSubscription<dynamic>> _subs = [];
  String? _listeningFor; // uid we're subscribed for (managers only)

  static const _months = [
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

  void _onSessionChanged() {
    final u = Session.instance.user.value;
    final uid = (u != null && u.isManager) ? u.uid : null;
    if (uid == _listeningFor) return;
    _listeningFor = uid;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    events.value = const [];
    expenses.value = const [];
    if (uid == null) return;

    _subs.add(
      _eventsCol.snapshots().listen(
        (snap) => events.value = [
          for (final d in snap.docs) CalendarEvent.fromDoc(d),
        ],
        onError: (Object e) =>
            debugPrint('ManagerStore: events listener error: $e'),
      ),
    );
    _subs.add(
      _expensesCol.snapshots().listen(
        (snap) =>
            expenses.value = [for (final d in snap.docs) Expense.fromDoc(d)],
        onError: (Object e) =>
            debugPrint('ManagerStore: expenses listener error: $e'),
      ),
    );
  }

  void _write(Future<void> op, String what) {
    op.catchError((Object e) => debugPrint('ManagerStore: $what failed: $e'));
  }

  void addEvent({
    required String title,
    required String note,
    required DateTime date,
    required String time,
    required EventTag tag,
  }) {
    _write(
      _eventsCol.add({
        'title': title,
        'note': note,
        'date': Booking.dateKey(date),
        'time': time,
        'tag': tag.name,
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'add event',
    );
    BookingStore.instance.log(
      tag == EventTag.inventory ? ActivityKind.inventory : ActivityKind.team,
      title,
      '${date.day} ${_months[date.month - 1]} · $time${note.isEmpty ? '' : ' · $note'}',
      read: true,
    );
  }

  void removeEvent(String id) {
    events.value = events.value.where((e) => e.id != id).toList();
    _write(_eventsCol.doc(id).delete(), 'remove event');
  }

  void addExpense({
    required double amount,
    required String note,
    required DateTime date,
  }) {
    _write(
      _expensesCol.add({
        'amount': amount,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      }),
      'add expense',
    );
  }
}

// lib/customer/booking_store.dart
//
// The salon's bookings, shared by the customer and manager screens.
//  • Customer pays            → booking is added as a *request* (pending).
//  • Manager accepts/declines → status changes; customer screens update.
//  • Customer cancels/moves   → manager sees it in Alerts.
//
// Every change is also written to [BookingStore.activity] — the manager's
// Alerts feed.
//
// Stored in Cloud Firestore so every phone sees the same data:
//   bookings/{reference}  — created by the stripeWebhook Cloud Function once
//                           the deposit is paid (never by the app itself)
//   activity/{id}         — the manager's Alerts feed (staff only)
//   messages/{id}         — salon → customer messages
//
// The store listens to whatever the signed-in user is allowed to see
// (staff: everything; customers: only their own) and exposes it through the
// same ValueNotifiers as before, so screens just rebuild when data changes.
// Writes go straight to Firestore; the listeners pick them up instantly
// (Firestore applies local writes to listeners before the server confirms).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum BookingStatus { pending, confirmed, declined, cancelled }

class Booking {
  final String reference; // e.g. BK-10482
  final String customerUid; // Firebase Auth uid of the customer
  final String customerName;
  final String customerPhone; // may be empty
  final String serviceName;
  final int? servicePrice; // null = POA
  final double depositPaid;
  final DateTime date;
  final String time; // e.g. "10:00"
  final String paymentMethod; // e.g. "Apple Pay" or "Visa ending in 4242"
  final DateTime createdAt;
  final BookingStatus status;

  // Filled in by the worker on "Mark as Done".
  final DateTime? doneAt;
  final String doneBy;
  final String doneNotes;

  static const String salonName = 'Divine Aesthetics & Beauty';
  static const String salonAddress = '32 West St, Crewe CW1 3HA';

  const Booking({
    required this.reference,
    this.customerUid = '',
    required this.customerName,
    this.customerPhone = '',
    required this.serviceName,
    required this.servicePrice,
    required this.depositPaid,
    required this.date,
    required this.time,
    required this.paymentMethod,
    required this.createdAt,
    this.status = BookingStatus.pending,
    this.doneAt,
    this.doneBy = '',
    this.doneNotes = '',
  });

  /// Date + time of the appointment, used for sorting / upcoming vs past.
  DateTime get startsAt {
    final parts = time.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  Booking copyWith({
    DateTime? date,
    String? time,
    BookingStatus? status,
    DateTime? doneAt,
    String? doneBy,
    String? doneNotes,
  }) => Booking(
    reference: reference,
    customerUid: customerUid,
    customerName: customerName,
    customerPhone: customerPhone,
    serviceName: serviceName,
    servicePrice: servicePrice,
    depositPaid: depositPaid,
    date: date ?? this.date,
    time: time ?? this.time,
    paymentMethod: paymentMethod,
    createdAt: createdAt,
    status: status ?? this.status,
    doneAt: doneAt ?? this.doneAt,
    doneBy: doneBy ?? this.doneBy,
    doneNotes: doneNotes ?? this.doneNotes,
  );

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Appointment day as stored in Firestore: "YYYY-MM-DD".
  static String dateKey(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static DateTime _parseDateKey(String? s) {
    final p = (s ?? '').split('-');
    if (p.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(p[0]) ?? 2000,
      int.tryParse(p[1]) ?? 1,
      int.tryParse(p[2]) ?? 1,
    );
  }

  static Booking fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Booking(
      reference: doc.id,
      customerUid: d['customerUid'] as String? ?? '',
      customerName: d['customerName'] as String? ?? 'Guest',
      customerPhone: d['customerPhone'] as String? ?? '',
      serviceName: d['serviceName'] as String? ?? '',
      servicePrice: (d['servicePrice'] as num?)?.toInt(),
      depositPaid: (d['depositPaid'] as num?)?.toDouble() ?? 0,
      date: _parseDateKey(d['date'] as String?),
      time: d['time'] as String? ?? '00:00',
      paymentMethod: d['paymentMethod'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status:
          BookingStatus.values.asNameMap()[d['status']] ??
          BookingStatus.pending,
      doneAt: (d['doneAt'] as Timestamp?)?.toDate(),
      doneBy: d['doneBy'] as String? ?? '',
      doneNotes: d['doneNotes'] as String? ?? '',
    );
  }

  bool get isPending => status == BookingStatus.pending;
  bool get isConfirmed => status == BookingStatus.confirmed;

  /// Still going ahead (waiting for the salon, or confirmed).
  bool get isActive => isPending || isConfirmed;

  /// A worker marked the visit as done.
  bool get isDone => doneAt != null;

  /// Active, not done yet, and in the future.
  bool get isUpcoming =>
      isActive && !isDone && startsAt.isAfter(DateTime.now());

  /// Confirmed and either marked done or the time has passed.
  bool get isCompleted =>
      isConfirmed && (isDone || !startsAt.isAfter(DateTime.now()));

  /// Short label for status chips, as the customer sees it.
  String get statusLabel => switch (status) {
    BookingStatus.pending =>
      isUpcoming ? 'Awaiting confirmation' : 'Not confirmed',
    BookingStatus.confirmed => isUpcoming ? 'Confirmed' : 'Completed',
    BookingStatus.declined => 'Declined',
    BookingStatus.cancelled => 'Cancelled',
  };

  /// Full price, or the deposit when the price is POA.
  double get value => (servicePrice ?? depositPaid).toDouble();

  /// Amount still to pay at the salon (null when the price is POA).
  double? get balanceDue {
    final price = servicePrice;
    if (price == null) return null;
    final left = price - depositPaid;
    return left > 0 ? left : 0;
  }
}

// ───────────────────────── Activity feed ─────────────────────────

enum ActivityKind {
  request, // new booking waiting for the manager
  payment,
  accepted,
  declined,
  cancelled,
  rescheduled,
  team, // calendar event for the team
  inventory,
  note,
  message, // manager sent a message to a customer
  completed, // worker marked a booking as done
}

class SalonActivity {
  final String id;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final DateTime at;
  final String? bookingRef;
  final bool read;

  const SalonActivity({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
    this.bookingRef,
    this.read = false,
  });

  bool get isBooking => switch (kind) {
    ActivityKind.request ||
    ActivityKind.payment ||
    ActivityKind.accepted ||
    ActivityKind.declined ||
    ActivityKind.cancelled ||
    ActivityKind.rescheduled ||
    ActivityKind.message ||
    ActivityKind.completed => true,
    _ => false,
  };

  static SalonActivity fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return SalonActivity(
      id: doc.id,
      kind: ActivityKind.values.asNameMap()[d['kind']] ?? ActivityKind.note,
      title: d['title'] as String? ?? '',
      subtitle: d['subtitle'] as String? ?? '',
      at: (d['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookingRef: d['bookingRef'] as String?,
      read: d['read'] as bool? ?? false,
    );
  }

  SalonActivity markRead() => SalonActivity(
    id: id,
    kind: kind,
    title: title,
    subtitle: subtitle,
    at: at,
    bookingRef: bookingRef,
    read: true,
  );
}

// ───────────────────────── Messages ─────────────────────────

/// A message from the salon to the customer about one booking.
class SalonMessage {
  final String id;
  final String bookingRef;
  final String text;
  final DateTime at;
  final bool readByCustomer;

  const SalonMessage({
    required this.id,
    required this.bookingRef,
    required this.text,
    required this.at,
    this.readByCustomer = false,
  });

  static SalonMessage fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return SalonMessage(
      id: doc.id,
      bookingRef: d['bookingRef'] as String? ?? '',
      text: d['text'] as String? ?? '',
      at: (d['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readByCustomer: d['readByCustomer'] as bool? ?? false,
    );
  }

  SalonMessage markRead() => SalonMessage(
    id: id,
    bookingRef: bookingRef,
    text: text,
    at: at,
    readByCustomer: true,
  );
}

// ───────────────────────── Store ─────────────────────────

class BookingStore {
  BookingStore._();
  static final BookingStore instance = BookingStore._();

  /// Listen to this to rebuild when bookings change.
  final ValueNotifier<List<Booking>> bookings = ValueNotifier<List<Booking>>(
    const [],
  );

  /// Manager's Alerts feed, newest first. Only filled for staff.
  final ValueNotifier<List<SalonActivity>> activity =
      ValueNotifier<List<SalonActivity>>(const []);

  /// Messages from the salon to customers, newest first.
  final ValueNotifier<List<SalonMessage>> messages =
      ValueNotifier<List<SalonMessage>>(const []);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _bookingsCol =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _activityCol =>
      _db.collection('activity');
  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _db.collection('messages');

  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<User?>? _authSub;
  int _session = 0; // ignores late results after a sign-out / user switch

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
  static String _when(Booking b) =>
      '${b.date.day} ${_months[b.date.month - 1]} · ${b.time}';

  // ── Connecting to Firestore ──

  /// Call once at startup (after Firebase.initializeApp). Follows sign-in /
  /// sign-out and listens to the right data for the user's role.
  void start() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );
  }

  Future<void> _onAuthChanged(User? user) async {
    final session = ++_session;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    bookings.value = const [];
    activity.value = const [];
    messages.value = const [];
    if (user == null) return;

    String? role;
    try {
      final profile = await _db.collection('users').doc(user.uid).get();
      role = profile.data()?['role'] as String?;
    } catch (e) {
      debugPrint('BookingStore: could not read role: $e');
    }
    if (session != _session) return; // signed out / switched user meanwhile

    final staff = role == 'manager' || role == 'worker';

    final bookingsQuery = staff
        ? _bookingsCol
        : _bookingsCol.where('customerUid', isEqualTo: user.uid);
    _subs.add(
      bookingsQuery.snapshots().listen(
        (snap) =>
            bookings.value = [for (final d in snap.docs) Booking.fromDoc(d)],
        onError: (Object e) =>
            debugPrint('BookingStore: bookings listener error: $e'),
      ),
    );

    final messagesQuery = staff
        ? _messagesCol
        : _messagesCol.where('customerUid', isEqualTo: user.uid);
    _subs.add(
      messagesQuery.snapshots().listen(
        (snap) => messages.value = [
          for (final d in snap.docs) SalonMessage.fromDoc(d),
        ]..sort((a, b) => b.at.compareTo(a.at)),
        onError: (Object e) =>
            debugPrint('BookingStore: messages listener error: $e'),
      ),
    );

    if (staff) {
      _subs.add(
        _activityCol
            .orderBy('at', descending: true)
            .limit(200)
            .snapshots()
            .listen(
              (snap) => activity.value = [
                for (final d in snap.docs) SalonActivity.fromDoc(d),
              ],
              onError: (Object e) =>
                  debugPrint('BookingStore: activity listener error: $e'),
            ),
      );
    }
  }

  /// Fire-and-forget Firestore write; failures are logged, and the listeners
  /// put the screen back to what the server really has.
  void _write(Future<void> op, String what) {
    op.catchError((Object e) => debugPrint('BookingStore: $what failed: $e'));
  }

  /// Replace one booking locally straight away, so the screen updates even
  /// before the Firestore listener fires.
  void _replaceLocal(String reference, Booking Function(Booking) change) {
    bookings.value = [
      for (final b in bookings.value)
        if (b.reference == reference) change(b) else b,
    ];
  }

  // ── Activity feed ──

  void log(
    ActivityKind kind,
    String title,
    String subtitle, {
    String? bookingRef,
    bool read = false,
  }) {
    _write(
      _activityCol.add({
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'at': Timestamp.now(),
        'bookingRef': bookingRef,
        'read': read,
      }),
      'log activity',
    );
  }

  void markAllRead() {
    final unread = activity.value.where((a) => !a.read).toList();
    if (unread.isEmpty) return;
    activity.value = [
      for (final a in activity.value) a.read ? a : a.markRead(),
    ];
    final batch = _db.batch();
    for (final a in unread) {
      batch.update(_activityCol.doc(a.id), {'read': true});
    }
    _write(batch.commit(), 'mark all read');
  }

  void markRead(String id) {
    if (!activity.value.any((a) => a.id == id && !a.read)) return;
    activity.value = [
      for (final a in activity.value) a.id == id && !a.read ? a.markRead() : a,
    ];
    _write(_activityCol.doc(id).update({'read': true}), 'mark read');
  }

  int get unreadCount => activity.value.where((a) => !a.read).length;

  // ── Bookings ──
  //
  // New bookings are created by the stripeWebhook Cloud Function after the
  // deposit is paid — see functions/index.js and PaymentScreen.

  Booking? find(String reference) {
    for (final b in bookings.value) {
      if (b.reference == reference) return b;
    }
    return null;
  }

  /// Load one booking straight from Firestore (e.g. right after payment,
  /// before the listener has delivered it).
  Future<Booking?> fetch(String reference) async {
    final doc = await _bookingsCol.doc(reference).get();
    return doc.exists ? Booking.fromDoc(doc) : null;
  }

  void _setStatus(String reference, BookingStatus status) {
    _replaceLocal(reference, (b) => b.copyWith(status: status));
    _write(
      _bookingsCol.doc(reference).update({'status': status.name}),
      'set status',
    );
  }

  // ── Customer actions ──

  /// Cancel a booking. [byManager] = the salon cancelled it.
  void cancel(String reference, {bool byManager = false}) {
    final b = find(reference);
    if (b == null) return;
    _setStatus(reference, BookingStatus.cancelled);
    log(
      ActivityKind.cancelled,
      'Booking canceled',
      '${b.customerName} · ${b.serviceName} · ${_when(b)}${byManager ? ' (by salon)' : ''}',
      bookingRef: reference,
      read: byManager,
    );
  }

  void reschedule(String reference, DateTime date, String time) {
    final old = find(reference);
    if (old == null) return;
    final moved = old.copyWith(date: date, time: time);
    _replaceLocal(reference, (_) => moved);
    _write(
      _bookingsCol.doc(reference).update({
        'date': Booking.dateKey(date),
        'time': time,
      }),
      'reschedule',
    );
    log(
      ActivityKind.rescheduled,
      'Booking moved',
      '${moved.customerName} · ${_when(old)} → ${_when(moved)}',
      bookingRef: reference,
    );
  }

  // ── Manager actions ──

  void accept(String reference) {
    final b = find(reference);
    if (b == null || !b.isPending) return;
    _setStatus(reference, BookingStatus.confirmed);
    _resolveRequest(reference);
    log(
      ActivityKind.accepted,
      'Booking accepted',
      '${b.customerName} · ${b.serviceName} · ${_when(b)}',
      bookingRef: reference,
      read: true,
    );
  }

  void decline(String reference) {
    final b = find(reference);
    if (b == null || !b.isPending) return;
    _setStatus(reference, BookingStatus.declined);
    _resolveRequest(reference);
    log(
      ActivityKind.declined,
      'Booking declined',
      '${b.customerName} · ${b.serviceName} · ${_when(b)}',
      bookingRef: reference,
      read: true,
    );
  }

  void _resolveRequest(String reference) {
    for (final a in activity.value) {
      if (a.kind == ActivityKind.request &&
          a.bookingRef == reference &&
          !a.read) {
        markRead(a.id);
      }
    }
  }

  // ── Messages ──

  /// Staff → customer message about [reference].
  void sendMessage(String reference, String text) {
    final b = find(reference);
    final t = text.trim();
    if (b == null || t.isEmpty) return;
    _write(
      _messagesCol.add({
        'bookingRef': reference,
        'customerUid': b.customerUid,
        'text': t,
        'at': Timestamp.now(),
        'readByCustomer': false,
      }),
      'send message',
    );
    log(
      ActivityKind.message,
      'Message sent to ${b.customerName}',
      t,
      bookingRef: reference,
      read: true,
    );
  }

  List<SalonMessage> messagesFor(String reference) =>
      messages.value.where((m) => m.bookingRef == reference).toList();

  int get unreadMessages =>
      messages.value.where((m) => !m.readByCustomer).length;

  /// Customer opened the booking — mark its messages as read.
  void markMessagesRead(String reference) {
    final unread = messages.value
        .where((m) => m.bookingRef == reference && !m.readByCustomer)
        .toList();
    if (unread.isEmpty) return;
    messages.value = [
      for (final m in messages.value)
        m.bookingRef == reference && !m.readByCustomer ? m.markRead() : m,
    ];
    final batch = _db.batch();
    for (final m in unread) {
      batch.update(_messagesCol.doc(m.id), {'readByCustomer': true});
    }
    _write(batch.commit(), 'mark messages read');
  }

  // ── Worker actions ──

  /// Worker finished the visit. Notifies the manager (unread alert).
  void markDone(String reference, {required String doneBy, String notes = ''}) {
    final b = find(reference);
    if (b == null || !b.isConfirmed || b.isDone) return;
    final now = DateTime.now();
    _replaceLocal(
      reference,
      (x) => x.copyWith(
        doneAt: now,
        doneBy: doneBy.trim(),
        doneNotes: notes.trim(),
      ),
    );
    _write(
      _bookingsCol.doc(reference).update({
        'doneAt': Timestamp.fromDate(now),
        'doneBy': doneBy.trim(),
        'doneNotes': notes.trim(),
      }),
      'mark done',
    );
    log(
      ActivityKind.completed,
      'Booking done',
      '${b.customerName} · ${b.serviceName} · done by ${doneBy.trim()}${notes.trim().isEmpty ? '' : '\n“${notes.trim()}”'}',
      bookingRef: reference,
    );
  }
}

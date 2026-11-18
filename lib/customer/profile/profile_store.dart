// lib/customer/profile/profile_store.dart
//
// The customer's profile, preferences and settings.
// Every profile screen reads and writes this one object.
//
// Saved in Firestore in the customer's own users/{uid} document, and the
// photo in Firebase Storage (see lib/data/session.dart).
//
// No card details are kept here — customers pay on Stripe's checkout page.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/session.dart';
import '../booking_store.dart';

class CustomerProfile extends ChangeNotifier with FirestoreProfile {
  CustomerProfile._() {
    bindToSession();
  }
  static final CustomerProfile instance = CustomerProfile._();

  /// Put a photo at this path to use it as the default profile picture.
  static const String defaultPhotoAsset = 'lib/assets/images/profile.jpg';

  // Edit profile
  String fullName = '';
  String preferredName = '';
  String about = '';
  Uint8List? photoBytes; // set by "Change photo"
  int memberSince = DateTime.now().year;

  // Personal details
  String email = '';
  String phone = '';
  DateTime? birthday;
  String gender = '';
  String address = '';

  // Beauty preferences
  String hairTexture = '';
  String hairLength = '';
  String hairGoals = '';
  String preferredStylist = '';
  String allergies = '';
  String stylistNotes = '';

  // Settings
  bool appointmentReminders = true;
  bool offersAndNews = false;
  bool rewardsUpdates = true;

  String get displayName =>
      preferredName.trim().isNotEmpty ? preferredName.trim() : fullName.trim();

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  // ── Firestore (users/{uid}) ──
  // update(change) comes from FirestoreProfile: applies, rebuilds, saves.

  @override
  Uint8List? get photo => photoBytes;
  @override
  set photo(Uint8List? bytes) => photoBytes = bytes;

  @override
  void resetFields() {
    fullName = '';
    preferredName = '';
    about = '';
    memberSince = DateTime.now().year;
    email = '';
    phone = '';
    birthday = null;
    gender = '';
    address = '';
    hairTexture = '';
    hairLength = '';
    hairGoals = '';
    preferredStylist = '';
    allergies = '';
    stylistNotes = '';
    appointmentReminders = true;
    offersAndNews = false;
    rewardsUpdates = true;
  }

  @override
  void applyData(SessionUser user) {
    final d = user.data;
    String str(String key) => d[key] as String? ?? '';
    bool flag(String key, bool fallback) => d[key] as bool? ?? fallback;

    fullName = str('name');
    preferredName = str('preferredName');
    about = str('about');
    email =
        d['email'] as String? ??
        user.email; // contact email (login email lives in Firebase Auth)
    phone = str('phone');
    birthday = (d['birthday'] as Timestamp?)?.toDate();
    gender = str('gender');
    address = str('address');
    hairTexture = str('hairTexture');
    hairLength = str('hairLength');
    hairGoals = str('hairGoals');
    preferredStylist = str('preferredStylist');
    allergies = str('allergies');
    stylistNotes = str('stylistNotes');
    appointmentReminders = flag('appointmentReminders', true);
    offersAndNews = flag('offersAndNews', false);
    rewardsUpdates = flag('rewardsUpdates', true);
    final created = (d['createdAt'] as Timestamp?)?.toDate();
    if (created != null) memberSince = created.year;
  }

  @override
  Map<String, dynamic> toData() => {
    'name': fullName.trim(),
    'preferredName': preferredName.trim(),
    'about': about.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'birthday': birthday == null ? null : Timestamp.fromDate(birthday!),
    'gender': gender,
    'address': address.trim(),
    'hairTexture': hairTexture,
    'hairLength': hairLength,
    'hairGoals': hairGoals.trim(),
    'preferredStylist': preferredStylist.trim(),
    'allergies': allergies.trim(),
    'stylistNotes': stylistNotes.trim(),
    'appointmentReminders': appointmentReminders,
    'offersAndNews': offersAndNews,
    'rewardsUpdates': rewardsUpdates,
  };
}

/// Reward points: 1 point per £1 of each completed (past) visit.
class Rewards {
  static const List<({int points, int discount, String note})> tiers = [
    (points: 500, discount: 10, note: 'A little extra self-care'),
    (points: 1000, discount: 20, note: 'More care, more to enjoy'),
  ];

  static int pointsFor(Booking b) => (b.servicePrice ?? b.depositPaid).round();

  static List<Booking> completedVisits() {
    final list =
        BookingStore.instance.bookings.value
            .where((b) => b.isCompleted)
            .toList()
          ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return list;
  }

  static int totalPoints() =>
      completedVisits().fold(0, (total, b) => total + pointsFor(b));

  /// Next tier the customer hasn't reached yet (or the top tier when all reached).
  static ({int points, int discount, String note}) nextTier(int points) =>
      tiers.firstWhere((t) => t.points > points, orElse: () => tiers.last);
}

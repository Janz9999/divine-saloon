// lib/data/session.dart
//
// Who is signed in, and their live `users/{uid}` document from Firestore.
//
// Profile stores (customer, manager, worker) mix in [FirestoreProfile] to
// load their fields from that document, save edits back to it, and keep the
// profile photo in Firebase Storage at `profilePhotos/{uid}`.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class SessionUser {
  final String uid;
  final String email;
  final String?
  role; // 'customer' | 'manager' | 'worker' (null until the doc exists)
  final Map<String, dynamic> data; // the users/{uid} document

  const SessionUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.data,
  });

  bool get isManager => role == 'manager';
  bool get isStaff => role == 'manager' || role == 'worker';
}

class Session {
  Session._();
  static final Session instance = Session._();

  /// null when signed out.
  final ValueNotifier<SessionUser?> user = ValueNotifier<SessionUser?>(null);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;

  /// Call once at startup, after Firebase.initializeApp.
  void start() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((authUser) {
      _docSub?.cancel();
      _docSub = null;
      user.value = null;
      if (authUser == null) return;
      _docSub = FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .snapshots()
          .listen(
            (snap) {
              final data = snap.data() ?? const <String, dynamic>{};
              user.value = SessionUser(
                uid: authUser.uid,
                email: authUser.email ?? '',
                role: data['role'] as String?,
                data: data,
              );
            },
            onError: (Object e) =>
                debugPrint('Session: users doc listener error: $e'),
          );
    });
  }

  DocumentReference<Map<String, dynamic>>? get userDoc {
    final u = user.value;
    return u == null
        ? null
        : FirebaseFirestore.instance.collection('users').doc(u.uid);
  }
}

/// Guess an image content type from its first bytes (Storage rules require image/*).
String imageContentType(Uint8List bytes) {
  if (bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50) {
    return 'image/png';
  }
  if (bytes.length > 12 && bytes[8] == 0x57 && bytes[9] == 0x45) {
    return 'image/webp';
  }
  if (bytes.length > 3 && bytes[0] == 0x47 && bytes[1] == 0x49) {
    return 'image/gif';
  }
  return 'image/jpeg';
}

/// Shared load / save logic for a profile stored in `users/{uid}`.
mixin FirestoreProfile on ChangeNotifier {
  /// Put every field back to its empty default (on sign-out / user switch).
  void resetFields();

  /// Copy fields from the users/{uid} document.
  void applyData(SessionUser user);

  /// The fields to save into users/{uid} (never include 'role').
  Map<String, dynamic> toData();

  Uint8List? get photo;
  set photo(Uint8List? bytes);

  String? _boundUid;
  int? _loadedPhotoVersion;
  Uint8List? _savedPhoto;

  /// Start following the signed-in user. Call once from the constructor.
  void bindToSession() {
    Session.instance.user.addListener(_onSessionChanged);
    _onSessionChanged(); // catch up if someone is already signed in
  }

  void _onSessionChanged() {
    final u = Session.instance.user.value;
    if (u?.uid != _boundUid) {
      _boundUid = u?.uid;
      _loadedPhotoVersion = null;
      _savedPhoto = null;
      resetFields();
      photo = null;
    }
    if (u != null) {
      applyData(u);
      _maybeLoadPhoto(u);
    }
    notifyListeners();
  }

  Future<void> _maybeLoadPhoto(SessionUser u) async {
    final version = (u.data['photoVersion'] as num?)?.toInt();
    if (version == null || version == _loadedPhotoVersion) return;
    _loadedPhotoVersion = version;
    try {
      final bytes = await FirebaseStorage.instance
          .ref('profilePhotos/${u.uid}')
          .getData(5 * 1024 * 1024);
      if (bytes != null && _boundUid == u.uid) {
        photo = bytes;
        _savedPhoto = bytes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Profile photo download failed: $e');
    }
  }

  /// Apply [change], rebuild listeners, then save to Firestore (and upload
  /// the photo if it changed).
  void update(VoidCallback change) {
    change();
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final doc = Session.instance.userDoc;
    final uid = _boundUid;
    if (doc == null || uid == null) return;
    try {
      final data = toData()..remove('role');
      final newPhoto = photo;
      if (newPhoto != null && !identical(newPhoto, _savedPhoto)) {
        await FirebaseStorage.instance
            .ref('profilePhotos/$uid')
            .putData(
              newPhoto,
              SettableMetadata(contentType: imageContentType(newPhoto)),
            );
        _savedPhoto = newPhoto;
        final version = DateTime.now().millisecondsSinceEpoch;
        _loadedPhotoVersion = version; // already have these bytes
        data['photoVersion'] = version;
      }
      await doc.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Profile save failed: $e');
    }
  }
}

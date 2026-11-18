// lib/customer/gallery_store.dart
//
// The salon's photo gallery. The manager uploads posts (Manager › Gallery);
// customers see them on the salon page (SalonDetailScreen) and can filter
// by category.
//
// Stored in Firestore (gallery/{id}); uploaded photos live in Firebase
// Storage at gallery/{id}. The salon's built-in photos are copied into
// Firestore once, the first time the manager signs in (meta/gallery.seeded).

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';

/// Categories shown as chips above the gallery (customer and manager).
const List<String> galleryCategories = [
  'AESTHETICS',
  'MASSAGE',
  'HAIR',
  'NAILS',
  'MAKEUP',
  'TANNING',
  'PIERCINGS',
  'TATTOOS',
];

class GalleryPost {
  final String id;
  final String? url; // built-in photos
  final Uint8List? bytes; // photo still uploading (shown from memory)
  final String? storagePath; // set for photos uploaded to Firebase Storage
  final String category;
  final String caption;
  final DateTime postedAt;

  const GalleryPost({
    required this.id,
    this.url,
    this.bytes,
    this.storagePath,
    required this.category,
    this.caption = '',
    required this.postedAt,
  });
}

class GalleryStore {
  GalleryStore._() {
    Session.instance.user.addListener(_onSessionChanged);
    _onSessionChanged(); // catch up if someone is already signed in
  }
  static final GalleryStore instance = GalleryStore._();

  static String _u(String id) =>
      'https://images.unsplash.com/photo-$id?q=80&w=600';

  /// The salon's existing photos, with a category each (seeded once).
  static const _seed = [
    ('1604654894610-df63bc536371', 'NAILS'),
    ('1562322140-8baeececf3df', 'AESTHETICS'),
    ('1534528741775-53994a69daeb', 'MAKEUP'),
    ('1522337360788-8b13dee7a37e', 'HAIR'),
    ('1517841905240-472988babdf9', 'MAKEUP'),
    ('1524504388940-b1c1722653e1', 'HAIR'),
    ('1540555700478-4be289fbecef', 'MASSAGE'),
    ('1580618672591-eb180b1a973f', 'HAIR'),
    ('1508214751196-bcfd4ca60f91', 'MAKEUP'),
    ('1519699047748-de8e457a634e', 'HAIR'),
    ('1527799820374-dcf8d9d4a388', 'MASSAGE'),
    ('1512290900673-700200843236', 'TATTOOS'),
    ('1596462502278-27bfdc403348', 'TATTOOS'),
    ('1522337094846-8a8383853713', 'HAIR'),
    ('1516975080664-ed2fc6a32937', 'AESTHETICS'),
    ('1560066984-138dadb4c035', 'HAIR'),
    ('1522337652631-d6cc2d856ad1', 'HAIR'),
    ('1588776814546-1ffcf47267a5', 'TATTOOS'),
  ];

  /// Newest first. Uploads in progress are shown at the top.
  final ValueNotifier<List<GalleryPost>> posts =
      ValueNotifier<List<GalleryPost>>(const []);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('gallery');

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _listeningFor;
  List<GalleryPost> _remote = const [];
  final List<GalleryPost> _uploading = [];
  bool _seedChecked = false;

  void _publish() => posts.value = [..._uploading, ..._remote];

  void _onSessionChanged() {
    final u = Session.instance.user.value;
    if (u?.uid == _listeningFor) return;
    _listeningFor = u?.uid;
    _sub?.cancel();
    _sub = null;
    _remote = const [];
    _seedChecked = false;
    _publish();
    if (u == null) return;

    _sub = _col.orderBy('postedAt', descending: true).snapshots().listen((
      snap,
    ) {
      _remote = [
        for (final d in snap.docs)
          GalleryPost(
            id: d.id,
            url: d.data()['url'] as String?,
            storagePath: d.data()['storagePath'] as String?,
            category: d.data()['category'] as String? ?? 'HAIR',
            caption: d.data()['caption'] as String? ?? '',
            postedAt:
                (d.data()['postedAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          ),
      ];
      _publish();
      if (snap.docs.isEmpty) _seedIfNeeded();
    }, onError: (Object e) => debugPrint('GalleryStore: listener error: $e'));
  }

  /// First manager sign-in: copy the built-in photos into Firestore once.
  Future<void> _seedIfNeeded() async {
    final u = Session.instance.user.value;
    if (_seedChecked || u == null || !u.isManager) return;
    _seedChecked = true;
    try {
      final metaRef = _db.collection('meta').doc('gallery');
      if ((await metaRef.get()).data()?['seeded'] == true) return;
      final batch = _db.batch();
      final start = DateTime.now().subtract(const Duration(days: 30));
      for (int i = 0; i < _seed.length; i++) {
        batch.set(_col.doc(), {
          'url': _u(_seed[i].$1),
          'storagePath': null,
          'category': _seed[i].$2,
          'caption': '',
          'postedAt': Timestamp.fromDate(start.subtract(Duration(days: i))),
        });
      }
      batch.set(metaRef, {'seeded': true});
      await batch.commit();
    } catch (e) {
      debugPrint('GalleryStore: seeding failed: $e');
    }
  }

  List<GalleryPost> filtered(String category) => category == 'ALL'
      ? posts.value
      : posts.value.where((p) => p.category == category).toList();

  GalleryPost? find(String id) {
    for (final p in posts.value) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Manager posts a photo: shown straight away, uploaded in the background.
  void add({
    required Uint8List bytes,
    required String category,
    String caption = '',
  }) {
    final doc = _col.doc();
    final pending = GalleryPost(
      id: doc.id,
      bytes: bytes,
      category: category,
      caption: caption.trim(),
      postedAt: DateTime.now(),
    );
    _uploading.insert(0, pending);
    _publish();
    _upload(doc, pending);
  }

  Future<void> _upload(
    DocumentReference<Map<String, dynamic>> doc,
    GalleryPost post,
  ) async {
    final path = 'gallery/${doc.id}';
    try {
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(
        post.bytes!,
        SettableMetadata(contentType: imageContentType(post.bytes!)),
      );
      final url = await ref.getDownloadURL();
      await doc.set({
        'url': url,
        'storagePath': path,
        'category': post.category,
        'caption': post.caption,
        'postedAt': Timestamp.fromDate(post.postedAt),
      });
    } catch (e) {
      debugPrint('GalleryStore: upload failed: $e');
    } finally {
      _uploading.removeWhere((p) => p.id == post.id);
      _publish();
    }
  }

  void remove(String id) {
    final post = find(id);
    _uploading.removeWhere((p) => p.id == id);
    _remote = _remote.where((p) => p.id != id).toList();
    _publish();
    _col
        .doc(id)
        .delete()
        .catchError(
          (Object e) => debugPrint('GalleryStore: delete failed: $e'),
        );
    final path = post?.storagePath;
    if (path != null) {
      FirebaseStorage.instance
          .ref(path)
          .delete()
          .catchError(
            (Object e) => debugPrint('GalleryStore: photo delete failed: $e'),
          );
    }
  }
}

/// Shows a gallery post's photo (uploaded bytes or a web image).
class GalleryImage extends StatelessWidget {
  final GalleryPost post;
  final BoxFit fit;
  const GalleryImage(this.post, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    Widget broken(BuildContext _, Object _, StackTrace? _) => const ColoredBox(
      color: Color(0xFFDBDBDB),
      child: Center(child: Icon(Icons.broken_image, color: Color(0xFF8E8E8E))),
    );
    if (post.bytes != null) {
      return Image.memory(post.bytes!, fit: fit, errorBuilder: broken);
    }
    return Image.network(post.url!, fit: fit, errorBuilder: broken);
  }
}

/// Full-screen photo with its category and caption.
/// Pass [onDelete] (manager only) to show a delete button.
class GalleryPhotoScreen extends StatelessWidget {
  final GalleryPost post;
  final VoidCallback? onDelete;
  const GalleryPhotoScreen({super.key, required this.post, this.onDelete});

  @override
  Widget build(BuildContext context) {
    const months = [
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
    final d = post.postedAt;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete photo',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete this photo?'),
                    content: const Text(
                      'Customers will no longer see it on the salon page.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  onDelete!();
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 4,
              child: Center(child: GalleryImage(post, fit: BoxFit.contain)),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${d.day} ${months[d.month - 1]} ${d.year}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/manager/manager_gallery_screen.dart
//
// Gallery tab: the manager uploads photos (with a category and caption).
// They appear straight away on the customer's salon page.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../customer/booking_store.dart';
import '../customer/gallery_store.dart';
import 'manager_ui.dart';

class ManagerGalleryScreen extends StatefulWidget {
  const ManagerGalleryScreen({super.key});

  @override
  State<ManagerGalleryScreen> createState() => _ManagerGalleryScreenState();
}

class _ManagerGalleryScreenState extends State<ManagerGalleryScreen> {
  String _category = 'ALL';

  Future<void> _upload() async {
    List<XFile> files;
    try {
      files = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) mSnack(context, 'Could not open your photos');
      return;
    }
    if (files.isEmpty || !mounted) return;
    final images = [for (final f in files) await f.readAsBytes()];
    if (!mounted) return;

    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PostSheet(
        images: images,
        initialCategory: _category == 'ALL' ? null : _category,
      ),
    );
    if (result == null) return;

    final (category, caption) = result;
    for (final bytes in images.reversed) {
      GalleryStore.instance.add(
        bytes: bytes,
        category: category,
        caption: caption,
      );
    }
    final n = images.length;
    BookingStore.instance.log(
      ActivityKind.note,
      n == 1 ? 'Photo posted' : '$n photos posted',
      '${category[0]}${category.substring(1).toLowerCase()} · now on your salon page',
      read: true,
    );
    if (mounted) {
      mSnack(
        context,
        n == 1 ? 'Photo posted — customers can see it now' : '$n photos posted',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<GalleryPost>>(
      valueListenable: GalleryStore.instance.posts,
      builder: (context, all, _) {
        final shown = GalleryStore.instance.filtered(_category);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Gallery', style: mTitle)),
                      MPrimaryButton(
                        'Upload',
                        icon: Icons.add_photo_alternate_outlined,
                        compact: true,
                        onPressed: _upload,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${all.length} photos · customers see these on your salon page.',
                    style: mSubtitle,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  children: [
                    for (final c in ['ALL', ...galleryCategories])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: MChipButton(
                          c == 'ALL'
                              ? 'All'
                              : '${c[0]}${c.substring(1).toLowerCase()}',
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (shown.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                sliver: SliverToBoxAdapter(
                  child: MCard(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'No photos in this category yet.',
                            style: TextStyle(
                              fontSize: 14.5,
                              color: MColors.muted,
                            ),
                          ),
                        ),
                        MLink('Upload', onTap: _upload),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                sliver: SliverGrid.builder(
                  itemCount: shown.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (context, i) {
                    final p = shown[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GalleryPhotoScreen(
                              post: p,
                              onDelete: () {
                                GalleryStore.instance.remove(p.id);
                                mSnack(context, 'Photo deleted');
                              },
                            ),
                          ),
                        ),
                        child: ColoredBox(
                          color: MColors.border,
                          child: GalleryImage(p),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Preview of the picked photos + category + caption. Returns (category, caption).
class _PostSheet extends StatefulWidget {
  final List<Uint8List> images;
  final String? initialCategory;
  const _PostSheet({required this.images, this.initialCategory});

  @override
  State<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<_PostSheet> {
  late String? _category = widget.initialCategory;
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.images.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n == 1 ? 'New post' : 'New post · $n photos', style: mSection),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: n,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    widget.images[i],
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 15,
                color: MColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in galleryCategories)
                  MChipButton(
                    '${c[0]}${c.substring(1).toLowerCase()}',
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            MField(
              label: 'Caption (optional)',
              controller: _caption,
              hint: 'e.g. Fresh balayage by Darlene',
              maxLines: 2,
            ),
            MPrimaryButton(
              _category == null ? 'Choose a category' : 'Post to salon page',
              onPressed: _category == null
                  ? null
                  : () => Navigator.pop(context, (_category!, _caption.text)),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Customers see new photos at the top of your salon page.',
                style: TextStyle(fontSize: 13, color: MColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

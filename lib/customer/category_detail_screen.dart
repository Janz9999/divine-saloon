// lib/customer/category_detail_screen.dart

import 'package:flutter/material.dart';

import 'salon_messages.dart' show MessageBadge;
import '../theme/app_colors.dart';
import 'customer_nav.dart';
import 'profile/profile_ui.dart' show openProfile;
import 'activity_screen.dart';

import 'service_catalog.dart';
import 'service_image.dart';
import 'treatment_booking_screen.dart';
import '../theme/app_text.dart';

/// Opens the right screen for a home-screen category:
/// one card  → straight to the price list / booking screen,
/// many cards → the category page with photo cards.
void openCategory(BuildContext context, String homeTitle) {
  final category = serviceCatalog[homeTitle.replaceAll('\n', ' ')];
  if (category == null) return;
  final cards = category['cards'] as List;

  final Widget screen;
  if (cards.length == 1) {
    final card = cards.first as Map<String, dynamic>;
    screen = TreatmentBookingScreen(
      card: card,
      fallbackImage: category['banner'] as String,
    );
  } else {
    screen = CategoryDetailScreen(category: category);
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class CategoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final cards = category['cards'] as List;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(context),
              const SizedBox(height: 28),
              _buildDescription(),
              const SizedBox(height: 24),
              for (final c in cards.cast<Map<String, dynamic>>())
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: _CategoryCard(
                    title: c['title'] as String,
                    imagePath: c['image'] as String,
                    fallbackImage: category['banner'] as String,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TreatmentBookingScreen(
                          card: c,
                          fallbackImage: category['banner'] as String,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Large banner photo with back button
  Widget _buildBanner(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ServiceImage(
            category['banner'] as String,
            height: 230,
            width: double.infinity,
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Title, description and bullet list
  Widget _buildDescription() {
    const bodyStyle = TextStyle(
      fontSize: 13.5,
      color: AppColors.text,
      height: 1.3,
    );
    final tagline = category['tagline'] as String?;
    final description = category['description'] as String?;
    final bullets =
        (category['bullets'] as List?)?.cast<String>() ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category['title'] as String,
            style: const TextStyle(
              fontFamily: AppFonts.heading,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          if (tagline != null) Text(tagline, style: bodyStyle),
          if (description != null) Text(description, style: bodyStyle),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text('•  $b', style: bodyStyle),
            ),
        ],
      ),
    );
  }

  // 3. Bottom navigation (search / home / saved / profile)
  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.search, color: AppColors.muted),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.black),
              onPressed: () => goCustomerHome(context),
            ),
            IconButton(
              icon: MessageBadge(
                child: Icon(Icons.bookmark_border, color: AppColors.muted),
              ),
              onPressed: () => openActivity(context),
            ),
            IconButton(
              icon: Icon(Icons.account_circle_outlined, color: AppColors.muted),
              onPressed: () => openProfile(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded pill-shaped photo card with a centred white title.
class _CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final String fallbackImage;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.imagePath,
    required this.fallbackImage,
    required this.onTap,
  });

  static const double _height = 110;
  static const double _radius = 36;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ServiceImage(imagePath, fallbackPath: fallbackImage),
              // Soft dark tint so the white title stays readable on any photo
              Container(color: Colors.black.withValues(alpha: 0.18)),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

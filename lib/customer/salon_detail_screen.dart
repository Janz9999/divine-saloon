import 'package:flutter/material.dart';

import 'salon_messages.dart' show MessageBadge;
import '../theme/app_colors.dart';
import 'customer_nav.dart';
import 'profile/profile_ui.dart' show openProfile;
import 'activity_screen.dart';
import 'gallery_store.dart';

class SalonDetailScreen extends StatefulWidget {
  const SalonDetailScreen({super.key});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  int selectedSpecialistIndex = 0;
  String selectedCategory = 'ALL';

  final List<String> categories = galleryCategories;

  final List<Map<String, String>> specialists = [
    {
      'name': 'Bessie',
      'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300',
      'about':
          'Bessie is best Hair Dresser in Our Saloon. He is Wonderful Person.',
    },
    {
      'name': 'Jane',
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300',
      'about': 'Jane is an expert in Skincare and Facial Treatments with over 6 years of experience.',
    },
    {
      'name': 'Gladys',
      'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=300',
      'about': 'Gladys specializes in Bridal Makeup, Hair Styling, and Premium Nail Art.',
    },
    {
      'name': 'Darlene',
      'image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=300',
      'about': 'Darlene is a Master Colorist and Hair Extensions Specialist.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedSpecialist = specialists[selectedSpecialistIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=800',
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Divine Aesthetics & Beauty',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Text(
                                'Charmaine ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                '(Owner)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '32 West St, Crewe CW1 3HA',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Text(
                                '4.9 ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.star_outline,
                                size: 18,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionButton(Icons.language, 'Website'),
                              _buildActionButton(Icons.phone_outlined, 'Call'),
                              _buildActionButton(
                                Icons.location_on_outlined,
                                'Direction',
                              ),
                              _buildActionButton(Icons.share_outlined, 'Share'),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Choose Specialist',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(specialists.length, (
                              index,
                            ) {
                              final specialist = specialists[index];
                              final isSelected =
                                  selectedSpecialistIndex == index;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSpecialistIndex = index;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(
                                          specialist['image']!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      specialist['name']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? Colors.black
                                            : AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'About ${selectedSpecialist['name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedSpecialist['about']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1, height: 1),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selectedCategory == category;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = isSelected
                                    ? 'ALL'
                                    : category;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Photos posted by the manager (Manager › Gallery).
                    ValueListenableBuilder<List<GalleryPost>>(
                      valueListenable: GalleryStore.instance.posts,
                      builder: (context, _, _) {
                        final shown = GalleryStore.instance.filtered(
                          selectedCategory,
                        );
                        if (shown.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No photos in this category yet.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: shown.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 3,
                                mainAxisSpacing: 3,
                                childAspectRatio: 1.0,
                              ),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    GalleryPhotoScreen(post: shown[index]),
                              ),
                            ),
                            child: ColoredBox(
                              color: AppColors.border,
                              child: GalleryImage(shown[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // UPDATED BOTTOM NAVIGATION BAR WITH WORKING HOME BUTTON
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Search Icon (Active on Salon Detail Screen)
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),

                  // Home Icon -> Navigates to CustomerHomeScreen
                  IconButton(
                    icon: const Icon(
                      Icons.home_outlined,
                      color: AppColors.muted,
                      size: 28,
                    ),
                    onPressed: () => goCustomerHome(context),
                  ),

                  // Bookmark Icon
                  IconButton(
                    icon: const MessageBadge(
                      child: Icon(
                        Icons.bookmark_border,
                        color: AppColors.muted,
                        size: 28,
                      ),
                    ),
                    onPressed: () => openActivity(context),
                  ),

                  // Profile Icon
                  IconButton(
                    icon: const Icon(
                      Icons.person_outline,
                      color: AppColors.muted,
                      size: 28,
                    ),
                    onPressed: () => openProfile(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

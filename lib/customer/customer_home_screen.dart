import 'package:flutter/material.dart';

import '../auth/log_out.dart';
import 'salon_messages.dart' show MessageBadge;
import '../theme/app_colors.dart';
import 'customer_nav.dart';
import 'profile/profile_ui.dart' show openProfile;
import 'activity_screen.dart';
import 'category_detail_screen.dart';
import 'profile/profile_store.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  final List<Map<String, String>> services = const [
    {'title': 'AESTHETICS', 'image': 'lib/assets/images/asa.jpg'},
    {
      'title': 'MASSAGE &\nHOLISTIC',
      'image': 'lib/assets/images/massage_holistic.jpg',
    },
    {
      'title': 'HAIR EXTENSIONS',
      'image': 'lib/assets/images/hair_extensions.jpg',
    },
    {'title': 'NAILS', 'image': 'lib/assets/images/nails.jpg'},
    {'title': 'BROWS & BEAUTY', 'image': 'lib/assets/images/brows_beauty.jpg'},
    {'title': 'TATTOOS', 'image': 'lib/assets/images/tattoos.jpg'},
    {'title': 'PIERCINGS', 'image': 'lib/assets/images/piercings.jpg'},
    {'title': 'TANNING', 'image': 'lib/assets/images/tanning.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListenableBuilder(
                              listenable: CustomerProfile.instance,
                              builder: (context, _) {
                                final name = CustomerProfile
                                    .instance
                                    .displayName
                                    .split(' ')
                                    .first;
                                return Text(
                                  name.isEmpty ? 'Hello,' : 'Hello $name,',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: AppColors.surface,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => confirmAndLogOut(context),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Tooltip(
                                    message: 'Log out',
                                    child: Icon(
                                      Icons.logout_rounded,
                                      color: Colors.black,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Discount Promotion Card
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Get Special\nDiscount\nUp to 40%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentSoft,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Book now',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            top: 0,
                            width: 170,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Services Header
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'More',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Services Grid Layout
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.35,
                          ),
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return GestureDetector(
                          onTap: () => openCategory(context, service['title']!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  service['image']!,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.1),
                                        Colors.black.withValues(alpha: 0.65),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                      service['title']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM NAVIGATION BAR
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: AppColors.muted,
                      size: 28,
                    ),
                    onPressed: () => goCustomerExplore(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.home_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
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
}

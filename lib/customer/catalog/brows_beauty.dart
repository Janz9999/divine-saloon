// lib/customer/catalog/brows_beauty.dart

const Map<String, dynamic> browsBeautyCategory = {
  'title': 'BROWS & BEAUTY',
  'banner':
      'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?q=80&w=800',
  'tagline': 'Defined, polished, effortless',
  'description':
      'From brows and lashes to semi-permanent make-up, waxing and '
      'teeth whitening — everyday beauty, done beautifully.',
  'bullets': [
    'Brow & Lash Lamination, Lifts and Tints',
    'Powder Brows, Microblading & Lip Blush',
    'Waxing',
    'Teeth Whitening',
  ],
  'cards': [
    // ── Brows & Lashes ──
    {
      'title': 'Brows & Lashes',
      'image': 'lib/assets/images/brows_lashes.jpg',
      'tagline': 'Frame your face',
      'description':
          'Shape, tint, lift and laminate — brow and lash treatments for '
          'fuller, defined brows and lifted lashes.',
      'highlights': [
        'Brow wax, tint & lamination',
        'Lash lift & tint, including Korean lash lift',
        'Combo packages available',
      ],
      'note': 'Some tint prices vary by artist (Charmaine / Paige).',
      'services': [
        {'name': 'Brow Wax', 'price': 15},
        {'name': 'Brow Tint (Charmaine)', 'price': 15},
        {'name': 'Brow Tint (Paige)', 'price': 16},
        {'name': 'Brow Wax & Tint', 'price': 18},
        {'name': 'Brow Lamination + Tint', 'price': 30},
        {'name': 'Lash Tint (Charmaine)', 'price': 18},
        {'name': 'Lash Tint (Paige)', 'price': 15},
        {'name': 'Lash Lift + Tint', 'price': 30},
        {'name': 'Korean Lash Lift + Tint', 'price': 28},
        {'name': 'Korean Lash Lift + Brow Wax & Tint', 'price': 45},
        {'name': 'Brow Lamination + Lash Lift & Tint', 'price': 45},
      ],
    },

    // ── SPMU ──
    {
      'title': 'SPMU (Semi Permanent Make Up)',
      'image': 'lib/assets/images/spmu.jpg',
      'tagline': 'Wake up ready',
      'description':
          'Semi-permanent make-up for brows and lips that saves you time every day, '
          'with top-ups and annual boosts to keep it looking fresh.',
      'highlights': [
        'Powder brows, microblading & lip blush',
        'Top-up 6–8 weeks after your first session',
        'Annual boosts to maintain colour',
      ],
      'services': [
        {'name': 'Powder Brows', 'price': 120},
        {'name': 'Microblading', 'price': 130},
        {'name': 'Lip Blush', 'price': 150},
        {'name': 'SPMU Top-Up 6–8 Weeks', 'price': 60},
        {'name': 'Powder Brow Touch-Up', 'price': 60},
        {'name': 'Microblading Touch-Up', 'price': 60},
        {'name': 'SPMU Annual Boost', 'price': 140},
        {'name': 'Microblading Annual Boost', 'price': 130},
        {'name': 'Lip Blush Annual Boost', 'price': 130},
      ],
    },

    // ── Waxing ──
    {
      'title': 'Waxing',
      'image': 'lib/assets/images/waxing.jpg',
      'tagline': 'Smooth, long-lasting results',
      'description':
          'Quick, professional waxing for face and body, from single areas '
          'to full body packages.',
      'highlights': [
        'Single areas from £15',
        'Facial & body wax packages',
        'Full body wax available',
      ],
      'services': [
        {'name': 'Underarm', 'price': 15},
        {'name': 'Bikini', 'price': 15},
        {'name': 'Full Arm', 'price': 15},
        {'name': 'Half Leg', 'price': 20},
        {'name': 'Full Leg', 'price': 30},
        {'name': 'Facial Wax Package', 'price': 25},
        {'name': 'Body Wax Package', 'price': 60},
        {'name': 'Full Body Wax', 'price': 90},
      ],
    },

    // ── Teeth Whitening ──
    {
      'title': 'Teeth Whitening',
      'image': 'lib/assets/images/teeth_whitening.jpg',
      'tagline': 'Brighter smile',
      'description': 'A quick, comfortable teeth whitening session for a brighter, fresher smile.',
      'highlights': ['Visible results in one session'],
      'services': [
        {'name': 'Teeth Whitening', 'price': 30},
      ],
    },
  ],
};

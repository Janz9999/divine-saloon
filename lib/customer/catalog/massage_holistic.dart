// lib/customer/catalog/massage_holistic.dart

const Map<String, dynamic> massageHolisticCategory = {
  'title': 'MASSAGE & HOLISTIC',
  'banner':
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?q=80&w=800',
  'tagline': 'Relax, restore and rebalance',
  'description':
      'Soothing massages and holistic therapies to ease tension, '
      'calm the mind and leave you feeling renewed.',
  'bullets': [
    'Full Body & Hot Stone Massage',
    'Japanese Head Spa',
    'Lymphatic Drainage',
    'Chakra, Sound & Colour Therapy',
  ],
  'cards': [
    // ── Massage ──
    {
      'title': 'Massage',
      'image': 'lib/assets/images/massage.jpg',
      'tagline': 'Melt away tension',
      'description':
          'From a quick back, neck & shoulder massage to a full Japanese head spa — '
          'choose the treatment and length that suits you.',
      'highlights': [
        '30, 40, 45, 60 and 90 minute options',
        'Hot stone, lymphatic drainage & cellulite massage',
        'Japanese head spa & scratch therapy',
      ],
      'services': [
        {'name': 'Full Body Massage – 60 min', 'price': 45},
        {'name': 'Full Body Massage – 90 min', 'price': 65},
        {'name': 'Back, Neck & Shoulder – 30 min', 'price': 25},
        {'name': 'Back, Neck & Shoulder – 60 min', 'price': 40},
        {'name': 'Indian Head Massage – 30 min', 'price': 35},
        {'name': 'Hot Stone Massage – 40 min', 'price': 45},
        {'name': 'Hot Stone Massage – 60 min', 'price': 65},
        {'name': 'Foot Massage – 30 min', 'price': 25},
        {'name': 'Foot Massage – 60 min', 'price': 40},
        {'name': 'Japanese Head Spa – 60 min', 'price': 60},
        {'name': 'Lymphatic Drainage Massage – 60 min', 'price': 45},
        {'name': 'Cellulite Massage – 60 min', 'price': 45},
        {'name': 'Scratch Therapy – 45 min', 'price': 40},
      ],
    },

    // ── Holistic Therapies ──
    {
      'title': 'Holistic Therapies',
      'image': 'lib/assets/images/holistic.jpg',
      'tagline': 'Balance for body and mind',
      'description':
          'Gentle holistic sessions to help you unwind, release stress and '
          'restore a sense of balance.',
      'highlights': [
        'Chakra rebalancing & unblocking',
        'Sound therapy',
        'Colour therapy',
        'All sessions 60 minutes',
      ],
      'services': [
        {'name': 'Chakra Rebalancing & Unblocking – 60 min', 'price': 50},
        {'name': 'Sound Therapy – 60 min', 'price': 45},
        {'name': 'Colour Therapy – 60 min', 'price': 45},
      ],
    },
  ],
};

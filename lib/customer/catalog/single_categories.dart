// lib/customer/catalog/single_categories.dart
//
// Categories with just one card — the home tile opens the card page directly.

const Map<String, dynamic> hairExtensionsCategory = {
  'title': 'HAIR EXTENSIONS',
  'banner':
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=800',
  'cards': [
    {
      'title': 'Hair Extensions',
      'image': 'lib/assets/images/hair_extensions.jpg',
      'tagline': 'Length, volume, confidence',
      'description':
          'Add length and volume with tapes, nanos, micros or weave — '
          'blended to match your natural hair.',
      'highlights': [
        'Tapes, nanos, micros & weave',
        'Priced per pack',
        'Colour matched to your hair',
      ],
      'note': 'Prices are per pack — the number of packs depends on the look you want.',
      'services': [
        {'name': 'Tapes (per pack)', 'price': 35},
        {'name': 'Nanos (per pack)', 'price': 50},
        {'name': 'Micros (per pack)', 'price': 50},
        {'name': 'Weave (per pack)', 'price': 60},
      ],
    },
  ],
};

const Map<String, dynamic> nailsCategory = {
  'title': 'NAILS',
  'banner':
      'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=800',
  'cards': [
    {
      'title': 'Nails',
      'image': 'lib/assets/images/nails.jpg',
      'tagline': 'Polished from fingers to toes',
      'description':
          'Gel polish, BIAB and acrylics for hands and toes — long-lasting, '
          'glossy and finished with care.',
      'highlights': [
        'Gel polish, BIAB & acrylic',
        'Gel toes or nails & toes combo',
        'Model price on plain acrylics',
      ],
      'services': [
        {'name': 'Plain Acrylic Nails (Model Price)', 'price': 25},
        {'name': 'Gel Polish', 'price': 28},
        {'name': 'Gel Toes', 'price': 28},
        {'name': 'BIAB', 'price': 30},
        {'name': 'Acrylic', 'price': 30},
        {'name': 'Gel Nails and Toes', 'price': 50},
      ],
    },
  ],
};

const Map<String, dynamic> tattoosCategory = {
  'title': 'TATTOOS',
  'banner':
      'https://images.unsplash.com/photo-1596462502278-27bfdc403348?q=80&w=800',
  'cards': [
    {
      'title': 'Tattoos',
      'image': 'lib/assets/images/tattoos.jpg',
      'tagline': 'Your idea, our artistry',
      'description':
          'Every tattoo is unique. Book a consultation to talk through your design, '
          'size and placement, and get a personal quote.',
      'highlights': ['Custom designs', 'Quote given at consultation'],
      'services': [
        {'name': 'Tattoo Consultation', 'price': null},
      ],
    },
  ],
};

const Map<String, dynamic> piercingsCategory = {
  'title': 'PIERCINGS',
  'banner':
      'https://images.unsplash.com/photo-1535295972055-1c762f4483e5?q=80&w=800',
  'cards': [
    {
      'title': 'Piercings',
      'image': 'lib/assets/images/piercings.jpg',
      'tagline': 'Safe, clean, precise',
      'description':
          'Ear, face and body piercings carried out hygienically, with aftercare '
          'advice to help you heal well.',
      'highlights': [
        'Ear: daith, conch, helix, industrial',
        'Face: septum, labret, Madonna, Monroe, snake bites',
        'Body: navel & nipple',
      ],
      'services': [
        {'name': 'Septum', 'price': 15},
        {'name': 'Daith', 'price': 25},
        {'name': 'Conch', 'price': 25},
        {'name': 'Helix', 'price': 25},
        {'name': 'Labret', 'price': 25},
        {'name': 'Madonna', 'price': 25},
        {'name': 'Monroe', 'price': 25},
        {'name': 'Navel / Belly Button', 'price': 25},
        {'name': 'Industrial', 'price': 30},
        {'name': 'Nipple', 'price': 30},
        {'name': 'Snake Bites', 'price': 40},
      ],
    },
  ],
};

const Map<String, dynamic> tanningCategory = {
  'title': 'SUNBEDS & TANNING',
  'banner':
      'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?q=80&w=800',
  'cards': [
    {
      'title': 'Sunbeds & Tanning',
      'image': 'lib/assets/images/tanning.jpg',
      'tagline': 'Sun-kissed, all year round',
      'description': 'An even, natural-looking spray tan for a healthy glow — no sun needed.',
      'highlights': ['Even, streak-free finish'],
      'services': [
        {'name': 'Spray Tan', 'price': 28},
      ],
    },
  ],
};

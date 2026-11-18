// lib/customer/catalog/aesthetics.dart
//
// Card fields:
//   title, image, tagline, description, highlights (bullets), note (optional),
//   services: [ {name, price} ]   — price: null shows "POA" (price on application)

const Map<String, dynamic> aestheticsCategory = {
  'title': 'AESTHETICS',
  'banner': 'lib/assets/images/asa.jpg',
  'tagline': 'Subtle enhancements, naturally beautiful',
  'description':
      'Skilled, gentle treatments designed to refine and rejuvenate. '
      'From dermal fillers to advanced skin therapies — every procedure '
      'is delivered with precision and care.',
  'bullets': [
    'Lip Filler (0.5ml / 1ml)',
    'Cheek & Jawline Filler',
    'Anti-Wrinkle Treatments',
    'Microneedling',
    'Skin Boosters',
  ],
  'cards': [
    // ── Anti-Wrinkle ──
    {
      'title': 'Anti-Wrinkle',
      'image': 'lib/assets/images/anti_wrinkle.jpg',
      'tagline': 'Soften lines, keep your expression',
      'description':
          'Anti-wrinkle injections relax the muscles that cause expression lines, '
          'smoothing the forehead, frown lines and crow’s feet for a fresher, '
          'well-rested look.',
      'highlights': [
        'Prescriber consultation before your first treatment',
        'Quick appointment with minimal downtime',
        'Results develop over 1–2 weeks',
      ],
      'note': 'A prescriber consultation is required before treatment.',
      'services': [
        {'name': 'Prescriber Consultation', 'price': 30},
        {'name': '1 Area', 'price': 120},
        {'name': '2 Areas', 'price': 170},
        {'name': '3 Areas', 'price': 195},
        {'name': 'Lip Flip', 'price': 100},
        {'name': 'Gummy Smile', 'price': 100},
        {'name': 'Bunny Lines', 'price': 100},
        {'name': 'Cobbled Chin', 'price': 100},
        {'name': 'Brow Lift / Dropped Brow', 'price': 100},
        {'name': 'Nasal Flare', 'price': 100},
        {'name': 'Masseter', 'price': 200},
        {'name': 'Excessive Underarm Sweating', 'price': 250},
      ],
    },

    // ── Dermal Fillers ──
    {
      'title': 'Dermal Fillers',
      'image': 'lib/assets/images/dermal_fillers.jpg',
      'tagline': 'Restore volume, enhance shape',
      'description':
          'Dermal fillers add natural-looking volume and definition to the lips, '
          'cheeks and jawline, tailored to balance your features.',
      'highlights': [
        'Lip filler in 0.5ml or 1ml',
        'Non-surgical rhinoplasty',
        'Cheek, chin & jawline contouring',
        'Nasolabial line filler',
      ],
      'note': 'Cheek, chin and jawline filler are priced per ml.',
      'services': [
        {'name': 'Lip Filler 0.5ml', 'price': 90},
        {'name': 'Lip Filler 1ml', 'price': 110},
        {'name': 'Non-Surgical Rhinoplasty', 'price': 160},
        {'name': 'Cheek Filler (per ml)', 'price': 170},
        {'name': 'Chin Filler (per ml)', 'price': 170},
        {'name': 'Jawline Filler (per ml)', 'price': 170},
        {'name': 'Nasolabial Line Filler', 'price': 200},
      ],
    },

    // ── Skin Boosters & Advanced Skin ──
    {
      'title': 'Skin Boosters & Advanced Skin',
      'image': 'lib/assets/images/skin_boosters.jpg',
      'tagline': 'Hydrated, glowing, renewed skin',
      'description':
          'Advanced skin treatments that boost hydration and stimulate collagen '
          'to improve texture, tone and radiance.',
      'highlights': [
        'Skin boosters for deep hydration',
        'Microneedling to refine texture',
        'Suitable for most skin types',
      ],
      'services': [
        {'name': 'Lumi Eyes', 'price': 100},
        {'name': 'Elaxen PN Skin Rejuvenation', 'price': 80},
        {'name': 'Vitaran Skin Booster', 'price': 150},
        {'name': 'Eye Boosters', 'price': 150},
        {'name': 'Neck Boosters', 'price': 200},
        {'name': 'Profhilo', 'price': 120},
        {'name': 'Profhilo Course of 3', 'price': 350},
        {'name': 'Jalupro Classic', 'price': 160},
        {'name': 'Jalupro Course of 3', 'price': 400},
        {'name': 'Sunekos', 'price': 150},
        {'name': 'PRP Vampire Facial', 'price': 150},
        {'name': 'PRP Hair Loss Treatment', 'price': 150},
        {'name': 'Microneedling Course of 3', 'price': 200},
        {'name': 'Microdermabrasion Facial', 'price': 35},
      ],
    },

    // ── Fat Dissolving ──
    {
      'title': 'Fat Dissolving',
      'image': 'lib/assets/images/fat_dissolving.jpg',
      'tagline': 'Target stubborn areas',
      'description':
          'Injectable fat-dissolving treatment designed to reduce small, stubborn '
          'pockets of fat that don’t respond to diet and exercise.',
      'highlights': [
        'Non-surgical treatment',
        'Consultation to assess suitable areas',
      ],
      'services': [
        {'name': 'Chin', 'price': 90},
        {'name': 'Abdomen / Arms', 'price': 160},
        {'name': 'Thighs', 'price': 180},
      ],
    },

    // ── Facials ──
    {
      'title': 'Facials',
      'image': 'lib/assets/images/facials.jpg',
      'tagline': 'Cleanse, refresh, glow',
      'description':
          'Professional facials tailored to your skin to cleanse, nourish and '
          'leave your complexion bright and refreshed.',
      'highlights': [
        'Tailored to your skin type',
        'Relaxing, results-focused treatment',
      ],
      'services': [
        {'name': 'Dermaplaning Facial', 'price': 30},
        {'name': 'EMS Facial', 'price': 35},
        {'name': 'Signature Facial', 'price': 35},
        {'name': 'BB Glow Facial', 'price': 50},
        {'name': 'Cellular Glow Peel', 'price': 50},
        {'name': 'Microneedling', 'price': 80},
        {'name': "Children's Facial", 'price': 25},
      ],
    },

    // ── Other Aesthetics ──
    {
      'title': 'Other Aesthetics',
      'image': 'lib/assets/images/other_aesthetics.jpg',
      'tagline': 'Something else in mind?',
      'description':
          'Looking for a treatment not listed here? Book a consultation and we’ll '
          'talk through the options that suit you best.',
      'highlights': [
        'One-to-one consultation',
        'Honest advice and a personalised plan',
      ],
      'services': [
        {'name': 'Teeth Whitening', 'price': 30},
        {'name': 'Spray Tan', 'price': 28},
        {'name': 'IM Injection Appointment', 'price': 30},
      ],
    },
  ],
};

// lib/customer/service_catalog.dart
//
// Maps each home-screen tile title (line breaks → spaces) to its category data.
// The details and prices for each category live in lib/customer/catalog/.
//
// Card images: add photos to lib/assets/images/ with the names used in the
// catalog files. Until then the category's banner photo is shown instead.

import 'catalog/aesthetics.dart';
import 'catalog/brows_beauty.dart';
import 'catalog/massage_holistic.dart';
import 'catalog/single_categories.dart';

const Map<String, Map<String, dynamic>> serviceCatalog = {
  'AESTHETICS': aestheticsCategory,
  'MASSAGE & HOLISTIC': massageHolisticCategory,
  'HAIR EXTENSIONS': hairExtensionsCategory,
  'NAILS': nailsCategory,
  'BROWS & BEAUTY': browsBeautyCategory,
  'TATTOOS': tattoosCategory,
  'PIERCINGS': piercingsCategory,
  'TANNING': tanningCategory,
};

class CropConstants {
  CropConstants._();

  static const List<String> allCrops = [
    'maize', 'rice', 'sorghum', 'millet',
    'groundnut', 'cowpea', 'soybean',
    'cassava', 'yam', 'sweet_potato', 'ginger',
    'tomato', 'pepper', 'okra', 'onion', 'watermelon',
    'cocoa', 'oil_palm', 'plantain', 'sesame',
  ];

  static const Map<String, String> cropDisplayNames = {
    'maize': 'Maize',
    'rice': 'Rice',
    'sorghum': 'Sorghum',
    'millet': 'Millet',
    'groundnut': 'Groundnut',
    'cowpea': 'Cowpea',
    'soybean': 'Soybean',
    'cassava': 'Cassava',
    'yam': 'Yam',
    'sweet_potato': 'Sweet Potato',
    'ginger': 'Ginger',
    'tomato': 'Tomato',
    'pepper': 'Pepper',
    'okra': 'Okra',
    'onion': 'Onion',
    'watermelon': 'Watermelon',
    'cocoa': 'Cocoa',
    'oil_palm': 'Oil Palm',
    'plantain': 'Plantain',
    'sesame': 'Sesame',
  };

  static const Map<String, String> cropEmojis = {
    'maize': '🌽',
    'rice': '🍚',
    'sorghum': '🌾',
    'millet': '🌾',
    'groundnut': '🥜',
    'cowpea': '🫘',
    'soybean': '🫘',
    'cassava': '🥔',
    'yam': '🥔',
    'sweet_potato': '🍠',
    'ginger': '🫚',
    'tomato': '🍅',
    'pepper': '🌶️',
    'okra': '🫑',
    'onion': '🧅',
    'watermelon': '🍉',
    'cocoa': '🍫',
    'oil_palm': '🌴',
    'plantain': '🍌',
    'sesame': '🫘',
  };

  static const Map<String, List<String>> cropCategories = {
    'grains': ['maize', 'rice', 'sorghum', 'millet'],
    'legumes': ['groundnut', 'cowpea', 'soybean'],
    'tubers_roots': ['cassava', 'yam', 'sweet_potato', 'ginger'],
    'vegetables': ['tomato', 'pepper', 'okra', 'onion', 'watermelon'],
    'cash_tree': ['cocoa', 'oil_palm', 'plantain', 'sesame'],
  };

  static const Map<String, String> categoryLabels = {
    'grains': 'Grains',
    'legumes': 'Legumes',
    'tubers_roots': 'Tubers & Roots',
    'vegetables': 'Vegetables',
    'cash_tree': 'Cash & Tree Crops',
  };

  static const Map<String, String> categoryIcons = {
    'grains': '🌾',
    'legumes': '🫘',
    'tubers_roots': '🥔',
    'vegetables': '🥬',
    'cash_tree': '🌴',
  };
}

class SoilConstants {
  SoilConstants._();

  static const Map<String, Map<String, double>> thresholds = {
    'maize': {'critical': 0.15, 'low': 0.20},
    'cassava': {'critical': 0.10, 'low': 0.15},
    'tomato': {'critical': 0.18, 'low': 0.23},
    'rice': {'critical': 0.30, 'low': 0.35},
    'yam': {'critical': 0.12, 'low': 0.18},
    'pepper': {'critical': 0.18, 'low': 0.23},
    'okra': {'critical': 0.12, 'low': 0.17},
    'onion': {'critical': 0.20, 'low': 0.25},
    'watermelon': {'critical': 0.15, 'low': 0.20},
    'sorghum': {'critical': 0.10, 'low': 0.15},
    'millet': {'critical': 0.08, 'low': 0.13},
    'groundnut': {'critical': 0.10, 'low': 0.15},
    'cowpea': {'critical': 0.10, 'low': 0.15},
    'soybean': {'critical': 0.15, 'low': 0.20},
    'sweet_potato': {'critical': 0.10, 'low': 0.15},
    'ginger': {'critical': 0.15, 'low': 0.20},
    'cocoa': {'critical': 0.18, 'low': 0.23},
    'oil_palm': {'critical': 0.18, 'low': 0.23},
    'plantain': {'critical': 0.18, 'low': 0.23},
    'sesame': {'critical': 0.10, 'low': 0.15},
  };
}

class PestConstants {
  PestConstants._();

  static const List<String> pests = [
    'fall_armyworm', 'desert_locust', 'stem_borer',
    'tuta_absoluta', 'aphids', 'whitefly',
    'cassava_mosaic', 'cassava_green_mite',
    'yam_beetle', 'blight', 'leaf_spot',
    'nematodes', 'mite', 'thrips',
    'mirids', 'black_pod', 'wilt',
  ];

  static const Map<String, String> pestNames = {
    'fall_armyworm': 'Fall Armyworm',
    'desert_locust': 'Desert Locust',
    'stem_borer': 'Stem Borer',
    'tuta_absoluta': 'Tuta Absoluta',
    'aphids': 'Aphids',
    'whitefly': 'Whitefly',
    'cassava_mosaic': 'Cassava Mosaic Virus',
    'cassava_green_mite': 'Cassava Green Mite',
    'yam_beetle': 'Yam Beetle',
    'blight': 'Blight',
    'leaf_spot': 'Leaf Spot',
    'nematodes': 'Nematodes',
    'mite': 'Mite',
    'thrips': 'Thrips',
    'mirids': 'Mirids',
    'black_pod': 'Black Pod Disease',
    'wilt': 'Wilt Disease',
  };

  static const Map<String, List<String>> cropPests = {
    'maize': ['fall_armyworm', 'stem_borer', 'aphids'],
    'rice': ['stem_borer', 'blight', 'leaf_spot'],
    'sorghum': ['fall_armyworm', 'stem_borer', 'aphids'],
    'millet': ['fall_armyworm', 'stem_borer', 'blight'],
    'groundnut': ['leaf_spot', 'blight', 'aphids'],
    'cowpea': ['aphids', 'thrips', 'blight'],
    'soybean': ['leaf_spot', 'nematodes', 'aphids'],
    'cassava': ['cassava_mosaic', 'cassava_green_mite', 'whitefly'],
    'yam': ['yam_beetle', 'blight', 'nematodes'],
    'sweet_potato': ['blight', 'nematodes', 'weevil'],
    'ginger': ['blight', 'nematodes', 'wilt'],
    'tomato': ['tuta_absoluta', 'blight', 'whitefly'],
    'pepper': ['thrips', 'mite', 'blight'],
    'okra': ['aphids', 'mite', 'blight'],
    'onion': ['thrips', 'blight', 'wilt'],
    'watermelon': ['blight', 'aphids', 'wilt'],
    'cocoa': ['mirids', 'black_pod', 'wilt'],
    'oil_palm': ['leaf_spot', 'wilt', 'nematodes'],
    'plantain': ['wilt', 'nematodes', 'black_pod'],
    'sesame': ['leaf_spot', 'wilt', 'aphids'],
  };
}

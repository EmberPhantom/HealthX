// lib/screens/ready_to_eat_screen.dart
// ✅ 13 Real products — 5 FitSport + 8 Nutritius
// ✅ Real asset images (3 per product for carousel)
// ✅ Fully connected to AppProvider cart
// ✅ Tap → BigBasket-style ProductDetailScreen with image carousel
// ✅ Add/Stepper on card, View Cart FAB
// ✅ Category filter: All, Energy Bars, Protein Bars, Chikki
// ✅ Search by name or description

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

const double _rteRefW = 360.0;
const double _rteRefH = 800.0;

// ─── Category ─────────────────────────────────────────────────────────────────

class _RteCat {
  final String label;
  final String emoji;
  const _RteCat(this.label, this.emoji);
}

const _rteCats = [
  _RteCat('All', '🍽️'),
  _RteCat('Energy Bars', '⚡'),
  _RteCat('Protein Bars', '💪'),
  _RteCat('Chikki', '🍬'),
];

// ─── Extra metadata per product ───────────────────────────────────────────────

class RteMeta {
  final String weight;
  final double? originalPrice;
  final bool isBestseller;
  final bool isNew;
  final String aboutProduct;
  final Map<String, String> otherInfo;
  final List<String> imageUrls; // For carousel in detail screen

  const RteMeta({
    required this.weight,
    this.originalPrice,
    this.isBestseller = false,
    this.isNew = false,
    required this.aboutProduct,
    required this.otherInfo,
    required this.imageUrls,
  });
}

// ─── Product List (MenuItem) ──────────────────────────────────────────────────

final rteMenuItems = <MenuItem>[

  // ══════════════════════════════════════════════════════
  //  FITSPORT — 5 Products
  // ══════════════════════════════════════════════════════

  MenuItem(
    id: 'fs1',
    name: 'Happy Natural Energy Bar',
    description: 'Almonds, Pistachios, Seeds & Jaggery — 80%+ dry fruits.',
    price: 300,
    calories: 180,
    rating: 4.6,
    reviewCount: 342,
    imageUrl: 'assets/images/energy_bar_1.png',
    emoji: '⚡',
    category: 'Energy Bars',
    tags: ['No Added Sugar', 'Vegan', 'Gluten Free'],
    isVeg: true,
  ),

  MenuItem(
    id: 'fs2',
    name: 'Happy Jamun Nutrition Bar',
    description: 'Black Jamun, Oats, Almonds, Seeds — natural superfood bar.',
    price: 360,
    calories: 165,
    rating: 4.5,
    reviewCount: 218,
    imageUrl: 'assets/images/jasmun_1.png',
    emoji: '🫐',
    category: 'Energy Bars',
    tags: ['Superfood', 'Antioxidants', 'No Preservatives'],
    isVeg: true,
  ),

  MenuItem(
    id: 'fs3',
    name: 'Happy Coco Bar',
    description: 'Desiccated Coconut, Dry Fruits, Nuts & Seeds with Jaggery.',
    price: 300,
    calories: 190,
    rating: 4.4,
    reviewCount: 156,
    imageUrl: 'assets/images/coco_bar_1.png',
    emoji: '🥥',
    category: 'Energy Bars',
    tags: ['Coconut Flavour', 'Natural', 'Vegan'],
    isVeg: true,
  ),

  MenuItem(
    id: 'fs4',
    name: 'Happy Sport 12g Protein Bar',
    description: 'Whey Protein, Peanut Butter, Dark Choco Chips & Rice Crisps.',
    price: 570,
    calories: 250,
    rating: 4.7,
    reviewCount: 487,
    imageUrl: 'assets/images/12gm_protienbar_1.png',
    emoji: '🍫',
    category: 'Protein Bars',
    tags: ['12g Protein', 'Post Workout', 'Shark Tank'],
    isVeg: true,
  ),

  MenuItem(
    id: 'fs5',
    name: 'FitSport 20g Protein Bar',
    description: 'High Whey Protein, Peanut Butter, Dark Choco Chips, Almonds.',
    price: 570,
    calories: 290,
    rating: 4.8,
    reviewCount: 621,
    imageUrl: 'assets/images/20gm_protienbar_1.png',
    emoji: '💪',
    category: 'Protein Bars',
    tags: ['20g Protein', 'Muscle Recovery', 'Bestseller'],
    isVeg: true,
  ),

  // ══════════════════════════════════════════════════════
  //  NUTRITIUS — 8 Products
  // ══════════════════════════════════════════════════════

  MenuItem(
    id: 'nu1',
    name: 'Dry Fruit Chikki',
    description: 'Premium dry fruits with jaggery — traditional Indian energy snack.',
    price: 960,
    calories: 420,
    rating: 4.7,
    reviewCount: 295,
    imageUrl: 'assets/images/dry_fruit_chikki_1.png',
    emoji: '🍬',
    category: 'Chikki',
    tags: ['Premium', 'Jaggery', 'No Preservatives'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu2',
    name: 'Peanut Butter Chikki',
    description: 'Soft peanut butter chikki that melts in your mouth. Dairy free.',
    price: 480,
    calories: 380,
    rating: 4.5,
    reviewCount: 203,
    imageUrl: 'assets/images/peanut_butter_chikki_1.png',
    emoji: '🥜',
    category: 'Chikki',
    tags: ['Dairy Free', 'Vegan', 'Gluten Free'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu3',
    name: 'Almond Butter Chikki',
    description: 'Rich almond butter flavour chikki — soft, crunchy and delicious.',
    price: 480,
    calories: 395,
    rating: 4.6,
    reviewCount: 178,
    imageUrl: 'assets/images/almond_butter_chikki_1.png',
    emoji: '🍪',
    category: 'Chikki',
    tags: ['Almond Rich', 'Soft Bite', 'No Additives'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu4',
    name: 'Cashew Peanut Butter Chikki',
    description: 'Cashew & peanut butter blend chikki — creamy meets crunchy.',
    price: 480,
    calories: 410,
    rating: 4.4,
    reviewCount: 142,
    imageUrl: 'assets/images/cashew_peanut_butter_chikki_1.png',
    emoji: '🌰',
    category: 'Chikki',
    tags: ['Cashew + Peanut', 'No Dairy', 'Vegan'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu5',
    name: 'Hazelnut Butter Chikki',
    description: 'Hazelnut chocolate spread chikki — irresistible and unique.',
    price: 480,
    calories: 400,
    rating: 4.7,
    reviewCount: 261,
    imageUrl: 'assets/images/hazelnut_butter_chikki_1.png',
    emoji: '🍫',
    category: 'Chikki',
    tags: ['Hazelnut', 'Chocolate', 'Bestseller'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu6',
    name: 'Crunchy Peanut Chikki',
    description: 'Classic roasted peanut chikki with jaggery — crisp and fresh.',
    price: 240,
    calories: 360,
    rating: 4.3,
    reviewCount: 189,
    imageUrl: 'assets/images/crunchy_chikki_1.png',
    emoji: '🥜',
    category: 'Chikki',
    tags: ['Classic', 'Crunchy', 'Best Value'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu7',
    name: 'Rajgira Peanut Chikki',
    description: 'Rajgira (Amaranth) + Peanuts in jaggery — high protein & iron.',
    price: 300,
    calories: 355,
    rating: 4.5,
    reviewCount: 134,
    imageUrl: 'assets/images/ragira_peanut_chikki_1.png',
    emoji: '🌾',
    category: 'Chikki',
    tags: ['High Protein', 'Iron Rich', 'Rajgira'],
    isVeg: true,
  ),

  MenuItem(
    id: 'nu8',
    name: 'Sesame Crunch Chikki',
    description: 'Sesame seeds + jaggery chikki — calcium rich, light & crunchy.',
    price: 300,
    calories: 340,
    rating: 4.4,
    reviewCount: 117,
    imageUrl: 'assets/images/sesame_chikki_1.png',
    emoji: '🌱',
    category: 'Chikki',
    tags: ['Calcium Rich', 'Sesame', 'Light Snack'],
    isVeg: true,
  ),
];

// ─── Meta Map ─────────────────────────────────────────────────────────────────

final rteMeta = <String, RteMeta>{

  // ── FitSport ──────────────────────────────────────────────────────────────

  'fs1': const RteMeta(
    weight: '30g × 6 Pack',
    originalPrice: 360,
    isBestseller: true,
    imageUrls: [
      'assets/images/energy_bar_1.png',
      'assets/images/energy_bar_2.png',
      'assets/images/energy_bar_3.png',
    ],
    aboutProduct:
    'Happy Natural Energy Bar is crafted with 80%+ premium dry fruits, nuts '
        'and seeds. Made with almonds, pistachios, sunflower seeds, pumpkin seeds, '
        'dates and pure cow ghee — zero added sugar, zero preservatives. '
        'A wholesome snack for your morning routine, gym session or on-the-go energy boost. '
        'As seen on Shark Tank India and awarded Best Energy Bar of the Year.',
    otherInfo: {
      'Brand': 'FitSport Nutrition',
      'Net Weight': '30g per bar (Pack of 6)',
      'Key Ingredients': 'Almonds, Pistachios, Sunflower Seeds, Pumpkin Seeds, Dates, Jaggery',
      'Allergens': 'Contains Tree Nuts',
      'Sugar': 'No Added Sugar',
      'Preservatives': 'None',
      'Country of Origin': 'India — Made in Hyderabad',
      'Best For': 'Morning Snack, Pre-Workout, Travel',
    },
  ),

  'fs2': const RteMeta(
    weight: '30g × 6 Pack',
    originalPrice: 420,
    isNew: true,
    imageUrls: [
      'assets/images/jasmun_1.png',
      'assets/images/jasmun_2.png',
      'assets/images/jasmun_3.png',
    ],
    aboutProduct:
    'Happy Jamun Nutrition Bar is India\'s first energy bar featuring Black Jamun '
        '(Neredu Pandu) — a powerful antioxidant superfruit. Blended with oats, almonds, '
        'sunflower seeds and pumpkin seeds for a nutritionally dense snack. '
        'Rich in Vitamin C and anthocyanins that support immunity and digestion. '
        'No artificial colours, no added sugar — pure natural goodness.',
    otherInfo: {
      'Brand': 'FitSport Nutrition',
      'Net Weight': '30g per bar (Pack of 6)',
      'Key Ingredients': 'Black Jamun, Oats, Almonds, Sunflower Seeds, Pumpkin Seeds',
      'Antioxidants': 'High (Vitamin C, Anthocyanins)',
      'Sugar': 'No Added Sugar',
      'Preservatives': 'None',
      'Country of Origin': 'India — Made in Hyderabad',
      'Best For': 'Immunity Boost, Digestive Health, Kids',
    },
  ),

  'fs3': const RteMeta(
    weight: '30g × 6 Pack',
    originalPrice: 360,
    imageUrls: [
      'assets/images/coco_bar_1.png',
      'assets/images/coco_bar_2.png',
      'assets/images/coco_bar_1.png',
    ],
    aboutProduct:
    'Happy Coco Bar brings the tropical goodness of desiccated coconut blended with '
        'premium dry fruits, crunchy nuts and nutrient-packed seeds. Sweetened with natural '
        'jaggery and preserved with rosemary extract — completely free of synthetic additives. '
        'A naturally flavourful bar that\'s as delicious as it is healthy. '
        'Perfect for coconut lovers and health-conscious snackers.',
    otherInfo: {
      'Brand': 'FitSport Nutrition',
      'Net Weight': '30g per bar (Pack of 6)',
      'Key Ingredients': 'Desiccated Coconut, Dry Fruits, Nuts, Seeds, Jaggery',
      'Preservative': 'Rosemary Extract (Natural)',
      'Sugar': 'No Added Sugar',
      'Country of Origin': 'India — Made in Hyderabad',
      'Best For': 'Coconut Lovers, Travel, Evening Snack',
    },
  ),

  'fs4': const RteMeta(
    weight: '40g × 10 Pack',
    originalPrice: 700,
    isBestseller: true,
    imageUrls: [
      'assets/images/12gm_protienbar_1.png',
      'assets/images/12gm_protienbar_2.png',
      'assets/images/12gm_protienbar_3.png',
    ],
    aboutProduct:
    'Happy Sport 12g Protein Bar is the ultimate post-workout fuel crafted with '
        'premium whey protein, natural peanut butter and rich dark chocolate chips. '
        'Each bar packs 12g of high-quality protein with crunchy rice crisps for texture. '
        'Loved by Shark Tank Sharks especially Aman Gupta — voted World\'s Tastiest Protein Bar. '
        'No artificial sweeteners. Real taste, real results.',
    otherInfo: {
      'Brand': 'FitSport Nutrition',
      'Net Weight': '40g per bar (Pack of 10)',
      'Protein': '12g per bar',
      'Key Ingredients': 'Whey Protein, Peanut Butter, Dark Choco Chips, Rice Crisps',
      'Allergens': 'Contains Milk, Peanuts',
      'Artificial Sweeteners': 'None',
      'Country of Origin': 'India — Made in Hyderabad',
      'Best For': 'Post-Workout, Muscle Recovery, Gym Snack',
    },
  ),

  'fs5': const RteMeta(
    weight: '40g × 6 Pack',
    originalPrice: 600,
    isBestseller: true,
    imageUrls: [
      'assets/images/20gm_protienbar_1.png',
      'assets/images/20gm_protienbar_2.png',
      'assets/images/20gm_protienbar_3.png',
    ],
    aboutProduct:
    'FitSport 20g Protein Bar is our highest-protein bar, packing a massive 20g of '
        'whey protein per bar with irresistible peanut butter and dark chocolate chips. '
        'Perfect for serious athletes, bodybuilders and fitness enthusiasts who need '
        'maximum protein in minimum calories. Clean ingredients, no artificial additives — '
        'the cleanest and tastiest protein bar on the market.',
    otherInfo: {
      'Brand': 'FitSport Nutrition',
      'Net Weight': '40g per bar (Pack of 6)',
      'Protein': '20g per bar',
      'Key Ingredients': 'Whey Protein, Peanut Butter, Dark Choco Chips, Almonds',
      'Allergens': 'Contains Milk, Peanuts, Tree Nuts',
      'Artificial Additives': 'None',
      'Country of Origin': 'India — Made in Hyderabad',
      'Best For': 'Bodybuilding, High Protein Diet, Muscle Gain',
    },
  ),

  // ── Nutritius ─────────────────────────────────────────────────────────────

  'nu1': const RteMeta(
    weight: '100g × 6 Pack',
    originalPrice: 1200,
    isBestseller: true,
    imageUrls: [
      'assets/images/dry_fruit_chikki_1.png',
      'assets/images/dry_fruit_chikki_2.png',
      'assets/images/dry_fruit_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Dry Fruit Chikki is a premium blend of handpicked dry fruits — '
        'almonds, cashews, pistachios and raisins — bound together with pure jaggery. '
        'A 100-year-old traditional Indian recipe reimagined for modern health-conscious families. '
        'No artificial colours, flavours or preservatives. Soft, chewy and naturally sweet. '
        'Perfect for kids and adults as a guilt-free energy snack.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '100g per pack (Pack of 6)',
      'Key Ingredients': 'Almonds, Cashews, Pistachios, Raisins, Jaggery, Cane Sugar, Liquid Glucose',
      'Preservatives': 'None',
      'Specialty': 'Preservative-Free, Vegan',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Family Snack, School Tiffin, Gifting',
    },
  ),

  'nu2': const RteMeta(
    weight: '125g × 6 Pack',
    originalPrice: 580,
    imageUrls: [
      'assets/images/peanut_butter_chikki_1.png',
      'assets/images/peanut_butter_chikki_2.png',
      'assets/images/peanut_butter_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Peanut Butter Chikki is soft, creamy and absolutely irresistible. '
        'Made with roasted peanuts and rich peanut butter flavour — nothing like the hard '
        'traditional chikki. These melt in your mouth and are loved by all ages. '
        'Dairy free, gluten free and vegan — a pioneer in soft peanut butter chikki category. '
        'No artificial colours or preservatives.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '125g per pack (Pack of 6)',
      'Key Ingredients': 'Roasted Peanuts, Peanut Butter, Jaggery, Cane Sugar, Liquid Glucose',
      'Preservatives': 'None',
      'Specialty': 'Dairy Free, Gluten Free, Vegan',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Peanut Butter Lovers, Kids Snack, Evening Treat',
    },
  ),

  'nu3': const RteMeta(
    weight: '125g × 6 Pack',
    originalPrice: 580,
    isNew: true,
    imageUrls: [
      'assets/images/almond_butter_chikki_1.png',
      'assets/images/almond_butter_chikki_2.png',
      'assets/images/almond_butter_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Almond Butter Chikki is a rich, nutty delight made with real almond butter '
        'and roasted peanuts. Soft-bite texture that is easy on teeth for all age groups. '
        'High in healthy fats, natural energy and great taste. No added artificial flavours — '
        'just the pure, wholesome goodness of almonds in every bite. '
        'Gluten free and dairy free for a clean snacking experience.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '125g per pack (Pack of 6)',
      'Key Ingredients': 'Roasted Peanuts, Almond Butter, Jaggery, Cane Sugar, Liquid Glucose',
      'Preservatives': 'None',
      'Specialty': 'Dairy Free, Gluten Free, Vegan',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Almond Lovers, Healthy Gifting, Fitness Snack',
    },
  ),

  'nu4': const RteMeta(
    weight: '125g × 6 Pack',
    originalPrice: 580,
    imageUrls: [
      'assets/images/cashew_peanut_butter_chikki_1.png',
      'assets/images/cashew_peanut_butter_chikki_2.png',
      'assets/images/cashew_peanut_butter_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Cashew Peanut Butter Chikki brings together the creamy richness of '
        'cashews and peanut butter in a soft, bite-sized chikki. The combination creates '
        'a uniquely indulgent flavour that is hard to resist. '
        'Made with no preservatives, no dairy and no gluten — perfectly suited for health '
        'conscious snackers and those with dietary restrictions.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '125g per pack (Pack of 6)',
      'Key Ingredients': 'Roasted Peanuts, Cashew Butter, Jaggery, Cane Sugar, Liquid Glucose',
      'Preservatives': 'None',
      'Specialty': 'Dairy Free, Gluten Free, Vegan',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Cashew Lovers, Dessert Alternative, School Snack',
    },
  ),

  'nu5': const RteMeta(
    weight: '125g × 6 Pack',
    originalPrice: 600,
    isBestseller: true,
    imageUrls: [
      'assets/images/hazelnut_butter_chikki_1.png',
      'assets/images/hazelnut_butter_chikki_2.png',
      'assets/images/hazelnut_butter_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Hazelnut Butter Chikki is a highly unique, irresistible snack featuring '
        'hazelnut chocolate spread — the first of its kind in the chikki category. '
        'Pioneers in this segment, there are no chikkis like these in the market. '
        'Soft, extremely flavourful and delightfully tasty. No artificial colours, '
        'preservatives or dairy. Pure hazelnut bliss in every bite.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '125g per pack (Pack of 6)',
      'Key Ingredients': 'Roasted Peanuts, Hazelnut Chocolate Spread, Jaggery, Sugar, Liquid Glucose',
      'Preservatives': 'None',
      'Specialty': 'Dairy Free, Gluten Free, Vegan',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Hazelnut Fans, Kids Favourite, Premium Gifting',
    },
  ),

  'nu6': const RteMeta(
    weight: '100g × 6 Pack',
    originalPrice: 300,
    imageUrls: [
      'assets/images/crunchy_chikki_1.png',
      'assets/images/crunchy_chikki_2.png',
      'assets/images/crunchy_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Crunchy Peanut Chikki is the classic, traditional peanut brittle '
        'made with freshly roasted peanuts and pure jaggery. '
        'Crisp, crunchy and naturally sweet — the way your grandma used to make it. '
        'Absolutely no artificial additives, colours or preservatives. '
        'Great as a daily snack, energy booster or sweet bite after meals. '
        'Best value in our range for everyday snacking.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '100g per pack (Pack of 6)',
      'Key Ingredients': 'Roasted Peanuts, Jaggery, Cane Sugar, Liquid Glucose',
      'Preservatives': 'None',
      'Specialty': 'Dairy Free, Gluten Free, Vegan',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Daily Snack, After Meals, Budget Friendly',
    },
  ),

  'nu7': const RteMeta(
    weight: '125g × 6 Pack',
    originalPrice: 380,
    imageUrls: [
      'assets/images/ragira_peanut_chikki_1.png',
      'assets/images/ragira_peanut_chikki_2.png',
      'assets/images/ragira_peanut_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Rajgira Peanut Chikki combines the power of Rajgira (Amaranth) and '
        'crunchy peanuts in a jaggery base. Rajgira is a superfood grain — gluten free, '
        'high in protein, iron and calcium. A perfect Navratri snack that is also great '
        'for everyday eating. Traditional flavour with modern nutritional benefits. '
        'No preservatives, naturally vegan and dairy free.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '125g per pack (Pack of 6)',
      'Key Ingredients': 'Rajgira (Amaranth), Roasted Peanuts, Jaggery, Cane Sugar, Liquid Glucose',
      'Protein': 'High (Rajgira + Peanuts)',
      'Specialty': 'Gluten Free, Iron Rich, Navratri Special',
      'Preservatives': 'None',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Navratri, Fitness Snack, High Protein Diet',
    },
  ),

  'nu8': const RteMeta(
    weight: '125g × 6 Pack',
    originalPrice: 380,
    isNew: true,
    imageUrls: [
      'assets/images/sesame_chikki_1.png',
      'assets/images/sesame_chikki_2.png',
      'assets/images/sesame_chikki_3.png',
    ],
    aboutProduct:
    'Nutritius Sesame Crunch Chikki is made from golden roasted sesame seeds and '
        'pure jaggery — a calcium powerhouse in every bite. '
        'Sesame seeds are one of the richest plant sources of calcium, supporting '
        'strong bones and teeth. Light, crunchy and delicately sweet with a nutty aroma. '
        'Traditional Til Chikki loved across India. No preservatives, dairy free, vegan.',
    otherInfo: {
      'Brand': 'Nutritius',
      'Net Weight': '125g per pack (Pack of 6)',
      'Key Ingredients': 'Roasted Sesame Seeds, Jaggery, Cane Sugar, Liquid Glucose',
      'Calcium': 'High (Sesame Seeds)',
      'Specialty': 'Dairy Free, Gluten Free, Vegan',
      'Preservatives': 'None',
      'Country of Origin': 'India — Made in Navsari, Gujarat',
      'Best For': 'Bone Health, Light Snack, Traditional Flavour',
    },
  ),
};

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReadyToEatScreen extends StatefulWidget {
  const ReadyToEatScreen({super.key});

  @override
  State<ReadyToEatScreen> createState() => _ReadyToEatScreenState();
}

class _ReadyToEatScreenState extends State<ReadyToEatScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MenuItem> _filtered(List<MenuItem> backendItems) => backendItems.where((p) {
    final matchCat =
        _selectedCategory == 'All' || p.category == _selectedCategory;
    final matchSearch = _searchQuery.isEmpty ||
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.description
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
    return matchCat && matchSearch;
  }).toList();

  int _qty(AppProvider provider, String id) => provider.cartItems
      .where((c) => c.menuItem.id == id)
      .fold(0, (s, c) => s + c.quantity);

  void _openDetail(BuildContext context, MenuItem item) {
    HapticFeedback.mediumImpact();
    // Use meta if available, or construct basic meta for items from backend
    final meta = rteMeta[item.id] ?? RteMeta(
      weight: 'Unit',
      aboutProduct: item.description,
      otherInfo: {'Category': item.category},
      imageUrls: [item.imageUrl],
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          args: ProductDetailArgs(
            menuItem: item,
            weight: meta.weight,
            originalPrice: meta.originalPrice,
            isBestseller: meta.isBestseller,
            aboutProduct: meta.aboutProduct,
            otherInfo: meta.otherInfo,
            imageUrls: meta.imageUrls,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = _filtered(provider.readyToEatItems);
    final ws = MediaQuery.of(context).size.width / _rteRefW;
    final hs = MediaQuery.of(context).size.height / _rteRefH;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _buildHeader(context, provider, ws, hs),

            // ── Search ──────────────────────────────────────────────────────
            _buildSearch(ws, hs),

            // ── Scroll body ─────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8 * hs),
                    _buildCategoryChips(ws, hs),
                    SizedBox(height: 10 * hs),
                    _buildSectionHeader(filtered.length, ws, hs),
                    SizedBox(height: 6 * hs),
                    if (filtered.isEmpty)
                      _buildEmpty(ws, hs)
                    else
                      _buildList(context, provider, filtered, ws, hs),
                    SizedBox(height: 90 * hs),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── View Cart FAB ───────────────────────────────────────────────────────
      floatingActionButton: provider.cartItemCount > 0
          ? _ViewCartFAB(
        itemCount: provider.cartItemCount,
        total: provider.cartTotal,
        ws: ws,
        hs: hs,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CartScreen())),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, AppProvider provider, double ws, double hs) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 10 * hs),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8 * ws),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10 * ws)),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16 * ws, color: const Color(0xFF0F172A)),
            ),
          ),
          SizedBox(width: 12 * ws),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready to Eat',
                    style: TextStyle(
                        fontSize: 17 * ws,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        fontFamily: 'Poppins')),
                Text('Sugar Free · Preservative Free',
                    style: TextStyle(
                        fontSize: 10 * ws,
                        color: Colors.grey.shade500,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
          GestureDetector(
            onTap: provider.cartItemCount > 0
                ? () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen()))
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(9 * ws),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10 * ws)),
                  child: Icon(Icons.shopping_bag_outlined,
                      size: 20 * ws, color: const Color(0xFF0F172A)),
                ),
                if (provider.cartItemCount > 0)
                  Positioned(
                    right: -3 * ws,
                    top: -3 * ws,
                    child: Container(
                      width: 16 * ws,
                      height: 16 * ws,
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text('${provider.cartItemCount}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8 * ws,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────────────
  Widget _buildSearch(double ws, double hs) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14 * ws, 0, 14 * ws, 8 * hs),
      child: Container(
        height: 38 * hs,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * ws),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12 * ws),
            Icon(Icons.search_rounded,
                size: 18 * ws, color: Colors.grey.shade400),
            SizedBox(width: 8 * ws),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(
                    fontSize: 13 * ws,
                    fontFamily: 'Poppins',
                    color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Search bars, chikki, flavours...',
                  hintStyle: TextStyle(
                      fontSize: 13 * ws,
                      color: Colors.grey.shade400,
                      fontFamily: 'Poppins'),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                child: Padding(
                  padding: EdgeInsets.all(8 * ws),
                  child: Icon(Icons.close_rounded,
                      size: 16 * ws, color: Colors.grey.shade400),
                ),
              ),
            SizedBox(width: 8 * ws),
          ],
        ),
      ),
    );
  }

  // ── Category Chips ──────────────────────────────────────────────────────────
  Widget _buildCategoryChips(double ws, double hs) {
    return SizedBox(
      height: 34 * hs,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14 * ws),
        itemCount: _rteCats.length,
        separatorBuilder: (_, __) => SizedBox(width: 8 * ws),
        itemBuilder: (_, i) {
          final cat = _rteCats[i];
          final isSelected = _selectedCategory == cat.label;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat.label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                  horizontal: 12 * ws, vertical: 5 * hs),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20 * ws),
                border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade200),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(cat.emoji, style: TextStyle(fontSize: 13 * ws)),
                  SizedBox(width: 5 * ws),
                  Text(cat.label,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontSize: 12 * ws,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Section header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(int count, double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14 * ws),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _selectedCategory == 'All' ? 'All Products' : _selectedCategory,
            style: TextStyle(
                fontSize: 15 * ws,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                fontFamily: 'Poppins'),
          ),
          Text('$count item${count != 1 ? 's' : ''}',
              style: TextStyle(
                  fontSize: 11 * ws,
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  // ── Product List ────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, AppProvider provider,
      List<MenuItem> items, double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14 * ws),
      child: Column(
        children: items.map((item) {
          final meta = rteMeta[item.id] ?? RteMeta(
            weight: 'Unit',
            aboutProduct: item.description,
            otherInfo: {'Category': item.category},
            imageUrls: [item.imageUrl],
          );
          final qty = _qty(provider, item.id);
          return _RteCard(
            item: item,
            meta: meta,
            cartCount: qty,
            ws: ws,
            hs: hs,
            onTap: () => _openDetail(context, item),
            onAdd: () {
              HapticFeedback.mediumImpact();
              provider.addToCart(item);
            },
            onRemove: () {
              HapticFeedback.lightImpact();
              provider.updateQuantity(item.id, qty - 1);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmpty(double ws, double hs) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60 * hs),
      child: Center(
        child: Column(
          children: [
            Text('🔍', style: TextStyle(fontSize: 40 * ws)),
            SizedBox(height: 12 * hs),
            Text('No products found',
                style: TextStyle(
                    fontSize: 14 * ws,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    fontFamily: 'Poppins')),
            SizedBox(height: 4 * hs),
            Text('Try a different search or category',
                style: TextStyle(
                    fontSize: 12 * ws,
                    color: Colors.grey.shade500,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _RteCard extends StatelessWidget {
  final MenuItem item;
  final RteMeta meta;
  final int cartCount;
  final double ws, hs;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _RteCard({
    required this.item,
    required this.meta,
    required this.cartCount,
    required this.ws,
    required this.hs,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = meta.originalPrice != null;
    final discountPct = hasDiscount
        ? (((meta.originalPrice! - item.price) / meta.originalPrice!) * 100)
        .round()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8 * hs),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14 * ws),
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(10 * ws),
          child: Row(
            children: [
              // ── Image ─────────────────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10 * ws),
                    child: Image.asset(
                      item.imageUrl,
                      width: 82 * ws,
                      height: 82 * ws,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 82 * ws,
                        height: 82 * ws,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10 * ws),
                        ),
                        child: Center(
                          child: Text(item.emoji,
                              style: TextStyle(fontSize: 32 * ws)),
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 4 * hs,
                      left: 4 * ws,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5 * ws, vertical: 2 * hs),
                        decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(4 * ws)),
                        child: Text('$discountPct% OFF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 7 * ws,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 11 * ws),

              // ── Text info ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: TextStyle(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5 * ws,
                                  fontFamily: 'Poppins'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (meta.isBestseller)
                          Container(
                            margin: EdgeInsets.only(left: 4 * ws),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6 * ws, vertical: 2 * hs),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius:
                                BorderRadius.circular(6 * ws)),
                            child: Text('🏆 Best',
                                style: TextStyle(
                                    fontSize: 8 * ws,
                                    color: const Color(0xFFD97706),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins')),
                          )
                        else if (meta.isNew)
                          Container(
                            margin: EdgeInsets.only(left: 4 * ws),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6 * ws, vertical: 2 * hs),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius:
                                BorderRadius.circular(6 * ws)),
                            child: Text('✨ New',
                                style: TextStyle(
                                    fontSize: 8 * ws,
                                    color: const Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins')),
                          ),
                      ],
                    ),
                    SizedBox(height: 2 * hs),
                    Text(item.description,
                        style: TextStyle(
                            color: AppTheme.textMedium,
                            fontSize: 11 * ws,
                            fontFamily: 'Poppins',
                            height: 1.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 5 * hs),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppTheme.yellow, size: 13 * ws),
                        SizedBox(width: 2 * ws),
                        Text('${item.rating}',
                            style: TextStyle(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 11 * ws,
                                fontFamily: 'Poppins')),
                        SizedBox(width: 6 * ws),
                        Container(
                            width: 3 * ws,
                            height: 3 * ws,
                            decoration: BoxDecoration(
                                color:
                                AppTheme.textLight.withOpacity(0.6),
                                shape: BoxShape.circle)),
                        SizedBox(width: 6 * ws),
                        Text(meta.weight,
                            style: TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 11 * ws,
                                fontFamily: 'Poppins')),
                      ],
                    ),
                    SizedBox(height: 7 * hs),

                    // Price + Add / Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${item.price.toInt()}',
                                style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16 * ws,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.2)),
                            if (hasDiscount)
                              Text('₹${meta.originalPrice!.toInt()}',
                                  style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 10 * ws,
                                      fontFamily: 'Poppins',
                                      decoration:
                                      TextDecoration.lineThrough)),
                          ],
                        ),
                        cartCount == 0
                            ? GestureDetector(
                          onTap: onAdd,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 13 * ws,
                                vertical: 6 * hs),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius:
                              BorderRadius.circular(8 * ws),
                              boxShadow: [
                                BoxShadow(
                                    color: AppTheme.primaryGreen
                                        .withOpacity(0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Colors.white,
                                    size: 15 * ws),
                                SizedBox(width: 3 * ws),
                                Text('Add',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12 * ws,
                                        fontFamily: 'Poppins')),
                              ],
                            ),
                          ),
                        )
                            : Container(
                          decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius:
                              BorderRadius.circular(8 * ws)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: onRemove,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8 * ws,
                                      vertical: 6 * hs),
                                  child: Icon(Icons.remove,
                                      size: 14 * ws,
                                      color: Colors.white),
                                ),
                              ),
                              Text('$cartCount',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13 * ws,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins')),
                              GestureDetector(
                                onTap: onAdd,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8 * ws,
                                      vertical: 6 * hs),
                                  child: Icon(Icons.add,
                                      size: 14 * ws,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── View Cart FAB ────────────────────────────────────────────────────────────

class _ViewCartFAB extends StatelessWidget {
  final int itemCount;
  final double total;
  final double ws, hs;
  final VoidCallback onTap;

  const _ViewCartFAB({
    required this.itemCount,
    required this.total,
    required this.ws,
    required this.hs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: 20 * ws, vertical: 14 * hs),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(14 * ws),
          boxShadow: [
            BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22 * ws,
              height: 22 * ws,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle),
              child: Center(
                child: Text('$itemCount',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * ws,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins')),
              ),
            ),
            SizedBox(width: 10 * ws),
            Text('View Cart',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13 * ws,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            SizedBox(width: 10 * ws),
            Text('₹${total.toInt()}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12 * ws,
                    fontFamily: 'Poppins')),
            SizedBox(width: 8 * ws),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12 * ws, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
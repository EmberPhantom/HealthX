// lib/screens/category_detail_screen.dart
// ✅ Opens when user taps a category banner from MenuScreen
// ✅ Hero banner at top (same style as reference — CRISPY BITES, DELHI STYLE CHAATS etc.)
// ✅ 2-column product grid below — exactly matching reference screenshot style
// ✅ Each card: large image, Bestseller/New badge, Customise label, Add/stepper button
// ✅ Tags: Serves 1, Crispy, High Protein etc.
// ✅ "High Demand" / "Top-Selling in Indiranagar" label
// ✅ 20 products per category using curated Unsplash images
// ✅ Offer banner (50% upto ₹150 off) at bottom
// ✅ Fully connected to AppProvider cart
// ✅ Production-ready, error-free Flutter code

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'menu_screen.dart' show CategoryBannerData;
import 'product_detail_screen.dart';
import 'cart_screen.dart';

const double _refW = 390.0;
const double _refH = 844.0;

// ─── Product model for this screen ───────────────────────────────────────────

class _CatProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final int calories;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String emoji;
  final List<String> tags;
  final bool isVeg;
  final bool isBestseller;
  final bool isNew;
  final bool isHighDemand;
  final bool isTopSelling;
  final bool isCustomisable;

  const _CatProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.emoji,
    this.tags = const ['Serves 1'],
    this.isVeg = true,
    this.isBestseller = false,
    this.isNew = false,
    this.isHighDemand = false,
    this.isTopSelling = false,
    this.isCustomisable = false,
  });

  MenuItem toMenuItem() => MenuItem(
    id: id, name: name, description: description,
    price: price, calories: calories, rating: rating,
    reviewCount: reviewCount, imageUrl: imageUrl, emoji: emoji,
    category: 'All', tags: tags, isVeg: isVeg,
  );
}

// ─── Product lists per category ───────────────────────────────────────────────

const Map<String, List<_CatProduct>> _categoryProducts = {

  // ══════ HEARTY BREAKFAST ══════════════════════════════════════════════════
  'HEARTY BREAKFAST': [
    _CatProduct(id: 'hb1', name: 'Butter Corn', description: 'Seasoned sweet corn with loads of butter', price: 139, calories: 210, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?q=80&w=400&auto=format&fit=crop', emoji: '🌽', tags: ['Serves 1'], isVeg: true, isBestseller: false, isCustomisable: true),
    _CatProduct(id: 'hb2', name: 'Boiled Eggs', description: 'Three soft yet firm boiled eggs, served with salt and pepper', price: 79, calories: 155, rating: 4.6, reviewCount: 890, imageUrl: 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?q=80&w=400&auto=format&fit=crop', emoji: '🥚', tags: ['3 Eggs', '18g Protein'], isVeg: false, isNew: true, isCustomisable: false),
    _CatProduct(id: 'hb3', name: 'Papaya Cubes', description: 'Fresh papaya cubes cut and served fresh', price: 89, calories: 120, rating: 4.3, reviewCount: 201, imageUrl: 'https://images.unsplash.com/photo-1526318896980-cf78c088247c?q=80&w=400&auto=format&fit=crop', emoji: '🍈', tags: ['Serves 1', 'Vegan'], isVeg: true, isNew: true),
    _CatProduct(id: 'hb4', name: 'Corn Chaat', description: 'Healthy snack made from fresh sweet corns', price: 119, calories: 190, rating: 4.7, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?q=80&w=400&auto=format&fit=crop', emoji: '🌽', tags: ['Serves 1'], isVeg: true, isTopSelling: true, isCustomisable: true),
    _CatProduct(id: 'hb5', name: 'Pav Bhaji', description: 'Mumbai special mashed bhaji served with 4 soft buns', price: 149, calories: 380, rating: 4.8, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🍞', tags: ['Serves 1'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'hb6', name: 'Poha', description: 'Light flattened rice with onions, mustard seeds and curry leaves', price: 99, calories: 240, rating: 4.5, reviewCount: 523, imageUrl: 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?q=80&w=400&auto=format&fit=crop', emoji: '🍚', tags: ['Serves 1', 'Light'], isVeg: true),
    _CatProduct(id: 'hb7', name: 'Upma', description: 'South Indian semolina dish with vegetables', price: 89, calories: 260, rating: 4.4, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?q=80&w=400&auto=format&fit=crop', emoji: '🍲', tags: ['Serves 1', 'South Indian'], isVeg: true),
    _CatProduct(id: 'hb8', name: 'Masala Omelette', description: 'Fluffy 3-egg omelette with onions, tomatoes and spices', price: 109, calories: 285, rating: 4.6, reviewCount: 489, imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=400&auto=format&fit=crop', emoji: '🍳', tags: ['3 Eggs', 'High Protein'], isVeg: false, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'hb9', name: 'Idli Sambar', description: '4 soft idlis with hot sambar and chutneys', price: 129, calories: 320, rating: 4.7, reviewCount: 601, imageUrl: 'https://images.unsplash.com/photo-1630383249896-424e482df921?q=80&w=400&auto=format&fit=crop', emoji: '🫓', tags: ['Serves 1', 'South Indian'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'hb10', name: 'Dosa', description: 'Crispy fermented rice crepe served with sambar and chutney', price: 149, calories: 350, rating: 4.8, reviewCount: 734, imageUrl: 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?q=80&w=400&auto=format&fit=crop', emoji: '🫓', tags: ['Serves 1', 'Crispy'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'hb11', name: 'Fruit Bowl', description: 'Seasonal fresh fruits with honey drizzle', price: 149, calories: 185, rating: 4.5, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?q=80&w=400&auto=format&fit=crop', emoji: '🍓', tags: ['Serves 1', 'Vegan'], isVeg: true),
    _CatProduct(id: 'hb12', name: 'Granola Bowl', description: 'Crunchy granola with fresh berries and almond milk', price: 179, calories: 290, rating: 4.6, reviewCount: 198, imageUrl: 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?q=80&w=400&auto=format&fit=crop', emoji: '🥣', tags: ['Serves 1', 'Healthy'], isVeg: true, isNew: true),
    _CatProduct(id: 'hb13', name: 'Banana Pancakes', description: 'Fluffy banana pancakes with honey and butter', price: 159, calories: 340, rating: 4.4, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?q=80&w=400&auto=format&fit=crop', emoji: '🥞', tags: ['Serves 1', 'Sweet'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'hb14', name: 'Veggie Oats', description: 'Savoury oats with mixed veggies and spices', price: 119, calories: 210, rating: 4.3, reviewCount: 178, imageUrl: 'https://images.unsplash.com/photo-1495214783159-3503fd1b572d?q=80&w=400&auto=format&fit=crop', emoji: '🥣', tags: ['Serves 1', 'Low Cal'], isVeg: true),
    _CatProduct(id: 'hb15', name: 'Sprouts Salad', description: 'Mixed sprouts with lemon, chaat masala and vegetables', price: 109, calories: 160, rating: 4.5, reviewCount: 289, imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop', emoji: '🌱', tags: ['Serves 1', 'Protein'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'hb16', name: 'Egg Bhurji', description: 'Scrambled eggs with spiced onions and tomatoes', price: 129, calories: 270, rating: 4.6, reviewCount: 421, imageUrl: 'https://images.unsplash.com/photo-1559847844-5315695dadae?q=80&w=400&auto=format&fit=crop', emoji: '🍳', tags: ['2 Eggs', 'High Protein'], isVeg: false, isHighDemand: true),
    _CatProduct(id: 'hb17', name: 'Aloo Paratha', description: 'Whole wheat flatbread stuffed with spiced potatoes', price: 139, calories: 380, rating: 4.7, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=400&auto=format&fit=crop', emoji: '🫓', tags: ['Serves 1', 'Filling'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'hb18', name: 'Curd Rice', description: 'Comforting south Indian yogurt rice with tempering', price: 119, calories: 290, rating: 4.4, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1546039907-7fa05f864c02?q=80&w=400&auto=format&fit=crop', emoji: '🍚', tags: ['Serves 1', 'Cooling'], isVeg: true),
    _CatProduct(id: 'hb19', name: 'Dhokla', description: 'Steamed spongy Gujarati snack with chutneys', price: 99, calories: 185, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🟡', tags: ['Serves 1', 'Light'], isVeg: true),
    _CatProduct(id: 'hb20', name: 'Avocado Toast', description: 'Multigrain toast with smashed avocado and seasonings', price: 179, calories: 295, rating: 4.8, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?q=80&w=400&auto=format&fit=crop', emoji: '🥑', tags: ['Serves 1', 'Healthy Fats'], isVeg: true, isBestseller: true, isNew: true),
  ],

  // ══════ DELHI-STYLE CHAATS ════════════════════════════════════════════════
  'DELHI-STYLE CHAATS': [
    _CatProduct(id: 'dc1', name: 'Dahi Papdi Chaat', description: 'Crunchy papdi chaat with curd, chutneys & sev', price: 139, calories: 310, rating: 4.8, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=400&auto=format&fit=crop', emoji: '🍽️', tags: ['Serves 1'], isVeg: true, isBestseller: true, isTopSelling: true, isCustomisable: true),
    _CatProduct(id: 'dc2', name: 'Dahi Samosa Chaat', description: 'Crispy samosas with curd, chutneys, spices & sev', price: 139, calories: 340, rating: 4.7, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1505253758473-96b7015fcd40?q=80&w=400&auto=format&fit=crop', emoji: '🥟', tags: ['Serves 1'], isVeg: true, isTopSelling: true, isCustomisable: true),
    _CatProduct(id: 'dc3', name: 'Bhel Puri', description: 'Crispy puffed rice with onions, tomatoes & chutneys', price: 119, calories: 265, rating: 4.6, reviewCount: 812, imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?q=80&w=400&auto=format&fit=crop', emoji: '🍿', tags: ['Serves 1', 'Tangy'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'dc4', name: 'Pani Puri', description: '8 crispy puris with spiced tangy water and filling', price: 99, calories: 210, rating: 4.9, reviewCount: 1245, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🫧', tags: ['8 Pcs', 'Tangy'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'dc5', name: 'Aloo Tikki Chaat', description: 'Crispy potato patties topped with chutneys and curd', price: 129, calories: 355, rating: 4.7, reviewCount: 467, imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?q=80&w=400&auto=format&fit=crop', emoji: '🥔', tags: ['Serves 1', 'Crispy'], isVeg: true, isTopSelling: true, isCustomisable: true),
    _CatProduct(id: 'dc6', name: 'Raj Kachori', description: 'Giant crispy kachori stuffed with sprouts, sev & chutneys', price: 149, calories: 420, rating: 4.8, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop', emoji: '🍥', tags: ['Serves 1', 'Royal'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'dc7', name: 'Sev Puri', description: 'Crispy flat puris topped with potatoes, onions & sev', price: 109, calories: 290, rating: 4.5, reviewCount: 523, imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=400&auto=format&fit=crop', emoji: '🥗', tags: ['Serves 1', 'Crunchy'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'dc8', name: 'Dahi Vada', description: 'Soft lentil dumplings in chilled curd with chutneys', price: 129, calories: 280, rating: 4.6, reviewCount: 345, imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?q=80&w=400&auto=format&fit=crop', emoji: '🍡', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'dc9', name: 'Masala Puri', description: 'Smashed puris with spiced mashed potatoes and garnish', price: 119, calories: 310, rating: 4.5, reviewCount: 278, imageUrl: 'https://images.unsplash.com/photo-1546039907-7fa05f864c02?q=80&w=400&auto=format&fit=crop', emoji: '🫓', tags: ['Serves 1'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'dc10', name: 'Palak Patta Chaat', description: 'Fried spinach leaves topped with curd and chutneys', price: 149, calories: 245, rating: 4.7, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=400&auto=format&fit=crop', emoji: '🥬', tags: ['Serves 1', 'Unique'], isVeg: true, isNew: true),
    _CatProduct(id: 'dc11', name: 'Katori Chaat', description: 'Edible katori filled with potato filling, chutney & curd', price: 159, calories: 360, rating: 4.6, reviewCount: 189, imageUrl: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?q=80&w=400&auto=format&fit=crop', emoji: '🍜', tags: ['Serves 1', 'Premium'], isVeg: true),
    _CatProduct(id: 'dc12', name: 'Papri Chaat', description: 'Classic chaat with papri, boiled potatoes, chickpeas & sev', price: 129, calories: 330, rating: 4.7, reviewCount: 456, imageUrl: 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?q=80&w=400&auto=format&fit=crop', emoji: '🥘', tags: ['Serves 1'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'dc13', name: 'Basket Chaat', description: 'Potato basket filled with spiced veggies and chutneys', price: 169, calories: 380, rating: 4.5, reviewCount: 145, imageUrl: 'https://images.unsplash.com/photo-1505253758473-96b7015fcd40?q=80&w=400&auto=format&fit=crop', emoji: '🧺', tags: ['Serves 1', 'Crispy'], isVeg: true, isNew: true),
    _CatProduct(id: 'dc14', name: 'Chana Chaat', description: 'Spiced chickpeas with onions, tomatoes and lemon', price: 119, calories: 295, rating: 4.6, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?q=80&w=400&auto=format&fit=crop', emoji: '🫘', tags: ['Serves 1', 'Protein'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'dc15', name: 'Moong Dal Chaat', description: 'Sprouted moong dal with spices, onion and lemon', price: 109, calories: 210, rating: 4.4, reviewCount: 198, imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop', emoji: '🫘', tags: ['Serves 1', 'Healthy'], isVeg: true),
    _CatProduct(id: 'dc16', name: 'Tokri Chaat', description: 'Crispy potato tokri with tangy veggie filling', price: 179, calories: 350, rating: 4.7, reviewCount: 223, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=400&auto=format&fit=crop', emoji: '🥗', tags: ['Serves 1', 'Premium'], isVeg: true),
    _CatProduct(id: 'dc17', name: 'Chole Tikki Chaat', description: 'Aloo tikki topped with spicy chole, curd and sev', price: 149, calories: 410, rating: 4.8, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?q=80&w=400&auto=format&fit=crop', emoji: '🍛', tags: ['Serves 1'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'dc18', name: 'Mango Puri', description: 'Crispy puris with sweet mango pani — seasonal special', price: 119, calories: 225, rating: 4.6, reviewCount: 167, imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=400&auto=format&fit=crop', emoji: '🥭', tags: ['8 Pcs', 'Seasonal'], isVeg: true, isNew: true),
    _CatProduct(id: 'dc19', name: 'Hara Bhara Chaat', description: 'Green spinach and pea tikki topped with chutney', price: 139, calories: 230, rating: 4.5, reviewCount: 189, imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=400&auto=format&fit=crop', emoji: '🥬', tags: ['Serves 1', 'Green'], isVeg: true),
    _CatProduct(id: 'dc20', name: 'Imli Gola Chaat', description: 'Crushed ice gola drizzled with tamarind & masala', price: 89, calories: 120, rating: 4.7, reviewCount: 423, imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=400&auto=format&fit=crop', emoji: '🧊', tags: ['Serves 1', 'Refreshing'], isVeg: true, isHighDemand: true),
  ],

  // ══════ CRISPY BITES ══════════════════════════════════════════════════════
  'CRISPY BITES': [
    _CatProduct(id: 'cb1', name: 'Salted Potato Wedges', description: 'Wedges sprinkled with salt; comes with dips', price: 129, calories: 310, rating: 4.6, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?q=80&w=400&auto=format&fit=crop', emoji: '🍟', tags: ['Serves 1', 'Crispy'], isVeg: true, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'cb2', name: 'Peri Peri Potato Wedges', description: 'Spicy potato wedges; comes with dips', price: 149, calories: 330, rating: 4.7, reviewCount: 734, imageUrl: 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=400&auto=format&fit=crop', emoji: '🌶️', tags: ['Serves 1', 'Crispy'], isVeg: true, isBestseller: true, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'cb3', name: 'Peri Peri French Fries', description: 'Classic fries tossed in peri peri masala', price: 149, calories: 295, rating: 4.8, reviewCount: 1023, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=400&auto=format&fit=crop', emoji: '🍟', tags: ['Serves 1', 'Crispy'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'cb4', name: 'Masala Samosa', description: '2 crispy golden samosas with mint chutney', price: 89, calories: 280, rating: 4.6, reviewCount: 892, imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?q=80&w=400&auto=format&fit=crop', emoji: '🥟', tags: ['2 Pcs'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'cb5', name: 'Cheese Loaded Fries', description: 'Crispy fries topped with melted cheese sauce', price: 179, calories: 420, rating: 4.7, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?q=80&w=400&auto=format&fit=crop', emoji: '🧀', tags: ['Serves 1', 'Loaded'], isVeg: true, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'cb6', name: 'Onion Rings', description: 'Golden crispy onion rings with tangy dip', price: 139, calories: 265, rating: 4.5, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1519984388953-d2406bc725e1?q=80&w=400&auto=format&fit=crop', emoji: '🧅', tags: ['Serves 1', 'Crunchy'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'cb7', name: 'Crispy Corn', description: 'Deep fried crispy corn tossed with spices', price: 129, calories: 255, rating: 4.6, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?q=80&w=400&auto=format&fit=crop', emoji: '🌽', tags: ['Serves 1', 'Crispy'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'cb8', name: 'Bread Pakora', description: 'Stuffed bread dipped in gram flour and deep fried', price: 109, calories: 310, rating: 4.4, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?q=80&w=400&auto=format&fit=crop', emoji: '🍞', tags: ['2 Pcs'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'cb9', name: 'Paneer Tikka Bites', description: 'Marinated cottage cheese grilled to perfection', price: 199, calories: 340, rating: 4.8, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?q=80&w=400&auto=format&fit=crop', emoji: '🧀', tags: ['Serves 1', 'High Protein'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'cb10', name: 'Spring Rolls', description: 'Crispy vegetable spring rolls with sweet chilli sauce', price: 149, calories: 295, rating: 4.5, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?q=80&w=400&auto=format&fit=crop', emoji: '🥢', tags: ['3 Pcs'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'cb11', name: 'Korean Sweet Chilli Shots', description: 'Crispy fried chicken bites in sweet chilli glaze', price: 179, calories: 360, rating: 4.7, reviewCount: 623, imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?q=80&w=400&auto=format&fit=crop', emoji: '🌶️', tags: ['Serves 1', 'Spicy'], isVeg: false, isBestseller: true, isNew: true),
    _CatProduct(id: 'cb12', name: 'Nachos with Salsa', description: 'Crunchy tortilla chips with fresh salsa and sour cream', price: 159, calories: 310, rating: 4.5, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1527090526205-beaac8dc3c62?q=80&w=400&auto=format&fit=crop', emoji: '🌮', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'cb13', name: 'Potato Smileys', description: '8 crispy smiley face potato snacks', price: 119, calories: 245, rating: 4.6, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?q=80&w=400&auto=format&fit=crop', emoji: '😊', tags: ['8 Pcs', 'Kids Fav'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'cb14', name: 'Momos — Fried', description: '6 crispy fried momos with fiery red chutney', price: 159, calories: 330, rating: 4.8, reviewCount: 789, imageUrl: 'https://images.unsplash.com/photo-1529694157872-4e0c0f3b238b?q=80&w=400&auto=format&fit=crop', emoji: '🥟', tags: ['6 Pcs'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'cb15', name: 'Kurkure Corn Sticks', description: 'Extra crunchy masala corn sticks — addictive snack', price: 99, calories: 220, rating: 4.4, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1519984388953-d2406bc725e1?q=80&w=400&auto=format&fit=crop', emoji: '🌽', tags: ['Serves 1', 'Crunchy'], isVeg: true),
    _CatProduct(id: 'cb16', name: 'Chicken Popcorn', description: 'Bite-sized crispy chicken pieces with seasoning', price: 199, calories: 385, rating: 4.7, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1527477396000-e27163b481c2?q=80&w=400&auto=format&fit=crop', emoji: '🍗', tags: ['Serves 1', 'Non Veg'], isVeg: false, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'cb17', name: 'Hash Browns', description: 'Golden crispy shredded potato patties with dip', price: 139, calories: 280, rating: 4.5, reviewCount: 278, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🥔', tags: ['2 Pcs'], isVeg: true),
    _CatProduct(id: 'cb18', name: 'Cheese Balls', description: 'Melted cheese stuffed crispy golden balls', price: 169, calories: 350, rating: 4.6, reviewCount: 456, imageUrl: 'https://images.unsplash.com/photo-1630383249896-424e482df921?q=80&w=400&auto=format&fit=crop', emoji: '🧀', tags: ['6 Pcs', 'Cheese'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'cb19', name: 'Peri Peri Peanuts', description: 'Crunchy roasted peanuts in peri peri masala', price: 79, calories: 190, rating: 4.3, reviewCount: 198, imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?q=80&w=400&auto=format&fit=crop', emoji: '🥜', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'cb20', name: 'Veg Nuggets', description: '6 crispy vegetable nuggets with ketchup and mayo', price: 149, calories: 295, rating: 4.5, reviewCount: 345, imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?q=80&w=400&auto=format&fit=crop', emoji: '🟡', tags: ['6 Pcs', 'Veg'], isVeg: true, isCustomisable: true),
  ],

  // ══════ CHILLED DRINKS ════════════════════════════════════════════════════
  'CHILLED DRINKS': [
    _CatProduct(id: 'cd1', name: 'Strawberry Lemonade', description: 'Sweet and tart strawberry lemonade', price: 99, calories: 145, rating: 4.7, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1570696516188-ade861b84a49?q=80&w=400&auto=format&fit=crop', emoji: '🍓', tags: ['450 mL'], isVeg: true, isNew: true),
    _CatProduct(id: 'cd2', name: 'Sweet Lassi', description: 'Chilled creamy yogurt lassi', price: 99, calories: 210, rating: 4.6, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=400&auto=format&fit=crop', emoji: '🥛', tags: ['450 mL'], isVeg: true, isNew: true),
    _CatProduct(id: 'cd3', name: 'Classic Cold Coffee', description: 'Rich blended cold coffee with ice cream', price: 169, calories: 280, rating: 4.8, reviewCount: 1023, imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?q=80&w=400&auto=format&fit=crop', emoji: '☕', tags: ['450 mL'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'cd4', name: 'Mango Lassi', description: 'Thick creamy mango and yogurt blend', price: 119, calories: 235, rating: 4.7, reviewCount: 812, imageUrl: 'https://images.unsplash.com/photo-1528825871115-3581a5387919?q=80&w=400&auto=format&fit=crop', emoji: '🥭', tags: ['450 mL'], isVeg: true, isBestseller: true, isTopSelling: true),
    _CatProduct(id: 'cd5', name: 'Rose Milk', description: 'Chilled milk with aromatic rose syrup', price: 89, calories: 180, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?q=80&w=400&auto=format&fit=crop', emoji: '🌹', tags: ['400 mL'], isVeg: true),
    _CatProduct(id: 'cd6', name: 'Watermelon Juice', description: 'Freshly squeezed watermelon — no water added', price: 99, calories: 85, rating: 4.6, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?q=80&w=400&auto=format&fit=crop', emoji: '🍉', tags: ['400 mL'], isVeg: true, isHighDemand: true),
    _CatProduct(id: 'cd7', name: 'Kala Khatta Shikanji', description: 'Tangy tamarind and black salt refresher', price: 89, calories: 95, rating: 4.4, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?q=80&w=400&auto=format&fit=crop', emoji: '🍋', tags: ['400 mL'], isVeg: true),
    _CatProduct(id: 'cd8', name: 'Blue Pea Lemonade', description: 'Butterfly pea flower colour-changing lemonade', price: 129, calories: 110, rating: 4.8, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?q=80&w=400&auto=format&fit=crop', emoji: '💙', tags: ['400 mL'], isVeg: true, isBestseller: true, isNew: true),
    _CatProduct(id: 'cd9', name: 'Masala Chaas', description: 'Spiced buttermilk with roasted cumin and mint', price: 79, calories: 75, rating: 4.5, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=400&auto=format&fit=crop', emoji: '🥛', tags: ['400 mL'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'cd10', name: 'Coconut Water', description: 'Fresh packaged tender coconut water', price: 89, calories: 65, rating: 4.6, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1526318896980-cf78c088247c?q=80&w=400&auto=format&fit=crop', emoji: '🥥', tags: ['350 mL'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'cd11', name: 'Mint Mojito', description: 'Virgin mojito with fresh mint and lime fizz', price: 119, calories: 120, rating: 4.7, reviewCount: 456, imageUrl: 'https://images.unsplash.com/photo-1570696516188-ade861b84a49?q=80&w=400&auto=format&fit=crop', emoji: '🌿', tags: ['450 mL'], isVeg: true, isHighDemand: true),
    _CatProduct(id: 'cd12', name: 'Oreo Shake', description: 'Thick milkshake blended with Oreo cookies', price: 179, calories: 380, rating: 4.7, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?q=80&w=400&auto=format&fit=crop', emoji: '🍪', tags: ['450 mL'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'cd13', name: 'Aam Panna', description: 'Raw mango summer cooler with spices', price: 89, calories: 95, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1528825871115-3581a5387919?q=80&w=400&auto=format&fit=crop', emoji: '🥭', tags: ['400 mL'], isVeg: true),
    _CatProduct(id: 'cd14', name: 'Filter Coffee', description: 'South Indian drip filter coffee with frothy milk', price: 89, calories: 110, rating: 4.8, reviewCount: 823, imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?q=80&w=400&auto=format&fit=crop', emoji: '☕', tags: ['250 mL'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'cd15', name: 'Jaljeera', description: 'Tangy cumin-spiced refreshing drink', price: 69, calories: 55, rating: 4.4, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?q=80&w=400&auto=format&fit=crop', emoji: '🫗', tags: ['350 mL'], isVeg: true),
    _CatProduct(id: 'cd16', name: 'Banana Shake', description: 'Thick creamy banana milkshake', price: 139, calories: 290, rating: 4.6, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1528825871115-3581a5387919?q=80&w=400&auto=format&fit=crop', emoji: '🍌', tags: ['450 mL'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'cd17', name: 'Virgin Pina Colada', description: 'Creamy coconut and pineapple tropical blend', price: 149, calories: 225, rating: 4.6, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?q=80&w=400&auto=format&fit=crop', emoji: '🍍', tags: ['450 mL'], isVeg: true, isNew: true),
    _CatProduct(id: 'cd18', name: 'Spicy Masala Chai', description: 'Strong ginger-cardamom masala tea', price: 69, calories: 95, rating: 4.7, reviewCount: 1123, imageUrl: 'https://images.unsplash.com/photo-1561336313-0bd5e0b27ec8?q=80&w=400&auto=format&fit=crop', emoji: '🍵', tags: ['200 mL'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'cd19', name: 'Bael Sharbat', description: 'Wood apple cooler — traditional summer drink', price: 89, calories: 120, rating: 4.5, reviewCount: 178, imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?q=80&w=400&auto=format&fit=crop', emoji: '🍊', tags: ['400 mL'], isVeg: true),
    _CatProduct(id: 'cd20', name: 'Thandai', description: 'Chilled milk with nuts, rose and saffron blend', price: 129, calories: 245, rating: 4.7, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=400&auto=format&fit=crop', emoji: '🌸', tags: ['400 mL'], isVeg: true, isTopSelling: true),
  ],

  // ══════ SANDWICHES & WRAPS ════════════════════════════════════════════════
  'SANDWICHES & WRAPS': [
    _CatProduct(id: 'sw1', name: 'Grilled Paneer Club Sandwich', description: 'Paneer club sandwich, served fresh in 4 slices', price: 219, calories: 420, rating: 4.7, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?q=80&w=400&auto=format&fit=crop', emoji: '🥪', tags: ['Serves 1', 'Pure Paneer'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'sw2', name: 'Grilled Chicken Club Sandwich', description: 'Chicken club sandwich, served fresh in 4 slices', price: 259, calories: 480, rating: 4.8, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1512152272829-e3139592d56f?q=80&w=400&auto=format&fit=crop', emoji: '🥪', tags: ['Serves 1', 'High Protein'], isVeg: false, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'sw3', name: 'Bombay Vada Pav', description: 'Spicy potato vada in soft bun with chutneys', price: 79, calories: 310, rating: 4.7, reviewCount: 912, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🍔', tags: ['Serves 1'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'sw4', name: 'Veg Cheese Wrap', description: 'Tortilla wrap with grilled veggies and cheese', price: 199, calories: 390, rating: 4.5, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'sw5', name: 'Chicken Kathi Roll', description: 'Spiced chicken wrapped in flaky paratha', price: 229, calories: 450, rating: 4.8, reviewCount: 734, imageUrl: 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1'], isVeg: false, isBestseller: true, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'sw6', name: 'Veggie Sub', description: 'Fresh sub loaded with veggies, cheese and sauces', price: 189, calories: 370, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?q=80&w=400&auto=format&fit=crop', emoji: '🥖', tags: ['Serves 1'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'sw7', name: 'Egg Mayo Sandwich', description: 'Soft bread with egg mayo filling and veggies', price: 149, calories: 330, rating: 4.5, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1481070414801-51fd732d7184?q=80&w=400&auto=format&fit=crop', emoji: '🥚', tags: ['Serves 1'], isVeg: false),
    _CatProduct(id: 'sw8', name: 'Masala Dosa Wrap', description: 'Dosa rolled with spiced potato filling — fusion style', price: 169, calories: 360, rating: 4.6, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1', 'Fusion'], isVeg: true, isNew: true),
    _CatProduct(id: 'sw9', name: 'BLT Sandwich', description: 'Bacon, lettuce and tomato on toasted bread', price: 239, calories: 415, rating: 4.6, reviewCount: 345, imageUrl: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?q=80&w=400&auto=format&fit=crop', emoji: '🥪', tags: ['Serves 1'], isVeg: false, isCustomisable: true),
    _CatProduct(id: 'sw10', name: 'Shawarma Wrap', description: 'Middle eastern style wrap with seasoned meat & garlic sauce', price: 249, calories: 490, rating: 4.8, reviewCount: 823, imageUrl: 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1'], isVeg: false, isBestseller: true, isTopSelling: true),
    _CatProduct(id: 'sw11', name: 'Hummus Veggie Wrap', description: 'Whole wheat wrap with hummus and grilled veggies', price: 199, calories: 355, rating: 4.6, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?q=80&w=400&auto=format&fit=crop', emoji: '🫓', tags: ['Serves 1', 'Healthy'], isVeg: true, isNew: true),
    _CatProduct(id: 'sw12', name: 'Corn & Cheese Toastie', description: 'Crunchy toasted sandwich with corn and cheese filling', price: 169, calories: 345, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1481070414801-51fd732d7184?q=80&w=400&auto=format&fit=crop', emoji: '🫓', tags: ['Serves 1'], isVeg: true, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'sw13', name: 'Paneer Kathi Roll', description: 'Grilled paneer cubes in spiced paratha roll', price: 209, calories: 430, rating: 4.7, reviewCount: 467, imageUrl: 'https://images.unsplash.com/photo-1596560548464-f010549b84d7?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1', 'Pure Paneer'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'sw14', name: 'Veggie Burger', description: 'Crispy veggie patty in a toasted sesame bun', price: 179, calories: 380, rating: 4.6, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=400&auto=format&fit=crop', emoji: '🍔', tags: ['Serves 1'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'sw15', name: 'Chicken Tikka Wrap', description: 'Marinated chicken tikka in mint chutney wrap', price: 239, calories: 465, rating: 4.8, reviewCount: 689, imageUrl: 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1', 'Spicy'], isVeg: false, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'sw16', name: 'Club Sandwich', description: 'Triple decker club with layers of filling', price: 229, calories: 445, rating: 4.6, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1512152272829-e3139592d56f?q=80&w=400&auto=format&fit=crop', emoji: '🥪', tags: ['Serves 1'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'sw17', name: 'Falafel Wrap', description: 'Crispy falafel with tahini and salad in pita wrap', price: 219, calories: 385, rating: 4.7, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1', 'Vegan'], isVeg: true, isNew: true),
    _CatProduct(id: 'sw18', name: 'Mumbai Pav Bhaji Sandwich', description: 'Pav bhaji filling sandwiched in butter toasted bread', price: 159, calories: 420, rating: 4.7, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?q=80&w=400&auto=format&fit=crop', emoji: '🥪', tags: ['Serves 1', 'Mumbai Style'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'sw19', name: 'Caesar Wrap', description: 'Grilled chicken, romaine, parmesan in a tortilla wrap', price: 229, calories: 410, rating: 4.6, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?q=80&w=400&auto=format&fit=crop', emoji: '🌯', tags: ['Serves 1'], isVeg: false, isCustomisable: true),
    _CatProduct(id: 'sw20', name: 'Mushroom Swiss Melt', description: 'Toasted sandwich with sautéed mushrooms and Swiss cheese', price: 209, calories: 390, rating: 4.7, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1481070414801-51fd732d7184?q=80&w=400&auto=format&fit=crop', emoji: '🍄', tags: ['Serves 1'], isVeg: true, isBestseller: true, isNew: true),
  ],

  // ══════ SWEET TOOTHS ══════════════════════════════════════════════════════
  'SWEET TOOTHS': [
    _CatProduct(id: 'st1', name: 'Dark Chocolate Dessert Jar', description: 'Deep, dark chocolate cake with a nutty crunch', price: 149, calories: 380, rating: 4.8, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=400&auto=format&fit=crop', emoji: '🍫', tags: ['Serves 1', 'Gourmet'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'st2', name: 'Kunafa Chocolate Jar', description: '[Fusion dessert] Kunafa and chocolate in a jar', price: 189, calories: 420, rating: 4.7, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=400&auto=format&fit=crop', emoji: '🍮', tags: ['Serves 1', 'Gourmet'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'st3', name: 'Gulab Jamun', description: 'Soft milk dumplings soaked in rose syrup — 3 pieces', price: 99, calories: 295, rating: 4.8, reviewCount: 1023, imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=400&auto=format&fit=crop', emoji: '🟤', tags: ['3 Pcs'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'st4', name: 'Rasmalai', description: 'Soft cottage cheese dumplings in chilled saffron milk', price: 149, calories: 310, rating: 4.7, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?q=80&w=400&auto=format&fit=crop', emoji: '🍮', tags: ['2 Pcs'], isVeg: true, isBestseller: true, isTopSelling: true),
    _CatProduct(id: 'st5', name: 'Brownie with Ice Cream', description: 'Warm fudgy brownie topped with vanilla ice cream', price: 199, calories: 450, rating: 4.8, reviewCount: 823, imageUrl: 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?q=80&w=400&auto=format&fit=crop', emoji: '🍫', tags: ['Serves 1'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'st6', name: 'Mango Kulfi', description: 'Authentic creamy mango ice cream on a stick', price: 109, calories: 195, rating: 4.6, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=400&auto=format&fit=crop', emoji: '🥭', tags: ['1 Pc'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'st7', name: 'Phirni', description: 'Chilled ground rice pudding with cardamom and nuts', price: 129, calories: 270, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=400&auto=format&fit=crop', emoji: '🍚', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'st8', name: 'Red Velvet Jar', description: 'Layers of red velvet cake and cream cheese in a jar', price: 169, calories: 395, rating: 4.7, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?q=80&w=400&auto=format&fit=crop', emoji: '❤️', tags: ['Serves 1', 'Gourmet'], isVeg: true, isNew: true),
    _CatProduct(id: 'st9', name: 'Gajar Ka Halwa', description: 'Traditional carrot dessert with ghee and cashews', price: 139, calories: 340, rating: 4.7, reviewCount: 623, imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=400&auto=format&fit=crop', emoji: '🥕', tags: ['Serves 1'], isVeg: true, isBestseller: true),
    _CatProduct(id: 'st10', name: 'Cheesecake Jar', description: 'New York style no-bake cheesecake in a jar', price: 179, calories: 410, rating: 4.7, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=400&auto=format&fit=crop', emoji: '🎂', tags: ['Serves 1', 'Gourmet'], isVeg: true, isHighDemand: true),
    _CatProduct(id: 'st11', name: 'Kheer', description: 'Creamy rice pudding with cardamom and raisins', price: 109, calories: 255, rating: 4.5, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?q=80&w=400&auto=format&fit=crop', emoji: '🍚', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'st12', name: 'Malpua', description: 'Fried sweet pancakes soaked in sugar syrup', price: 129, calories: 365, rating: 4.6, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?q=80&w=400&auto=format&fit=crop', emoji: '🥞', tags: ['3 Pcs'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'st13', name: 'Tiramisu Jar', description: 'Italian coffee dessert layered in a jar', price: 189, calories: 380, rating: 4.8, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=400&auto=format&fit=crop', emoji: '☕', tags: ['Serves 1', 'Italian'], isVeg: true, isNew: true),
    _CatProduct(id: 'st14', name: 'Jalebi', description: 'Crispy spiral sweets soaked in sugar syrup', price: 89, calories: 245, rating: 4.6, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🌀', tags: ['4 Pcs'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'st15', name: 'Basundi', description: 'Condensed milk dessert with saffron and pistachios', price: 149, calories: 310, rating: 4.5, reviewCount: 198, imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=400&auto=format&fit=crop', emoji: '🥛', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'st16', name: 'Chocolate Mousse', description: 'Light and airy dark chocolate mousse', price: 159, calories: 295, rating: 4.7, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1557003237-891a4f0c3539?q=80&w=400&auto=format&fit=crop', emoji: '🍫', tags: ['Serves 1'], isVeg: true, isNew: true),
    _CatProduct(id: 'st17', name: 'Boondi Ladoo', description: 'Traditional gram flour sweet balls — 3 pieces', price: 99, calories: 280, rating: 4.5, reviewCount: 423, imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=400&auto=format&fit=crop', emoji: '🟠', tags: ['3 Pcs'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'st18', name: 'Ice Cream Sundae', description: 'Three scoops with hot fudge and whipped cream', price: 199, calories: 440, rating: 4.7, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=400&auto=format&fit=crop', emoji: '🍨', tags: ['Serves 1'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'st19', name: 'Coconut Barfi', description: 'Desiccated coconut fudge with cardamom', price: 109, calories: 250, rating: 4.4, reviewCount: 189, imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=400&auto=format&fit=crop', emoji: '🥥', tags: ['4 Pcs'], isVeg: true),
    _CatProduct(id: 'st20', name: 'Lychee Panna Cotta', description: 'Silky Italian dessert with lychee jelly topping', price: 169, calories: 265, rating: 4.7, reviewCount: 178, imageUrl: 'https://images.unsplash.com/photo-1586985289688-ca3cf47d3e6e?q=80&w=400&auto=format&fit=crop', emoji: '🍈', tags: ['Serves 1', 'Fusion'], isVeg: true, isNew: true),
  ],

  // ══════ MAGGI MANIA ═══════════════════════════════════════════════════════
  'MAGGI MANIA': [
    _CatProduct(id: 'mm1', name: 'Classic Masala Maggi', description: 'Original maggi noodles with butter and masala', price: 89, calories: 295, rating: 4.7, reviewCount: 1023, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍜', tags: ['Serves 1'], isVeg: true, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'mm2', name: 'Cheese Maggi', description: 'Creamy maggi loaded with melted processed cheese', price: 119, calories: 375, rating: 4.8, reviewCount: 789, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🧀', tags: ['Serves 1', 'Cheese'], isVeg: true, isBestseller: true, isTopSelling: true),
    _CatProduct(id: 'mm3', name: 'Veg Maggi', description: 'Maggi with fresh chopped vegetables and spices', price: 109, calories: 310, rating: 4.6, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🥦', tags: ['Serves 1', 'Loaded Veggies'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'mm4', name: 'Egg Maggi', description: 'Masala maggi topped with a soft boiled egg', price: 129, calories: 390, rating: 4.7, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🥚', tags: ['Serves 1', '1 Egg'], isVeg: false, isBestseller: true),
    _CatProduct(id: 'mm5', name: 'Spicy Schezwan Maggi', description: 'Fiery maggi tossed in schezwan sauce and veggies', price: 129, calories: 340, rating: 4.7, reviewCount: 734, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🌶️', tags: ['Serves 1', 'Extra Spicy'], isVeg: true, isHighDemand: true, isCustomisable: true),
    _CatProduct(id: 'mm6', name: 'Butter Maggi', description: 'Simple maggi with loads of butter and seasoning', price: 99, calories: 335, rating: 4.5, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🧈', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'mm7', name: 'Peri Peri Maggi', description: 'Maggi tossed with peri peri spice and corn', price: 119, calories: 320, rating: 4.6, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🌽', tags: ['Serves 1', 'Crispy'], isVeg: true, isNew: true),
    _CatProduct(id: 'mm8', name: 'Chicken Maggi', description: 'Maggi with tender chicken shreds and spices', price: 159, calories: 425, rating: 4.8, reviewCount: 567, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍗', tags: ['Serves 1', 'Non Veg'], isVeg: false, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'mm9', name: 'Maggi Omelette', description: 'Maggi cooked inside a fluffy egg omelette', price: 149, calories: 395, rating: 4.6, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍳', tags: ['Serves 1', 'Fusion'], isVeg: false, isNew: true),
    _CatProduct(id: 'mm10', name: 'Tomato Maggi', description: 'Tangy tomato-based maggi with fresh tomatoes', price: 99, calories: 290, rating: 4.4, reviewCount: 234, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍅', tags: ['Serves 1'], isVeg: true),
    _CatProduct(id: 'mm11', name: 'Corn Chaat', description: 'Healthy snack made from fresh sweet corns', price: 119, calories: 190, rating: 4.7, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?q=80&w=400&auto=format&fit=crop', emoji: '🌽', tags: ['Serves 1'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'mm12', name: 'Pav Bhaji', description: 'Mumbai special mashed bhaji with 4 soft buns', price: 149, calories: 380, rating: 4.8, reviewCount: 678, imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?q=80&w=400&auto=format&fit=crop', emoji: '🍞', tags: ['Serves 1'], isVeg: true, isBestseller: true, isCustomisable: true),
    _CatProduct(id: 'mm13', name: 'Paneer Maggi', description: 'Maggi with grilled paneer cubes and spices', price: 149, calories: 405, rating: 4.6, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🧀', tags: ['Serves 1', 'Protein'], isVeg: true, isCustomisable: true),
    _CatProduct(id: 'mm14', name: 'Pizza Maggi', description: 'Maggi topped with pizza sauce, corn and cheese', price: 159, calories: 430, rating: 4.5, reviewCount: 198, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍕', tags: ['Serves 1', 'Fusion'], isVeg: true, isNew: true),
    _CatProduct(id: 'mm15', name: 'Hakka Noodles — Veg', description: 'Stir-fried hakka noodles with vegetables in dark sauce', price: 149, calories: 355, rating: 4.6, reviewCount: 445, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🥢', tags: ['Serves 1'], isVeg: true, isTopSelling: true),
    _CatProduct(id: 'mm16', name: 'Hakka Noodles — Chicken', description: 'Stir-fried hakka noodles with chicken and sauces', price: 189, calories: 420, rating: 4.7, reviewCount: 534, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🥢', tags: ['Serves 1', 'Non Veg'], isVeg: false, isBestseller: true, isHighDemand: true),
    _CatProduct(id: 'mm17', name: 'Pad Thai Noodles', description: 'Thai-style rice noodles with egg, peanuts and sauce', price: 199, calories: 415, rating: 4.7, reviewCount: 312, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🌟', tags: ['Serves 1', 'Thai'], isVeg: false, isNew: true),
    _CatProduct(id: 'mm18', name: 'Singapore Noodles', description: 'Thin rice noodles with curry powder and veggies', price: 179, calories: 370, rating: 4.5, reviewCount: 189, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍜', tags: ['Serves 1', 'Fusion'], isVeg: true),
    _CatProduct(id: 'mm19', name: 'Ramen Bowl', description: 'Japanese-style ramen with rich broth and toppings', price: 229, calories: 460, rating: 4.8, reviewCount: 267, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🍜', tags: ['Serves 1', 'Japanese'], isVeg: false, isBestseller: true, isNew: true),
    _CatProduct(id: 'mm20', name: 'Manchurian Noodles', description: 'Veg manchurian gravy tossed with hakka noodles', price: 179, calories: 390, rating: 4.6, reviewCount: 389, imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=400&auto=format&fit=crop', emoji: '🥢', tags: ['Serves 1', 'Combo'], isVeg: true, isTopSelling: true, isCustomisable: true),
  ],
};

// Helper to pick product list for a given banner
List<_CatProduct> _getProducts(CategoryBannerData banner) {
  // Map banner title → key
  final title = '${banner.titleLine1} ${banner.titleLine2}'.toUpperCase();
  if (title.contains('HEARTY') || title.contains('BREAKFAST')) return _categoryProducts['HEARTY BREAKFAST']!;
  if (title.contains('DELHI') || title.contains('CHAAT')) return _categoryProducts['DELHI-STYLE CHAATS']!;
  if (title.contains('CRISPY') || title.contains('BITES')) return _categoryProducts['CRISPY BITES']!;
  if (title.contains('CHILLED') || title.contains('DRINK')) return _categoryProducts['CHILLED DRINKS']!;
  if (title.contains('SANDWICH') || title.contains('WRAP')) return _categoryProducts['SANDWICHES & WRAPS']!;
  if (title.contains('SWEET')) return _categoryProducts['SWEET TOOTHS']!;
  if (title.contains('MAGGI')) return _categoryProducts['MAGGI MANIA']!;
  return _categoryProducts['CRISPY BITES']!;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CategoryDetailScreen extends StatefulWidget {
  final CategoryBannerData banner;

  const CategoryDetailScreen({super.key, required this.banner});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final products = _getProducts(widget.banner);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero Banner ──────────────────────────────────────────────────
            _HeroBanner(banner: widget.banner, ws: ws, hs: hs),

            // ── Product grid ─────────────────────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(12 * ws, 12 * hs, 12 * ws, 0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12 * ws,
                        mainAxisSpacing: 12 * hs,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _ProductCard(
                          product: products[i],
                          ws: ws, hs: hs,
                        ),
                        childCount: products.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _OfferBanner(ws: ws, hs: hs),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: 80 * hs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // View Cart FAB
      floatingActionButton: provider.cartItemCount > 0
          ? _ViewCartFAB(
        itemCount: provider.cartItemCount,
        total: provider.cartTotal,
        ws: ws, hs: hs,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CartScreen())),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final CategoryBannerData banner;
  final double ws, hs;

  const _HeroBanner({required this.banner, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200 * hs,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-width background image
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: banner.bgColor),
          ),

          // Dark gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.60),
                    Colors.black.withOpacity(0.40),
                    Colors.black.withOpacity(0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Color tint overlay from bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    banner.bgColor.withOpacity(0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 12 * hs,
            left: 12 * ws,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: _CircleBtn(ws: ws, icon: Icons.chevron_left_rounded),
            ),
          ),

          // Title
          Positioned(
            left: 16 * ws,
            bottom: 22 * hs,
            right: 60 * ws,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  banner.titleLine1,
                  style: TextStyle(
                    fontSize: 32 * ws, fontWeight: FontWeight.w900,
                    color: Colors.white, fontFamily: 'Poppins',
                    height: 1.0, letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                ),
                Text(
                  banner.titleLine2,
                  style: TextStyle(
                    fontSize: 32 * ws, fontWeight: FontWeight.w900,
                    color: Colors.white, fontFamily: 'Poppins',
                    height: 1.05, letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                ),
                SizedBox(height: 5 * hs),
                Text(
                  banner.tagline,
                  style: TextStyle(
                    fontSize: 10 * ws,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'Poppins', fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // ── U-curve at bottom: white bump rises up from centre ──────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(double.infinity, 36 * hs),
              painter: _UCurvePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── U-Curve Painter ─────────────────────────────────────────────────────────
// Paints a white ∪ shape: low at both sides, bulges UP in the centre,
// so the white grid below appears to push into the hero image.

class _UCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    // Start bottom-left, curve UP to centre top, back down to bottom-right
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2, 0,       // control point: top centre (peak of U)
      size.width, size.height, // end: bottom-right
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleBtn extends StatelessWidget {
  final double ws;
  final IconData icon;
  const _CircleBtn({required this.ws, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34 * ws, height: 34 * ws,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
      ),
      child: Icon(icon, size: 18 * ws, color: const Color(0xFF0F172A)),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final _CatProduct product;
  final double ws, hs;

  const _ProductCard({required this.product, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final menuItem = product.toMenuItem();
    final cartCount = provider.cartItems
        .where((c) => c.menuItem.id == product.id)
        .fold(0, (sum, c) => sum + c.quantity);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            args: ProductDetailArgs(
              menuItem: menuItem,
              weight: product.tags.isNotEmpty ? product.tags.first : 'Serves 1',
              originalPrice: null,
              isBestseller: product.isBestseller,
              aboutProduct: '${product.name} — ${product.description}. '
                  'Made fresh to order with high-quality ingredients. '
                  'A perfect choice for a healthy, satisfying snack.',
              otherInfo: {
                'Calories': '${product.calories} kcal',
                'Rating': '${product.rating} ⭐ (${product.reviewCount} reviews)',
                'Tags': product.tags.join(', '),
                'Type': product.isVeg ? 'Vegetarian' : 'Non-Vegetarian',
              },
            ),
          ),
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * ws),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ────────────────────────────────────────────────
            Expanded(
              flex: 56,
              child: Stack(
                children: [
                  // Food image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16 * ws)),
                    child: _FoodImage(url: product.imageUrl, fallback: product.emoji),
                  ),

                  // Bestseller badge
                  if (product.isBestseller)
                    Positioned(
                      top: 6 * hs, left: 6 * ws,
                      child: _Badge(label: '★ Bestseller', bg: AppTheme.primaryGreen, ws: ws, hs: hs),
                    )
                  else if (product.isNew)
                    Positioned(
                      top: 6 * hs, left: 6 * ws,
                      child: _Badge(label: '+ New', bg: const Color(0xFFEC4899), ws: ws, hs: hs),
                    ),

                  // Customise label above add button
                  if (product.isCustomisable)
                    Positioned(
                      bottom: 28 * hs, right: 6 * ws,
                      child: Text(
                        'Customise',
                        style: TextStyle(
                          fontSize: 7.5 * ws, color: Colors.white,
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ),

                  // Add / stepper bottom-right
                  Positioned(
                    bottom: 6 * hs, right: 6 * ws,
                    child: cartCount == 0
                        ? _AddButton(ws: ws, hs: hs, onTap: () {
                      HapticFeedback.mediumImpact();
                      provider.addToCart(menuItem);
                    })
                        : _StepperButton(
                      count: cartCount, ws: ws, hs: hs,
                      onRemove: () { HapticFeedback.lightImpact(); provider.updateQuantity(product.id, cartCount - 1); },
                      onAdd: () { HapticFeedback.lightImpact(); provider.addToCart(menuItem); },
                    ),
                  ),
                ],
              ),
            ),

            // ── Info area ─────────────────────────────────────────────────
            Expanded(
              flex: 44,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8 * ws, 6 * hs, 8 * ws, 6 * hs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Veg dot + tag chips
                    _TagsRow(product: product, ws: ws, hs: hs),
                    SizedBox(height: 3 * hs),

                    // Name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13 * ws, fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A), fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2 * hs),

                    // Description
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 10 * ws, color: const Color(0xFF94A3B8),
                        fontFamily: 'Poppins', height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // High Demand / Top-Selling label
                    if (product.isHighDemand || product.isTopSelling) ...[
                      SizedBox(height: 3 * hs),
                      Row(
                        children: [
                          Icon(
                            product.isHighDemand ? Icons.local_fire_department_rounded : Icons.star_rounded,
                            size: 9 * ws,
                            color: AppTheme.orange,
                          ),
                          SizedBox(width: 2 * ws),
                          Text(
                            product.isHighDemand ? 'High Demand' : 'Top-Selling in Indiranagar',
                            style: TextStyle(
                              fontSize: 8.5 * ws, color: AppTheme.orange,
                              fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Spacer(),

                    // Price
                    Text(
                      '₹${product.price.toInt()}',
                      style: TextStyle(
                        fontSize: 15 * ws, fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A), fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tags Row ─────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  final _CatProduct product;
  final double ws, hs;

  const _TagsRow({required this.product, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Veg/non-veg dot indicator
        Container(
          width: 12 * ws, height: 12 * ws,
          decoration: BoxDecoration(
            border: Border.all(
              color: product.isVeg ? AppTheme.primaryGreen : const Color(0xFFEF4444),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(2 * ws),
          ),
          child: Center(
            child: Container(
              width: 5.5 * ws, height: 5.5 * ws,
              decoration: BoxDecoration(
                color: product.isVeg ? AppTheme.primaryGreen : const Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        SizedBox(width: 4 * ws),
        // First tag
        if (product.tags.isNotEmpty)
          _TagChip(label: product.tags.first, ws: ws, hs: hs),
        if (product.tags.length > 1) ...[
          SizedBox(width: 4 * ws),
          _TagChip(label: product.tags[1], ws: ws, hs: hs),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final double ws, hs;
  const _TagChip({required this.label, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5 * ws, vertical: 1.5 * hs),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4 * ws),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8 * ws, color: const Color(0xFF64748B),
          fontFamily: 'Poppins', fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final double ws, hs;
  const _Badge({required this.label, required this.bg, required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * ws, vertical: 3 * hs),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6 * ws)),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white, fontSize: 8 * ws,
          fontWeight: FontWeight.w700, fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final double ws, hs;
  final VoidCallback onTap;
  const _AddButton({required this.ws, required this.hs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 7 * hs),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(10 * ws),
          boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.40), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 14 * ws),
            SizedBox(width: 3 * ws),
            Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12 * ws, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

// ─── Stepper Button ───────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final int count;
  final double ws, hs;
  final VoidCallback onRemove, onAdd;
  const _StepperButton({required this.count, required this.ws, required this.hs, required this.onRemove, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(10 * ws),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.40), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * ws, vertical: 6 * hs),
                child: Icon(Icons.remove_rounded, size: 13 * ws, color: Colors.white),
              )),
          Text('$count', style: TextStyle(color: Colors.white, fontSize: 13 * ws, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          GestureDetector(onTap: onAdd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * ws, vertical: 6 * hs),
                child: Icon(Icons.add_rounded, size: 13 * ws, color: Colors.white),
              )),
        ],
      ),
    );
  }
}

// ─── Offer Banner ─────────────────────────────────────────────────────────────

class _OfferBanner extends StatelessWidget {
  final double ws, hs;
  const _OfferBanner({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12 * ws, 14 * hs, 12 * ws, 0),
      padding: EdgeInsets.symmetric(horizontal: 14 * ws, vertical: 10 * hs),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10 * ws),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32 * ws, height: 32 * ws,
            decoration: BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
            child: Center(child: Text('🎁', style: TextStyle(fontSize: 15 * ws))),
          ),
          SizedBox(width: 10 * ws),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('50% upto ₹150 off',
                    style: TextStyle(fontSize: 12 * ws, fontWeight: FontWeight.w800, color: const Color(0xFF065F46), fontFamily: 'Poppins')),
                Text('USE TRY50 | ABOVE ₹99',
                    style: TextStyle(fontSize: 10 * ws, color: const Color(0xFF6B7280), fontFamily: 'Poppins', fontWeight: FontWeight.w500, letterSpacing: 0.5)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 12 * ws, color: AppTheme.primaryGreen),
        ],
      ),
    );
  }
}

// ─── View Cart FAB ────────────────────────────────────────────────────────────

class _ViewCartFAB extends StatelessWidget {
  final int itemCount;
  final double total, ws, hs;
  final VoidCallback onTap;

  const _ViewCartFAB({required this.itemCount, required this.total, required this.ws, required this.hs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20 * ws, vertical: 14 * hs),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(14 * ws),
          boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22 * ws, height: 22 * ws,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
              child: Center(child: Text('$itemCount', style: TextStyle(color: Colors.white, fontSize: 10 * ws, fontWeight: FontWeight.w800, fontFamily: 'Poppins'))),
            ),
            SizedBox(width: 10 * ws),
            Text('View Cart', style: TextStyle(color: Colors.white, fontSize: 13 * ws, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            SizedBox(width: 10 * ws),
            Text('₹${total.toInt()}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12 * ws, fontFamily: 'Poppins')),
            SizedBox(width: 8 * ws),
            Icon(Icons.arrow_forward_ios_rounded, size: 12 * ws, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── Food Image ───────────────────────────────────────────────────────────────

class _FoodImage extends StatelessWidget {
  final String url;
  final String fallback;
  const _FoodImage({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: double.infinity, height: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: double.infinity, height: double.infinity, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: double.infinity, height: double.infinity,
    color: const Color(0xFFF0FDF4),
    child: Center(child: Text(fallback, style: const TextStyle(fontSize: 36))),
  );
}
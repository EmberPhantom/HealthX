import MenuItem from '../models/MenuItem';
import MealPlan from '../models/MealPlan';
import Category from '../models/Category';
import Banner from '../models/Banner';
import { connectDB, disconnectDB } from '../config/db';
import logger from '../utils/logger';

const seedData = async () => {
  try {
    await connectDB();

    logger.info('Clearing existing content collections...');
    await Category.deleteMany({});
    await Banner.deleteMany({});
    await MealPlan.deleteMany({});
    await MenuItem.deleteMany({});

    logger.info('Seeding Categories...');
    const categories = await Category.insertMany([
      { name: 'Healthy Bowls', emoji: '🥣' },
      { name: 'Protein Meals', emoji: '💪' },
      { name: 'Salads', emoji: '🥗' },
      { name: 'Smoothies', emoji: '🥤' },
      { name: 'Keto', emoji: '🥑' },
      { name: 'Ready to Eat', emoji: '🍬' },
    ]);
    logger.info(`Seeded ${categories.length} categories.`);

    logger.info('Seeding Banners...');
    const banners = await Banner.insertMany([
      {
        imagePath: 'assets/images/bg_healthy_Bowl_home.png',
        title: 'Healthy Bowl',
        subtitle: 'High Protein Salad',
        chipLabel: '230 Cal',
      },
      {
        imagePath: 'assets/images/banner_2.png',
        title: 'Gym Bowl',
        subtitle: 'Power-Packed Fuel',
        chipLabel: '310 Cal',
      },
      {
        imagePath: 'assets/images/banner_3.png',
        title: 'Diabetic Care',
        subtitle: 'Low Glycemic Meal',
        chipLabel: '180 Cal',
      },
      {
        imagePath: 'assets/images/banner_3.png',
        title: 'Corporate Bowl',
        subtitle: 'Bulk Meal Delivery',
        chipLabel: '200 Cal',
      },
    ]);
    logger.info(`Seeded ${banners.length} banners.`);

    logger.info('Seeding Meal Plans...');
    const plans = await MealPlan.insertMany([
      {
        planName: 'HealthyBowl',
        price: '₹499',
        priceSuffix: '/week',
        subtitle: 'Balanced Nutrition Daily',
        badgeLabel: '⭐ Popular',
        accentColor: '0xFF059669',
        btnColor: '0xFF059669',
        isFeatured: true,
        tagIcon: 'eco_rounded',
        cardBgColor: '0xFFECFDF5',
        assetImagePath: 'assets/images/bg_weekly_plan.png',
        destination: 'healthy_bowl',
      },
      {
        planName: 'Protein Bowl',
        price: '₹1,799',
        priceSuffix: '/month',
        subtitle: 'High-Protein Power Fuel',
        badgeLabel: null,
        accentColor: '0xFFE07B00',
        btnColor: '0xFF059669',
        isFeatured: false,
        tagIcon: 'fitness_center_rounded',
        cardBgColor: '0xFFFFF7ED',
        assetImagePath: 'assets/images/bg_monthly_plan.png',
        destination: 'zym_bowl',
      },
      {
        planName: 'Diabetic Care Bowl',
        price: '₹299',
        priceSuffix: '/meal',
        subtitle: 'Low Glycemic · Doctor Approved',
        badgeLabel: null,
        accentColor: '0xFF0284C7',
        btnColor: '0xFF059669',
        isFeatured: false,
        tagIcon: 'favorite_rounded',
        cardBgColor: '0xFFEFF6FF',
        assetImagePath: 'assets/images/bg_custom_plan.png',
        destination: 'diabetic_care',
      },
      {
        planName: 'Corporate Tie-Up Bowl',
        price: '₹999',
        priceSuffix: '/month',
        subtitle: 'Team Plans · Bulk Savings',
        badgeLabel: null,
        accentColor: '0xFF7C3AED',
        btnColor: '0xFF059669',
        isFeatured: false,
        tagIcon: 'business_center_rounded',
        cardBgColor: '0xFFF5F3FF',
        assetImagePath: 'assets/images/corporate_tie_up.png',
        destination: 'corporate_tie_up_bowl',
      },
    ]);
    logger.info(`Seeded ${plans.length} meal plans.`);

    logger.info('Seeding Menu Items...');
    const menuItems = await MenuItem.insertMany([
      // Regular Items
      {
        name: 'Mediterranean Bowl',
        description: 'Grilled chicken, quinoa, organic hummus, cherry tomatoes, cucumbers, and tahini dressing.',
        price: 349,
        calories: 420,
        rating: 4.8,
        reviewCount: 124,
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
        emoji: '🥙',
        category: 'Healthy Bowls',
        type: 'Regular',
        tags: ['High Protein', 'Mediterranean', 'Fiber Rich'],
        isVeg: false,
      },
      {
        name: 'Protein Power Bowl',
        description: 'Hard-boiled eggs, grilled chicken breast, sliced avocado, brown rice, and sautéed spinach.',
        price: 399,
        calories: 520,
        rating: 4.9,
        reviewCount: 208,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop',
        emoji: '💪',
        category: 'Protein Meals',
        type: 'Regular',
        tags: ['High Protein', 'Muscle Building', 'Keto Friendly'],
        isVeg: false,
      },
      {
        name: 'Keto Steak Bowl',
        description: 'Tender beef steak strips, broccoli florets, cheddar cheese cubes, and buttered mushroom mix.',
        price: 449,
        calories: 550,
        rating: 4.9,
        reviewCount: 95,
        imageUrl: 'https://images.unsplash.com/photo-1529694157872-4e0c0f3b238b?q=80&w=400&auto=format&fit=crop',
        emoji: '🥩',
        category: 'Keto',
        type: 'Regular',
        tags: ['Keto', 'High Protein', 'Low Carb'],
        isVeg: false,
      },
      {
        name: 'Superfood Quinoa Salad',
        description: 'Organic quinoa, kale, pomegranate seeds, roasted almonds, and light lemon vinaigrette.',
        price: 299,
        calories: 310,
        rating: 4.7,
        reviewCount: 88,
        imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=400&auto=format&fit=crop',
        emoji: '🥗',
        category: 'Salads',
        type: 'Regular',
        tags: ['Superfood', 'Vegan', 'Gluten Free'],
        isVeg: true,
      },
      {
        name: 'Avocado Green Smoothie',
        description: 'Fresh avocado, baby spinach, banana, almond milk, and raw organic honey blend.',
        price: 249,
        calories: 280,
        rating: 4.6,
        reviewCount: 72,
        imageUrl: 'https://images.unsplash.com/photo-1553530979-7ee52a2670c2?q=80&w=400&auto=format&fit=crop',
        emoji: '🥤',
        category: 'Smoothies',
        type: 'Regular',
        tags: ['Antioxidant', 'Vegan Option', 'Detox'],
        isVeg: true,
      },
      // Ready to Eat Items
      {
        name: 'Happy Natural Energy Bar',
        description: 'Crunchy energy bar loaded with dry fruits (Almonds, Pistachios, Cashews) & bound with natural organic Jaggery.',
        price: 300,
        calories: 180,
        rating: 4.6,
        reviewCount: 342,
        imageUrl: 'https://images.unsplash.com/photo-1568254183919-78a4f43a2877?q=80&w=400&auto=format&fit=crop',
        emoji: '⚡',
        category: 'Ready to Eat',
        type: 'ReadyToEat',
        tags: ['No Added Sugar', 'Vegan', 'Energy Boost'],
        isVeg: true,
      },
      {
        name: 'Dry Fruit Chikki',
        description: 'Traditional Indian sweet snack made with premium crushed dry fruits and refined organic sugarcane jaggery.',
        price: 180,
        calories: 420,
        rating: 4.7,
        reviewCount: 295,
        imageUrl: 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?q=80&w=400&auto=format&fit=crop',
        emoji: '🍬',
        category: 'Ready to Eat',
        type: 'ReadyToEat',
        tags: ['Premium', 'Jaggery', 'Snack'],
        isVeg: true,
      },
      {
        name: 'Roasted Makhana (Lotus Seeds)',
        description: 'Slow-roasted foxnuts seasoned with organic pink salt and a dash of ground black pepper.',
        price: 120,
        calories: 150,
        rating: 4.8,
        reviewCount: 194,
        imageUrl: 'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?q=80&w=400&auto=format&fit=crop',
        emoji: '🍿',
        category: 'Ready to Eat',
        type: 'ReadyToEat',
        tags: ['Low Calorie', 'Gluten Free', 'Crunchy'],
        isVeg: true,
      },
    ]);
    logger.info(`Seeded ${menuItems.length} menu items.`);

    logger.info('Database seeding completed successfully!');
  } catch (error) {
    logger.error('Error seeding database:', error);
  } finally {
    await disconnectDB();
  }
};

seedData();

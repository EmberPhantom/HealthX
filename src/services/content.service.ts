import MenuItem, { IMenuItem } from '../models/MenuItem';
import MealPlan, { IMealPlan } from '../models/MealPlan';
import Category, { ICategory } from '../models/Category';
import Banner, { IBanner } from '../models/Banner';
import logger from '../utils/logger';

export interface ISubscriptionPlan {
  planId: string;
  planName: string;
  price: number;
  features: string[];
  isBestseller?: boolean;
}

export interface IRewardTask {
  taskId: string;
  title: string;
  points: number;
  target: number;
  unit: string;
}

export interface ISupportInfo {
  email: string;
  whatsapp: string;
  faqs: { question: string; answer: string }[];
}

export class ContentService {
  async getCategories(): Promise<ICategory[]> {
    let categories = await Category.find();
    if (categories.length === 0) {
      logger.info('Seeding default categories...');
      const defaultCategories = [
        { name: 'Healthy Bowls', emoji: '🥣' },
        { name: 'Protein Meals', emoji: '💪' },
        { name: 'Salads', emoji: '🥗' },
        { name: 'Smoothies', emoji: '🥤' },
        { name: 'Keto', emoji: '🥑' },
      ];
      categories = await Category.insertMany(defaultCategories);
    }
    return categories;
  }

  async getBanners(): Promise<IBanner[]> {
    let banners = await Banner.find();
    if (banners.length === 0) {
      logger.info('Seeding default banners...');
      const defaultBanners = [
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
      ];
      banners = await Banner.insertMany(defaultBanners);
    }
    return banners;
  }

  async getMealPlans(): Promise<IMealPlan[]> {
    let plans = await MealPlan.find();
    if (plans.length === 0) {
      logger.info('Seeding default meal plans...');
      const defaultPlans = [
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
      ];
      plans = await MealPlan.insertMany(defaultPlans);
    }
    return plans;
  }

  async getMenuItems(type?: string): Promise<IMenuItem[]> {
    const query = type ? { type } : {};
    let items = await MenuItem.find(query);
    if (items.length === 0 && !type) {
      logger.info('Seeding default menu items...');
      const defaultItems: any[] = [
        {
          name: 'Mediterranean Bowl',
          description: 'Grilled chicken, quinoa, hummus',
          price: 349,
          calories: 420,
          rating: 4.8,
          reviewCount: 124,
          imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
          emoji: '🥙',
          category: 'Healthy Bowls',
          type: 'Regular',
          tags: ['High Protein', 'Mediterranean'],
          isVeg: false,
        },
        {
          name: 'Protein Power Bowl',
          description: 'Eggs, chicken, avocado',
          price: 399,
          calories: 520,
          rating: 4.9,
          reviewCount: 208,
          imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop',
          emoji: '💪',
          category: 'Protein Meals',
          type: 'Regular',
          tags: ['High Protein', 'Muscle Building'],
          isVeg: false,
        },
        // ... (existing items)
        {
          name: 'Keto Steak Bowl',
          description: 'Steak strips, greens, cheese',
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
        // Ready to Eat items
        {
          name: 'Happy Natural Energy Bar',
          description: 'Almonds, Pistachios, Seeds & Jaggery — 80%+ dry fruits.',
          price: 300,
          calories: 180,
          rating: 4.6,
          reviewCount: 342,
          imageUrl: 'assets/images/energy_bar_1.png',
          emoji: '⚡',
          category: 'Ready to Eat',
          type: 'ReadyToEat',
          tags: ['No Added Sugar', 'Vegan'],
          isVeg: true,
        },
        {
          name: 'Dry Fruit Chikki',
          description: 'Premium dry fruits with jaggery.',
          price: 960,
          calories: 420,
          rating: 4.7,
          reviewCount: 295,
          imageUrl: 'assets/images/dry_fruit_chikki_1.png',
          emoji: '🍬',
          category: 'Ready to Eat',
          type: 'ReadyToEat',
          tags: ['Premium', 'Jaggery'],
          isVeg: true,
        },
      ];
      items = await MenuItem.insertMany(defaultItems) as any;
      // If we were filtering by type and just seeded, we need to filter again
      if (type) {
        items = items.filter(i => i.type === type);
      }
    }
    return items;
  }

  async getSubscriptionPlans(): Promise<ISubscriptionPlan[]> {
    return [
      {
        planId: 'basic',
        planName: 'Basic Plan',
        price: 499,
        features: [
          'Daily step and sleep log tracking',
          'Basic health analytics report',
          '1 doctor consultation per month'
        ]
      },
      {
        planId: 'pro',
        planName: 'Pro Plan',
        price: 999,
        features: [
          'Advanced glucose and metrics logging',
          'Detailed trend analysis charts',
          'Unlimited doctor consult bookings',
          'Priority support queue access'
        ],
        isBestseller: true
      },
      {
        planId: 'elite',
        planName: 'Elite Plan',
        price: 1999,
        features: [
          'Personal nutritionist and wellness coach',
          '24/7 priority emergency doctor helpline',
          'Monthly customized supplement box delivery',
          'Complete health panel reviews'
        ]
      }
    ];
  }

  async getRewardTasks(): Promise<IRewardTask[]> {
    return [
      { taskId: 'steps', title: 'Steps Goal', points: 50, target: 10000, unit: 'steps' },
      { taskId: 'sleep', title: 'Sleep Goal', points: 30, target: 420, unit: 'minutes' },
      { taskId: 'water', title: 'Water Goal', points: 20, target: 2500, unit: 'ml' }
    ];
  }

  async getSupportInfo(): Promise<ISupportInfo> {
    return {
      email: 'support@healthxworld.com',
      whatsapp: '919876543210',
      faqs: [
        {
          question: 'How do I book a doctor consultation?',
          answer: 'Go to the Consults tab, choose a doctor, select an available date and time slot, and tap Book Appointment.'
        },
        {
          question: 'Can I sync my fitness tracker?',
          answer: 'Yes, standard step counting uses native sensors and auto-syncs. Wearable device integrations can be enabled in settings.'
        },
        {
          question: 'How do I track my nutrition?',
          answer: 'Navigate to the Tracker tab, select meals, and use the Log Meal button to log your food items.'
        },
        {
          question: 'What is the refund policy for shop orders?',
          answer: 'Orders can be cancelled prior to dispatch. Refunds are processed to your original payment method within 5-7 business days.'
        }
      ]
    };
  }
}

export const contentService = new ContentService();

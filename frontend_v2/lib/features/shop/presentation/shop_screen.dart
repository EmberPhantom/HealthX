import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Widget _buildCategoryCard({
    required BuildContext context,
    required String title,
    required String imageUrl,
    bool isArrow = false,
  }) {
    if (isArrow) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIconsRegular.arrowRight,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'VIEW ALL',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required String name,
    required String size,
    required String price,
    required String imageUrl,
    bool isBestseller = false,
  }) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and badge
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (isBestseller)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: StatusBadge(
                    text: 'BESTSELLER',
                    dotColor: AppColors.secondary,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.secondary,
                  ),
                ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                ),
                Text(
                  size,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondary, width: 1.0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 18, color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        child: const Icon(
          PhosphorIconsRegular.shoppingCart,
          size: 26,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fuel your performance.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹0.00',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Featured Card Banner
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?fit=crop&w=400&h=200'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Premium Subscriptions',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      text: 'EXPLORE PLANS',
                      isFullWidth: false,
                      height: 36,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories Section
            Text(
              'CATEGORIES',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.25,
              children: [
                _buildCategoryCard(
                  context: context,
                  title: 'Daily Meals',
                  imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?fit=crop&w=150&h=100',
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'Healthy Breakfast',
                  imageUrl: 'https://images.unsplash.com/photo-1497534446932-c925b458314e?fit=crop&w=150&h=100',
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'Snacks & Treats',
                  imageUrl: 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?fit=crop&w=150&h=100',
                ),
                _buildCategoryCard(
                  context: context,
                  title: 'View All',
                  imageUrl: '',
                  isArrow: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trending Now Section
            Text(
              'TRENDING NOW',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildProductCard(
                    context: context,
                    name: 'Whey Isolate Pro',
                    size: '30 Servings',
                    price: '₹2,499',
                    imageUrl: 'https://images.unsplash.com/photo-1579758629938-03607ccdbaba?fit=crop&w=150&h=120',
                    isBestseller: true,
                  ),
                  const SizedBox(width: 16),
                  _buildProductCard(
                    context: context,
                    name: 'Keto Energy Bars',
                    size: 'Box of 12',
                    price: '₹899',
                    imageUrl: 'https://images.unsplash.com/photo-1568254183919-78a4f43a2877?fit=crop&w=150&h=120',
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

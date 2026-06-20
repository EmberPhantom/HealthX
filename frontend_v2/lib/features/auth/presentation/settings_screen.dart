import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../../notifications/providers/notification_preferences_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  
  // Settings goals controllers
  final _waterGoalController = TextEditingController();
  final _stepGoalController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  final _proteinGoalController = TextEditingController();
  final _carbGoalController = TextEditingController();
  final _fatGoalController = TextEditingController();

  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _prefillFields());
  }

  void _prefillFields() {
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      if (user.age != null) {
        _ageController.text = user.age.toString();
      }
      if (user.gender != null) {
        _selectedGender = user.gender!;
      }
      _waterGoalController.text = user.dailyWaterGoalMl.toString();
      _stepGoalController.text = user.dailyStepGoal.toString();
      _calorieGoalController.text = user.dailyCalorieGoal.toString();
      _proteinGoalController.text = user.dailyProteinGoalG.toString();
      _carbGoalController.text = user.dailyCarbGoalG.toString();
      _fatGoalController.text = user.dailyFatGoalG.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _waterGoalController.dispose();
    _stepGoalController.dispose();
    _calorieGoalController.dispose();
    _proteinGoalController.dispose();
    _carbGoalController.dispose();
    _fatGoalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    final waterGoal = int.tryParse(_waterGoalController.text.trim());
    final stepGoal = int.tryParse(_stepGoalController.text.trim());
    final calorieGoal = int.tryParse(_calorieGoalController.text.trim());
    final proteinGoal = int.tryParse(_proteinGoalController.text.trim());
    final carbGoal = int.tryParse(_carbGoalController.text.trim());
    final fatGoal = int.tryParse(_fatGoalController.text.trim());

    final successProfile = await ref.read(authProvider.notifier).updateUserProfile(
          name: name,
          phone: phone,
          gender: _selectedGender,
          age: age,
        );

    bool successSettings = false;
    if (successProfile) {
      successSettings = await ref.read(authProvider.notifier).updateUserSettings(
            dailyWaterGoalMl: waterGoal,
            dailyStepGoal: stepGoal,
            dailyCalorieGoal: calorieGoal,
            dailyProteinGoalG: proteinGoal,
            dailyCarbGoalG: carbGoal,
            dailyFatGoalG: fatGoal,
          );
    }

    final success = successProfile && successSettings;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'All settings and targets updated successfully!' : 'Failed to update settings'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: const Text(
            'WARNING: Deleting your account will permanently remove all your health history, tracking logs, rewards points, active consultations, and orders. This action is irreversible. Are you absolutely sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.neutral)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                final success = await ref.read(authProvider.notifier).deleteUserAccount();
                if (mounted) {
                  Navigator.pop(context); // Pop dialog
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully. We are sorry to see you go!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    final error = ref.read(authProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Failed to delete account'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('YES, DELETE ACCOUNT'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, color: AppColors.secondary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: AppColors.border, height: 1.0, thickness: 0.5),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Form Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EDIT PROFILE DETAILS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const Divider(height: 20),

                    // Name input
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone input
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),

                    // Age input
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Age (Years)', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),

                    // Gender input
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                      items: ['Male', 'Female', 'Other'].map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGender = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Targets Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EDIT HEALTH TARGETS & GOALS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _calorieGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Daily Calories (kcal)', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _waterGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Hydration Goal (mL)', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stepGoalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Daily Steps Goal', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DAILY MACRONUTRIENT SPLITS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _carbGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fatGoalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notification Preferences Card
              Consumer(
                builder: (context, ref, child) {
                  final notifState = ref.watch(notificationPreferencesProvider);
                  final notifNotifier = ref.read(notificationPreferencesProvider.notifier);

                  if (notifState.isLoading) return const SizedBox.shrink();

                  return CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NOTIFICATION PREFERENCES',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                        ),
                        const Divider(height: 20),
                        _buildToggle(
                          icon: PhosphorIconsRegular.drop,
                          label: 'Water Reminders',
                          subtitle: 'Remind to drink water every 30 min',
                          value: notifState.waterReminders,
                          onChanged: (v) => notifNotifier.toggle('water_reminders', v),
                        ),
                        const Divider(height: 1),
                        _buildToggle(
                          icon: PhosphorIconsRegular.moon,
                          label: 'Sleep Alarms',
                          subtitle: 'Bedtime and wake-up reminders',
                          value: notifState.sleepAlarms,
                          onChanged: (v) => notifNotifier.toggle('sleep_alarms', v),
                        ),
                        const Divider(height: 1),
                        _buildToggle(
                          icon: PhosphorIconsRegular.heart,
                          label: 'Health Alerts',
                          subtitle: 'Abnormal vitals and health reminders',
                          value: notifState.healthAlerts,
                          onChanged: (v) => notifNotifier.toggle('health_alerts', v),
                        ),
                        const Divider(height: 1),
                        _buildToggle(
                          icon: PhosphorIconsRegular.shoppingBag,
                          label: 'Order Updates',
                          subtitle: 'Order confirmations, tracking, and delivery',
                          value: notifState.orderUpdates,
                          onChanged: (v) => notifNotifier.toggle('order_updates', v),
                        ),
                        const Divider(height: 1),
                        _buildToggle(
                          icon: PhosphorIconsRegular.tag,
                          label: 'Promotions & Offers',
                          subtitle: 'Deals, discounts, and special offers',
                          value: notifState.promotionsOffers,
                          onChanged: (v) => notifNotifier.toggle('promotions_offers', v),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: 'SAVE ALL CHANGES',
                isLoading: authState.isLoading,
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 24),

              // Danger Zone Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DANGER ZONE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1.0),
                    ),
                    const Divider(height: 20),
                    const Text(
                      'Deleting your account is permanent and cannot be undone.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 44),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.red, width: 0.8),
                        ),
                      ),
                      onPressed: _confirmDeleteAccount,
                      icon: const Icon(PhosphorIconsRegular.trash),
                      label: const Text('DELETE ACCOUNT PERMANENTLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.tertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: value ? AppColors.primary : AppColors.neutral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}

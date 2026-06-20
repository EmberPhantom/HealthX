import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class RewardsState {
  final bool isStepsClaimed;
  final bool isSleepClaimed;
  final bool isWaterClaimed;
  final bool isLoading;
  final String? error;

  const RewardsState({
    this.isStepsClaimed = false,
    this.isSleepClaimed = false,
    this.isWaterClaimed = false,
    this.isLoading = false,
    this.error,
  });

  RewardsState copyWith({
    bool? isStepsClaimed,
    bool? isSleepClaimed,
    bool? isWaterClaimed,
    bool? isLoading,
    String? error,
  }) {
    return RewardsState(
      isStepsClaimed: isStepsClaimed ?? this.isStepsClaimed,
      isSleepClaimed: isSleepClaimed ?? this.isSleepClaimed,
      isWaterClaimed: isWaterClaimed ?? this.isWaterClaimed,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RewardsNotifier extends Notifier<RewardsState> {
  final DioClient _dioClient = DioClient();

  @override
  RewardsState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => loadClaimsState());
    }
    return const RewardsState();
  }

  Future<void> loadClaimsState() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final stepsKey = 'rewards_steps_$dateStr';
      final sleepKey = 'rewards_sleep_$dateStr';
      final waterKey = 'rewards_water_$dateStr';

      state = RewardsState(
        isStepsClaimed: prefs.getBool(stepsKey) ?? false,
        isSleepClaimed: prefs.getBool(sleepKey) ?? false,
        isWaterClaimed: prefs.getBool(waterKey) ?? false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> claimPoints(String taskType, int amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dioClient.patch(
        '/users/me/points',
        data: {'points': amount},
      );

      final responseData = response.data['data'] ?? response.data;
      final int newTotalPoints = responseData['totalPoints'] ?? amount;

      // Update auth provider
      ref.read(authProvider.notifier).updatePointsLocally(newTotalPoints);

      // Persist in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = 'rewards_${taskType}_$dateStr';
      await prefs.setBool(key, true);

      // Update local state
      if (taskType == 'steps') {
        state = state.copyWith(isStepsClaimed: true, isLoading: false);
      } else if (taskType == 'sleep') {
        state = state.copyWith(isSleepClaimed: true, isLoading: false);
      } else if (taskType == 'water') {
        state = state.copyWith(isWaterClaimed: true, isLoading: false);
      }
      return true;
    } catch (e) {
      debugPrint('❌ claimPoints failed: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final rewardsProvider = NotifierProvider<RewardsNotifier, RewardsState>(RewardsNotifier.new);

class RewardTask {
  final String taskId;
  final String title;
  final int points;
  final int target;
  final String unit;

  const RewardTask({
    required this.taskId,
    required this.title,
    required this.points,
    required this.target,
    required this.unit,
  });

  factory RewardTask.fromJson(Map<String, dynamic> json) {
    return RewardTask(
      taskId: json['taskId'] ?? '',
      title: json['title'] ?? '',
      points: json['points'] ?? 0,
      target: json['target'] ?? 0,
      unit: json['unit'] ?? '',
    );
  }
}

final rewardTasksProvider = FutureProvider<List<RewardTask>>((ref) async {
  final dioClient = DioClient();
  final response = await dioClient.get('/content/reward-tasks');
  final list = response.data['data'] as List? ?? [];
  return list.map((item) => RewardTask.fromJson(item as Map<String, dynamic>)).toList();
});

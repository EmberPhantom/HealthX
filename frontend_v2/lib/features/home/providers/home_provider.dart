import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tracker/providers/tracker_provider.dart';

class HomeState {
  final String userName;
  final int todaySteps;
  final int todayWater;
  final String sleepDuration;
  final int latestGlucose;
  final bool isLoading;

  const HomeState({
    required this.userName,
    required this.todaySteps,
    required this.todayWater,
    required this.sleepDuration,
    required this.latestGlucose,
    required this.isLoading,
  });
}

final homeProvider = Provider<HomeState>((ref) {
  final authState = ref.watch(authProvider);
  final trackerState = ref.watch(trackerProvider);

  final name = authState.user?.name ?? '';
  final steps = trackerState.todaySteps;
  final water = trackerState.todayWaterAmount;

  final sleepLog = trackerState.lastSleep;
  String sleepDuration = '0h 0m';
  if (sleepLog != null) {
    final diff = sleepLog.wakeTime.difference(sleepLog.bedtime);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    sleepDuration = '${hours}h ${mins}m';
  }

  final glucoseLog = trackerState.lastGlucose;
  final glucose = glucoseLog?.level ?? 0;

  return HomeState(
    userName: name,
    todaySteps: steps,
    todayWater: water,
    sleepDuration: sleepDuration,
    latestGlucose: glucose,
    isLoading: authState.isLoading || trackerState.isLoading,
  );
});

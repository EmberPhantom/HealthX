import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_health_service.dart';
import '../../auth/providers/auth_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AIHealthState {
  final AIProfileStatus? profileStatus;
  final bool isLoadingStatus;
  final bool isLoadingQuestions;
  final bool isSubmitting;
  final List<AIStep5Question> step5Questions;
  final String? error;

  const AIHealthState({
    this.profileStatus,
    this.isLoadingStatus = false,
    this.isLoadingQuestions = false,
    this.isSubmitting = false,
    this.step5Questions = const [],
    this.error,
  });

  bool get analysisComplete => profileStatus?.isComplete ?? false;
  bool get analysisPending => profileStatus?.isPending ?? false;

  AIHealthState copyWith({
    AIProfileStatus? profileStatus,
    bool? isLoadingStatus,
    bool? isLoadingQuestions,
    bool? isSubmitting,
    List<AIStep5Question>? step5Questions,
    String? error,
  }) {
    return AIHealthState(
      profileStatus: profileStatus ?? this.profileStatus,
      isLoadingStatus: isLoadingStatus ?? this.isLoadingStatus,
      isLoadingQuestions: isLoadingQuestions ?? this.isLoadingQuestions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      step5Questions: step5Questions ?? this.step5Questions,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AIHealthNotifier extends Notifier<AIHealthState> {
  final AIHealthService _service = AIHealthService();

  @override
  AIHealthState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      // Fetch status on each auth session change (e.g., after login)
      Future.microtask(() => fetchProfileStatus());
    }
    return const AIHealthState();
  }

  /// Check the AI analysis status.
  /// Called on Home screen load to show/hide the "plan being prepared" banner.
  Future<void> fetchProfileStatus() async {
    state = state.copyWith(isLoadingStatus: true, error: null);
    try {
      final status = await _service.getProfileStatus();
      state = state.copyWith(profileStatus: status, isLoadingStatus: false);
    } catch (e) {
      state = state.copyWith(isLoadingStatus: false);
      // Status fetch failure is non-critical — don't surface the error
    }
  }

  /// Load AI-generated Step 5 questions.
  /// Called when the user lands on the Step 5 page in the onboarding wizard.
  Future<void> loadStep5Questions() async {
    state = state.copyWith(isLoadingQuestions: true, error: null);
    try {
      final questions = await _service.getStep5Questions();
      state = state.copyWith(
        step5Questions: questions,
        isLoadingQuestions: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingQuestions: false,
        error: 'Could not load personalisation questions.',
      );
    }
  }

  /// Submit Step 5 responses and kick off the background analysis job.
  /// Returns true on success.
  Future<bool> submitStep5(List<AIStep5Response> responses) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _service.submitAnalysis(responses);
      state = state.copyWith(
        isSubmitting: false,
        profileStatus: const AIProfileStatus(status: 'pending', version: 0),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final aiHealthProvider = NotifierProvider<AIHealthNotifier, AIHealthState>(
  AIHealthNotifier.new,
);

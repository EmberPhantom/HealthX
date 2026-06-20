import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/prakriti_models.dart';
import '../services/prakriti_service.dart';
import '../../auth/providers/auth_provider.dart';

class PrakritiState {
  final List<PrakritiQuestion> questions;
  final Map<String, String> answers;
  final bool isLoading;
  final String? error;
  final PrakritiAssessmentResult? result;

  const PrakritiState({
    this.questions = const [],
    this.answers = const {},
    this.isLoading = false,
    this.error,
    this.result,
  });

  PrakritiState copyWith({
    List<PrakritiQuestion>? questions,
    Map<String, String>? answers,
    bool? isLoading,
    String? error,
    PrakritiAssessmentResult? result,
  }) {
    return PrakritiState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }
}

class PrakritiNotifier extends Notifier<PrakritiState> {
  final PrakritiService _service = PrakritiService();

  @override
  PrakritiState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchLatestResult());
    }
    return const PrakritiState();
  }

  Future<void> fetchLatestResult() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _service.getLatestAssessment();
      state = PrakritiState(
        result: res,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchQuestions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final questionsList = await _service.getQuestions();
      state = state.copyWith(
        questions: questionsList,
        answers: {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectAnswer(String questionId, String optionKey) {
    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[questionId] = optionKey;
    state = state.copyWith(answers: newAnswers);
  }

  Future<bool> submitQuiz() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resultData = await _service.submitAssessment(state.answers);
      state = state.copyWith(
        result: resultData,
        isLoading: false,
      );
      
      // Update local auth user profile dominantDosha if possible
      ref.read(authProvider.notifier).updateLocalUserDosha(resultData.dominantDosha);
      
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void resetQuiz() {
    state = state.copyWith(
      answers: {},
      error: null,
    );
  }
}

final prakritiProvider = NotifierProvider<PrakritiNotifier, PrakritiState>(PrakritiNotifier.new);

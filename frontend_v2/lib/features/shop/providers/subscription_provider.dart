import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../../../core/models/subscription_models.dart';
import '../../auth/providers/auth_provider.dart';

class SubscriptionState {
  final List<UserSubscription> subscriptions;
  final bool isLoading;
  final String? error;

  const SubscriptionState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
  });

  UserSubscription? get activeSubscription {
    for (final sub in subscriptions) {
      if (sub.status == 'active') return sub;
    }
    return null;
  }

  SubscriptionState copyWith({
    List<UserSubscription>? subscriptions,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  final SubscriptionService _service = SubscriptionService();

  @override
  SubscriptionState build() {
    final session = ref.watch(sessionProvider);
    if (session != null) {
      Future.microtask(() => fetchSubscriptions());
    }
    return const SubscriptionState();
  }

  Future<void> fetchSubscriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getActiveSubscriptions();
      state = SubscriptionState(
        subscriptions: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> subscribe(String planId, double price, String planName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sub = await _service.subscribeToPlan(planId, price, planName);
      state = state.copyWith(
        subscriptions: [sub, ...state.subscriptions],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> pause(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sub = await _service.pauseSubscription(id);

      final updated = state.subscriptions.map((s) {
        if (s.id == id) {
          return sub;
        }
        return s;
      }).toList();

      state = state.copyWith(
        subscriptions: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancel(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sub = await _service.cancelSubscription(id);
      
      final updated = state.subscriptions.map((s) {
        if (s.id == id) {
          return sub;
        }
        return s;
      }).toList();

      state = state.copyWith(
        subscriptions: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(SubscriptionNotifier.new);

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  return SubscriptionService().getSubscriptionPlans();
});


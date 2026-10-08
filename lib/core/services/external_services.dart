enum PurchaseState {
  unavailable,
  pending,
  purchased,
  cancelled,
  failed,
  restored,
  notOwned,
}

abstract interface class BillingService {
  bool get available;
  Future<PurchaseState> purchase();
  Future<PurchaseState> restore();
}

class DisabledBillingService implements BillingService {
  @override
  bool get available => false;
  @override
  Future<PurchaseState> purchase() async => PurchaseState.unavailable;
  @override
  Future<PurchaseState> restore() async => PurchaseState.unavailable;
}

enum SafeEvent {
  onboardingCompleted,
  cardCompleted,
  reminderCreated,
  paywallViewed,
}

abstract interface class AnalyticsService {
  void record(SafeEvent event);
}

class NoOpAnalytics implements AnalyticsService {
  @override
  void record(SafeEvent event) {}
}

abstract final class AppConfig {
  static const billingEnabled = false;
  static const analyticsEnabled = false;
  static const minSuccessfulActionsBetweenInterstitials = 2;
  static const interstitialCooldown = Duration(seconds: 90);
  // A ceiling, never a target: meaningful actions + cooldown + safe routes
  // still apply. Compare retention/show rate before raising this further.
  static const dailyInterstitialCap = 6;
}

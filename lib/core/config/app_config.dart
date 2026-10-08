abstract final class AppConfig {
  static const version = '1.0.5 (7)';
  static const billingEnabled = false;
  static const analyticsEnabled = false;
  static const minSuccessfulActionsBetweenInterstitials = 2;
  static const interstitialCooldown = Duration(seconds: 90);
  static const dailyInterstitialCap = 2;
}

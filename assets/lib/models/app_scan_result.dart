class AppScanResult {
  final String appName;
  final String packageName;
  final int score;
  final String? reason;

  AppScanResult(this.appName, this.packageName, this.score, {this.reason});
}

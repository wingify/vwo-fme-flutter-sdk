class VWOInitOptions {
  final String sdkKey;
  final int accountId;
  final Map<String, String>? logger;
  final Map<String, String>? gatewayService;
  final int? pollInterval;
  final int? cachedSettingsExpiryTime;
  final Function(Map<String, dynamic>)? integrationCallback;

  VWOInitOptions({
    required this.sdkKey,
    required this.accountId,
    this.logger,
    this.gatewayService,
    this.pollInterval,
    this.cachedSettingsExpiryTime,
    this.integrationCallback,
  });

  @override
  String toString() {
    return 'VWOInitOptions('
        'sdkKey: $sdkKey, '
        'accountId: $accountId, '
        'logger: $logger, '
        'gatewayService: $gatewayService, '
        'pollInterval: $pollInterval, '
        'cachedSettingsExpiryTime: $cachedSettingsExpiryTime, '
        'integrationCallback: ${integrationCallback != null ? 'Provided' : 'Not Provided'})';
  }
}
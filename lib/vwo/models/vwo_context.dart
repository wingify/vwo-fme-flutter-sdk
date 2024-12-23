class VWOContext {
  final String userId;
  final Map<String, dynamic>? customVariables;
  final String? ipAddress;
  final String? userAgent;

  VWOContext({
    required this.userId, // Mandatory parameter
    this.customVariables,
    this.ipAddress,
    this.userAgent,
  });

  /// Converts the `UserContext` object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'customVariables': customVariables,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  @override
  String toString() {
    return 'UserContext('
        'userId: $userId, '
        'customVariables: $customVariables, '
        'ipAddress: $ipAddress, '
        'userAgent: $userAgent)';
  }
}
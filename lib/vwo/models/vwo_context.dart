class VWOContext {
  final String userId;
  final Map<String, dynamic>? customVariables;

  VWOContext({
    required this.userId, // Mandatory parameter
    this.customVariables,
  });

  /// Converts the `UserContext` object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'customVariables': customVariables,
    };
  }

  @override
  String toString() {
    return 'UserContext('
        'userId: $userId, '
        'customVariables: $customVariables)';
  }
}
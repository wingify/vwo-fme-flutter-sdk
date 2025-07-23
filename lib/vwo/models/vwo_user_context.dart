class VWOUserContext {
  final String? id;
  final Map<String, dynamic>? customVariables;
  final bool shouldUseDeviceIdAsUserId;

  VWOUserContext({
    this.id, // Optional parameter since it is nullable
    this.customVariables,
    this.shouldUseDeviceIdAsUserId = false, // Default to false
  });

  /// Converts the `VWOUserContext` object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customVariables': customVariables,
      'shouldUseDeviceIdAsUserId': shouldUseDeviceIdAsUserId,
    };
  }

  @override
  String toString() {
    return 'VWOUserContext('
        'userId: $id, '
        'customVariables: $customVariables, '
        'shouldUseDeviceIdAsUserId: $shouldUseDeviceIdAsUserId)';
  }
}

class VWOUserContext {
  final String id;
  final Map<String, dynamic>? customVariables;

  VWOUserContext({
    required this.id, // Mandatory parameter
    this.customVariables,
  });

  /// Converts the `VWOUserContext` object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customVariables': customVariables,
    };
  }

  @override
  String toString() {
    return 'VWOUserContext('
        'userId: $id, '
        'customVariables: $customVariables)';
  }
}
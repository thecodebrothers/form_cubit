class LocalValidationError implements Exception {
  LocalValidationError({required this.invalidFields});

  final List<String> invalidFields;
}

class CnicVerificationResult {
  final bool exists;
  final String? guardianName;
  final String? message;

  const CnicVerificationResult({
    required this.exists,
    this.guardianName,
    this.message,
  });
}

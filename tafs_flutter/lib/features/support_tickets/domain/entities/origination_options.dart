class OriginationChildOption {
  final int cc;
  final String label;

  const OriginationChildOption({required this.cc, required this.label});
}

class OriginationOptions {
  final List<Map<String, String>> categories;
  final List<String> topicsGeneralWithChild;
  final List<String> topicsGeneralNoChild;
  final List<String> topicsFinancial;
  final String generalNoChildLabel;
  final String financialFamilyLabel;

  const OriginationOptions({
    required this.categories,
    required this.topicsGeneralWithChild,
    required this.topicsGeneralNoChild,
    required this.topicsFinancial,
    required this.generalNoChildLabel,
    required this.financialFamilyLabel,
  });
}

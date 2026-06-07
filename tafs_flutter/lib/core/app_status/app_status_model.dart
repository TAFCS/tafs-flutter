class AppStatusModel {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool forceUpdate;
  final String storeUrl;

  const AppStatusModel({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.forceUpdate,
    required this.storeUrl,
  });

  factory AppStatusModel.fromJson(Map<String, dynamic> json) {
    return AppStatusModel(
      maintenanceMode: json['maintenanceMode'] ?? false,
      maintenanceMessage: json['maintenanceMessage'] ?? '',
      forceUpdate: json['forceUpdate'] ?? false,
      storeUrl: json['storeUrl'] ?? '',
    );
  }

  factory AppStatusModel.defaultOk() {
    return const AppStatusModel(
      maintenanceMode: false,
      maintenanceMessage: '',
      forceUpdate: false,
      storeUrl: '',
    );
  }
}

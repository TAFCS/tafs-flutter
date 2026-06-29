import '../entities/leave_request.dart';

abstract class LeaveRequestsRepository {
  Future<List<LeaveRequest>> getMyRequests();
  Future<LeaveSelfContext> getSelfContext();
  Future<LeaveRequest> submitRequest({
    required String leaveTypeCode,
    required String startDate,
    required String endDate,
    String? reason,
    String? attachmentUrl,
    String? attachmentType,
  });
  Future<void> cancelRequest(int id);
  Future<({String url, String type})> uploadAttachment({
    required int employeeId,
    required String filePath,
    List<int>? bytes,
    required String filename,
  });
}

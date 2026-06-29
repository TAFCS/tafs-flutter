import 'package:dio/dio.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_requests_repository.dart';

class LeaveRequestsRepositoryImpl implements LeaveRequestsRepository {
  final Dio dio;

  LeaveRequestsRepositoryImpl({required this.dio});

  @override
  Future<List<LeaveRequest>> getMyRequests() async {
    final res = await dio.get('/hr/leaves/me');
    final list = _unwrapList(res.data);
    return list.map(LeaveRequest.fromJson).toList();
  }

  @override
  Future<LeaveSelfContext> getSelfContext() async {
    final res = await dio.get('/hr/leaves/me/context');
    final json = _unwrapMap(res.data);
    return LeaveSelfContext.fromJson(json);
  }

  @override
  Future<LeaveRequest> submitRequest({
    required String leaveTypeCode,
    required String startDate,
    required String endDate,
    String? reason,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    final res = await dio.post('/hr/leaves/me', data: {
      'leaveTypeCode': leaveTypeCode,
      'startDate': startDate,
      'endDate': endDate,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentType != null) 'attachmentType': attachmentType,
    });
    return LeaveRequest.fromJson(_unwrapMap(res.data));
  }

  @override
  Future<void> cancelRequest(int id) async {
    await dio.delete('/hr/leaves/me/$id');
  }

  @override
  Future<({String url, String type})> uploadAttachment({
    required int employeeId,
    required String filePath,
    List<int>? bytes,
    required String filename,
  }) async {
    MultipartFile multipartFile;
    if (bytes != null) {
      multipartFile = MultipartFile.fromBytes(bytes, filename: filename);
    } else {
      multipartFile = await MultipartFile.fromFile(filePath, filename: filename);
    }
    final form = FormData.fromMap({'file': multipartFile});
    final res = await dio.post(
      '/media/employee/$employeeId/leave-attachment',
      data: form,
    );
    final json = _unwrapMap(res.data);
    return (
      url: json['url'] as String,
      type: json['type'] as String? ?? 'document',
    );
  }

  List<Map<String, dynamic>> _unwrapList(dynamic raw) {
    final data = raw is Map ? raw['data'] ?? raw : raw;
    return (data as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      return raw['data'] as Map<String, dynamic>;
    }
    return raw as Map<String, dynamic>;
  }
}

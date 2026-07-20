import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/models/parent_dto.dart';
import '../../features/auth/data/models/staff_user_dto.dart';

/// Dio interceptor that transparently refreshes access tokens on 401 for parent or staff sessions.
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final AuthLocalDataSource localDataSource;
  final void Function() onLogout;
  final void Function(ParentDto parent) onParentTokenRefreshed;
  final void Function(StaffUserDto staff) onStaffTokenRefreshed;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingQueue = [];
  final Dio _refreshDio = Dio();

  TokenInterceptor({
    required this.dio,
    required this.localDataSource,
    required this.onLogout,
    required this.onParentTokenRefreshed,
    required this.onStaffTokenRefreshed,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final alreadyRetried = err.requestOptions.extra['__retried_after_refresh'] == true;
    final path = err.requestOptions.path;
    final isAuthPath = path.contains('/auth/parent/login') ||
        path.contains('/auth/parent/refresh') ||
        path.contains('/auth/parent/logout') ||
        path.contains('/auth/staff/mobile/login') ||
        path.contains('/auth/staff/mobile/refresh') ||
        path.contains('/auth/staff/mobile/logout');

    if (err.response?.statusCode != 401 || isAuthPath || alreadyRetried) {
      return handler.next(err);
    }

    final RequestOptions original = err.requestOptions;

    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _pendingQueue.add(
        _PendingRequest(options: original, completer: completer),
      );
      try {
        final response = await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw err,
        );
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    String? newAccess;

    try {
      final isStaff = await localDataSource.hasStaffSession();
      final String baseUrl = AppConfig.apiBaseUrl;

      if (isStaff) {
        final cached = await localDataSource.getCachedStaff();
        if (cached == null) {
          _failAll(err);
          await _clearAndLogout();
          return handler.next(err);
        }

        final refreshResponse = await _refreshDio.post<Map<String, dynamic>>(
          '$baseUrl/auth/staff/mobile/refresh',
          data: {'refreshToken': cached.refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        final inner = refreshResponse.data!['data'] as Map<String, dynamic>;
        newAccess = inner['accessToken'] as String;
        final updated = StaffUserDto.fromJson({'data': inner});
        await localDataSource.cacheStaff(updated);
        onStaffTokenRefreshed(updated);
      } else {
        final cached = await localDataSource.getCachedParent();
        if (cached == null) {
          _failAll(err);
          await _clearAndLogout();
          return handler.next(err);
        }

        final refreshResponse = await _refreshDio.post<Map<String, dynamic>>(
          '$baseUrl/auth/parent/refresh',
          data: {'refreshToken': cached.refreshToken},
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        final inner = refreshResponse.data!['data'] as Map<String, dynamic>;
        newAccess = inner['accessToken'] as String;
        final newRefresh = inner['refreshToken'] as String;
        final updated = ParentDto(
          id: cached.id,
          username: cached.username,
          householdName: cached.householdName,
          students: cached.students,
          guardians: cached.guardians,
          accessToken: newAccess,
          refreshToken: newRefresh,
          photographUrl: cached.photographUrl,
          homePhone: cached.homePhone,
        );
        await localDataSource.cacheParent(updated);
        onParentTokenRefreshed(updated);
      }

      for (final pending in _pendingQueue) {
        pending.options.headers['Authorization'] = 'Bearer $newAccess';
        pending.options.extra['__retried_after_refresh'] = true;
        try {
          final retried = await dio.fetch<dynamic>(pending.options);
          pending.completer.complete(retried);
        } catch (e) {
          pending.completer.completeError(e);
        }
      }
      _pendingQueue.clear();

      original.headers['Authorization'] = 'Bearer $newAccess';
      original.extra['__retried_after_refresh'] = true;
      final retriedResponse = await dio.fetch<dynamic>(original);
      return handler.resolve(retriedResponse);
    } on DioException catch (refreshErr) {
      final refreshPath = refreshErr.requestOptions.path;
      if ((refreshPath.contains('/auth/parent/refresh') ||
              refreshPath.contains('/auth/staff/mobile/refresh')) &&
          (refreshErr.response?.statusCode == 401 ||
              refreshErr.response?.statusCode == 403)) {
        _failAll(err);
        await _clearAndLogout();
        return handler.next(err);
      }
      _failAll(refreshErr);
      return handler.next(refreshErr);
    } catch (_) {
      _failAll(err);
      await _clearAndLogout();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  void _failAll(DioException err) {
    for (final pending in _pendingQueue) {
      pending.completer.completeError(err);
    }
    _pendingQueue.clear();
  }

  Future<void> _clearAndLogout() async {
    // Let AuthBloc handle remote logout (incl. FCM unregister) and local cache wipe.
    onLogout();
  }
}

class _PendingRequest {
  final RequestOptions options;
  final Completer<Response<dynamic>> completer;

  const _PendingRequest({required this.options, required this.completer});
}

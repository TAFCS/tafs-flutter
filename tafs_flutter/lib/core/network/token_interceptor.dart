import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/models/parent_dto.dart';

/// Dio interceptor that transparently refreshes the parent access token on 401.
///
/// Flow:
///   1. Original request → 401 response
///   2. Read cached [ParentDto] from [AuthLocalDataSource] for the refresh token
///   3. POST /auth/parent/refresh → get a new token pair
///   4. Persist updated [ParentDto] back to secure storage
///   5. Retry the original request (and any queued concurrent requests)
///   6. If refresh also fails → clear storage + call [onLogout] (triggers AuthBloc)
class TokenInterceptor extends Interceptor {
  final Dio dio;
  final AuthLocalDataSource localDataSource;

  /// Called when refresh fails or no cached session exists.
  /// In practice: `() => InjectionContainer.authBloc.add(AuthLogoutRequested())`
  final void Function() onLogout;

  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingQueue = [];

  /// Dedicated Dio for the refresh call — must NOT carry this interceptor
  /// to avoid an infinite loop when the refresh endpoint itself returns 401.
  final Dio _refreshDio = Dio();

  TokenInterceptor({
    required this.dio,
    required this.localDataSource,
    required this.onLogout,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final alreadyRetried = err.requestOptions.extra['__retried_after_refresh'] == true;
    final path = err.requestOptions.path;
    final isAuthPath =
        path.contains('/auth/parent/login') ||
        path.contains('/auth/parent/refresh') ||
        path.contains('/auth/parent/logout');

    // Only intercept 401s that are not from the refresh endpoint itself
    if (err.response?.statusCode != 401 ||
        isAuthPath ||
        alreadyRetried) {
      return handler.next(err);
    }

    final RequestOptions original = err.requestOptions;

    // ── Concurrent request during an ongoing refresh ──────────────────────
    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _pendingQueue.add(
        _PendingRequest(options: original, completer: completer),
      );
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;

    String? newAccess;
    try {
      // ── 1. Read cached session ──────────────────────────────────────────
      final cached = await localDataSource.getCachedParent();
      if (cached == null) {
        _failAll(err);
        await _clearAndLogout();
        return handler.next(err);
      }

      // ── 2. Call refresh endpoint ────────────────────────────────────────
      final String baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api/v1';

      final refreshResponse = await _refreshDio.post<Map<String, dynamic>>(
        '$baseUrl/auth/parent/refresh',
        data: {'refreshToken': cached.refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // ── 3. Unwrap { data: { accessToken, refreshToken } } envelope ───────
      final innerData = (refreshResponse.data!['data'] as Map<String, dynamic>);
      newAccess = innerData['accessToken'] as String;
      final newRefresh = innerData['refreshToken'] as String;

      // ── 4. Persist updated tokens ───────────────────────────────────────
      final updated = ParentDto(
        id: cached.id,
        username: cached.username,
        householdName: cached.householdName,
        students: cached.students,
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      await localDataSource.cacheParent(updated);

      // ── 5. Drain queue — retry all waiting requests ─────────────────────
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

      // ── 6. Retry the original request ───────────────────────────────────
      original.headers['Authorization'] = 'Bearer $newAccess';
      original.extra['__retried_after_refresh'] = true;
      final retriedResponse = await dio.fetch<dynamic>(original);
      return handler.resolve(retriedResponse);
    } on DioException catch (refreshErr) {
      // Logout only when refresh itself is rejected/unauthorized.
      if (refreshErr.requestOptions.path.contains('/auth/parent/refresh') &&
          (refreshErr.response?.statusCode == 401 ||
              refreshErr.response?.statusCode == 403)) {
        _failAll(err);
        await _clearAndLogout();
        return handler.next(err);
      }
      _failAll(refreshErr);
      return handler.next(refreshErr);
    } catch (_) {
      // Refresh parsing/storage failed — treat as auth session failure.
      _failAll(err);
      await _clearAndLogout();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _failAll(DioException err) {
    for (final pending in _pendingQueue) {
      pending.completer.completeError(err);
    }
    _pendingQueue.clear();
  }

  Future<void> _clearAndLogout() async {
    await localDataSource.clearCache();
    onLogout();
  }
}

class _PendingRequest {
  final RequestOptions options;
  final Completer<Response<dynamic>> completer;

  const _PendingRequest({required this.options, required this.completer});
}

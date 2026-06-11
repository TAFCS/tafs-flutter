import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/token_interceptor.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/parent_login_usecase.dart';
import 'features/auth/domain/usecases/staff_login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/support_tickets/staff/data/repositories/staff_support_ticket_repository_impl.dart';
import 'features/support_tickets/staff/domain/repositories/staff_support_ticket_repository.dart';
import 'features/support_tickets/staff/presentation/bloc/staff_pending_approvals_cubit.dart';
import 'features/support_tickets/staff/presentation/bloc/staff_ticket_queue_bloc.dart';

// Fee Ledger
import 'features/fee_ledger/data/datasources/fee_ledger_remote_data_source.dart';
import 'features/fee_ledger/data/datasources/fee_summary_remote_data_source.dart';
import 'features/fee_ledger/data/repositories/fee_ledger_repository_impl.dart';
import 'features/fee_ledger/data/repositories/fee_summary_repository_impl.dart';
import 'features/fee_ledger/domain/usecases/get_student_fee_months_usecase.dart';
import 'features/fee_ledger/domain/usecases/get_student_vouchers_usecase.dart';
import 'features/fee_ledger/domain/usecases/get_fee_summary_usecase.dart';
import 'features/fee_ledger/domain/usecases/get_ledger_usecase.dart';
import 'features/fee_ledger/domain/usecases/resolve_voucher_for_month_usecase.dart';
import 'features/fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import 'features/fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import 'features/fee_ledger/presentation/bloc/student_ledger_bloc.dart';
import 'features/auth/presentation/bloc/selected_student_cubit.dart';
import 'features/chat/data/datasources/chat_outbox_local_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/support_tickets/data/repositories/support_ticket_repository_impl.dart';
import 'features/support_tickets/domain/repositories/support_ticket_repository.dart';
import 'features/support_tickets/presentation/bloc/support_ticket_list_bloc.dart';
import 'features/notice_board/data/datasources/notice_board_remote_data_source.dart';
import 'features/notice_board/data/repositories/notice_board_repository_impl.dart';
import 'features/notice_board/presentation/bloc/notice_board_bloc.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'core/config/app_config.dart';

class InjectionContainer {
  static late final AuthBloc authBloc;
  static late final FeeLedgerBloc feeLedgerBloc;
  static late final StudentLedgerBloc studentLedgerBloc;
  static late final FeeSummaryBloc feeSummaryBloc;
  static late final SelectedStudentCubit selectedStudentCubit;
  static late final ChatBloc chatBloc;
  static late final SupportTicketListBloc supportTicketListBloc;
  static late final SupportTicketRepository supportTicketRepository;
  static late final StaffSupportTicketRepository staffSupportTicketRepository;
  static late final StaffTicketQueueBloc staffTicketQueueBloc;
  static late final StaffPendingApprovalsCubit staffPendingApprovalsCubit;
  static late final Dio dio;
  static late final NoticeBoardBloc noticeBoardBloc;
  static late final ProfileBloc profileBloc;

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static void init() {
    if (_initialized) return;
    _initialized = true;
    // Core
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
    ));
    const secureStorage = FlutterSecureStorage();

    final localDataSource = AuthLocalDataSourceImpl(secureStorage);
    final remoteDataSource = AuthRemoteDataSourceImpl(dio);

    // Repository
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    final feeLedgerRemoteDataSource = FeeLedgerRemoteDataSourceImpl(dio);
    final feeLedgerRepository = FeeLedgerRepositoryImpl(
      remoteDataSource: feeLedgerRemoteDataSource,
    );

    final feeSummaryRemoteDataSource = FeeSummaryRemoteDataSourceImpl(dio);
    final feeSummaryRepository = FeeSummaryRepositoryImpl(
      remoteDataSource: feeSummaryRemoteDataSource,
    );

    final chatOutboxDataSource = ChatOutboxLocalDataSource();
    final ChatRepository chatRepository = ChatRepositoryImpl(
      dio: dio,
      localDataSource: localDataSource,
      outboxDataSource: chatOutboxDataSource,
      baseUrl: AppConfig.apiBaseUrl,
    );

    // Use cases
    final parentLoginUseCase = ParentLoginUseCase(authRepository);
    final staffLoginUseCase = StaffLoginUseCase(authRepository);
    final getStudentFeeMonthsUseCase = GetStudentFeeMonthsUseCase(
      feeLedgerRepository,
    );
    final getStudentVouchersUseCase = GetStudentVouchersUseCase(
      feeLedgerRepository,
    );
    final resolveVoucherForMonthUseCase = ResolveVoucherForMonthUseCase(
      feeLedgerRepository,
    );
    final getFeeSummaryUseCase = GetFeeSummaryUseCase(feeSummaryRepository);
    final getLedgerUseCase = GetLedgerUseCase(feeLedgerRepository);

    // BLoCs
    authBloc = AuthBloc(
      loginUseCase: parentLoginUseCase,
      staffLoginUseCase: staffLoginUseCase,
      repository: authRepository,
    );

    feeLedgerBloc = FeeLedgerBloc(
      getStudentFeeMonths: getStudentFeeMonthsUseCase,
      getStudentVouchers: getStudentVouchersUseCase,
      resolveVoucherForMonthUseCase: resolveVoucherForMonthUseCase,
    );

    studentLedgerBloc = StudentLedgerBloc(
      getLedger: getLedgerUseCase,
      getStudentVouchers: getStudentVouchersUseCase,
    );

    feeSummaryBloc = FeeSummaryBloc(getFeeSummary: getFeeSummaryUseCase);

    selectedStudentCubit = SelectedStudentCubit();

    chatBloc = ChatBloc(repository: chatRepository);

    chatRepository.onSessionExpired.listen((_) {
      authBloc.add(AuthLogoutRequested());
    });

    supportTicketRepository = SupportTicketRepositoryImpl(
      dio: dio,
      chatRepository: chatRepository,
    );
    supportTicketListBloc = SupportTicketListBloc(
      repository: supportTicketRepository,
    );

    staffSupportTicketRepository = StaffSupportTicketRepositoryImpl(
      dio: dio,
      chatRepository: chatRepository,
    );
    staffTicketQueueBloc = StaffTicketQueueBloc(
      repository: staffSupportTicketRepository,
    );
    staffPendingApprovalsCubit = StaffPendingApprovalsCubit(
      repository: staffSupportTicketRepository,
    );

    final noticeBoardRemoteDataSource = NoticeBoardRemoteDataSource(dio);
    final noticeBoardRepository = NoticeBoardRepositoryImpl(
      remoteDataSource: noticeBoardRemoteDataSource,
    );
    noticeBoardBloc = NoticeBoardBloc(repository: noticeBoardRepository);

    final profileRemoteDataSource = ProfileRemoteDataSourceImpl(dio);
    final profileRepository = ProfileRepositoryImpl(
      remoteDataSource: profileRemoteDataSource,
    );
    profileBloc = ProfileBloc(repository: profileRepository);

    // ── Dio interceptors ───────────────────────────────────────────────────
    // Must be registered after authBloc so the TokenInterceptor callback
    // can reference it.

    // 1. Attach access token to every outgoing request automatically
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await localDataSource.getActiveAccessToken();
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // 2. Silently refresh on 401; trigger logout if refresh also fails.
    // onTokenRefreshed keeps AuthBloc state and HydratedBloc JSON cache in sync
    // with FlutterSecureStorage so stale tokens are never restored on cold restart.
    dio.interceptors.add(
      TokenInterceptor(
        dio: dio,
        localDataSource: localDataSource,
        onLogout: () => authBloc.add(AuthLogoutRequested()),
        onParentTokenRefreshed: (parent) => authBloc.add(AuthTokenRefreshed(parent)),
        onStaffTokenRefreshed: (staff) => authBloc.add(AuthStaffTokenRefreshed(staff)),
      ),
    );
  }
}

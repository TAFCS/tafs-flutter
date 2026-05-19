import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/in_app_notification_service.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../chat/domain/entities/chat_message.dart';
import '../../chat/presentation/bloc/chat_bloc.dart';
import '../../chat/presentation/bloc/chat_state.dart';
import '../../chat/presentation/bloc/chat_event.dart';
import '../../chat/presentation/pages/chat_page.dart';
import '../../fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../fee_ledger/presentation/bloc/fee_summary_event.dart';
import '../../fee_ledger/presentation/pages/fee_ledger_page.dart';
import '../../profile/presentation/family_profile_page.dart';
import 'main_dashboard_page.dart';
import 'widgets/student_app_bar.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final student = context.read<SelectedStudentCubit>().state;
    if (student != null) {
      context.read<FeeSummaryBloc>().add(FeeSummaryLoadRequested(student.cc));
      context.read<FeeLedgerBloc>().add(FeeLedgerLoadRequested(student.cc));
    }
  }

  void _onTabTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SelectedStudentCubit, Student?>(
          listener: (context, student) {
            if (student != null) {
              context.read<FeeSummaryBloc>().add(FeeSummaryLoadRequested(student.cc));
              context.read<FeeLedgerBloc>().add(FeeLedgerLoadRequested(student.cc));
            }
          },
        ),
        BlocListener<ChatBloc, ChatState>(
          listenWhen: (previous, current) {
            if (previous is ChatLoaded && current is ChatLoaded) {
              return current.messages.length > previous.messages.length &&
                  current.messages.first.senderType == ChatSenderType.admin;
            }
            return false;
          },
          listener: (context, state) {
            if (state is ChatLoaded && state.messages.isNotEmpty) {
              final latest = state.messages.first;
              if (context.read<ChatBloc>().isUserInChat) return;
              InAppNotificationService.show(
                context: context,
                title: 'TAFS Support',
                message: latest.content,
                onTap: () {
                  final chatBloc = context.read<ChatBloc>();
                  chatBloc.add(ChatEntered());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(isTab: false),
                    ),
                  ).then((_) {
                    chatBloc.add(ChatLeft());
                  });
                },
              );
            }
          },
        ),
      ],
      child: BlocBuilder<SelectedStudentCubit, Student?>(
        builder: (context, student) {
          if (student == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: StudentAppBar(
              student: student,
              actions: const [
                _ChatAppBarAction(),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeTabBody(
                  onSwitchToFees: () => _onTabTapped(1),
                ),
                FeeLedgerPage(
                  studentCc: student.cc,
                  studentName: student.fullName,
                  showAppBar: false,
                ),
                const FamilyProfilePage(showAppBar: false),
              ],
            ),
            bottomNavigationBar: _BottomNavBar(
              selectedIndex: _selectedIndex,
              onTap: _onTabTapped,
            ),
          );
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.blue100)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.white,
        selectedItemColor: AppTheme.navy,
        unselectedItemColor: AppTheme.blue300,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Fees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt_rounded),
            label: 'Family',
          ),
        ],
      ),
    );
  }
}

class _ChatAppBarAction extends StatelessWidget {
  const _ChatAppBarAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, chatState) {
        final unreadCount = chatState is ChatLoaded ? chatState.unreadCount : 0;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.navy,
                  size: 24,
                ),
                onPressed: () {
                  final chatBloc = context.read<ChatBloc>();
                  chatBloc.add(ChatEntered());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(isTab: false),
                    ),
                  ).then((_) {
                    chatBloc.add(ChatLeft());
                  });
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

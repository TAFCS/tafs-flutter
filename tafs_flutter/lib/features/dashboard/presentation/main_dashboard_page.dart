import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../notice_board/presentation/bloc/notice_board_bloc.dart';
import '../../notice_board/presentation/bloc/notice_board_event.dart';
import '../../notice_board/presentation/bloc/notice_board_state.dart';
import '../../notice_board/presentation/widgets/notice_post_card.dart';

class HomeTabBody extends StatefulWidget {
  const HomeTabBody({super.key});

  @override
  State<HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<HomeTabBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<NoticeBoardBloc>();
      if (bloc.state is NoticeBoardInitial) {
        bloc.add(const NoticeBoardLoadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NoticeBoardBloc>().add(const NoticeBoardLoadRequested());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.navy,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NoticeBoardSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeBoardSection extends StatelessWidget {
  const _NoticeBoardSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoticeBoardBloc, NoticeBoardState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state is NoticeBoardLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
                  child: CircularProgressIndicator(color: AppTheme.navy, strokeWidth: 2),
                ),
              )
            else if (state is NoticeBoardLoaded && state.posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
                child: Text(
                  'No notices at the moment.',
                  style: TextStyle(color: AppTheme.blue300, fontSize: 13),
                ),
              )
            else if (state is NoticeBoardLoaded)
              ...state.posts.map((post) => NoticePostCard(key: ValueKey(post.id), post: post))
            else if (state is NoticeBoardError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
                child: Text(
                  'Could not load notices.',
                  style: TextStyle(color: AppTheme.blue300, fontSize: 13),
                ),
              )
            else if (state is NoticeBoardInitial)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
                  child: CircularProgressIndicator(color: AppTheme.navy, strokeWidth: 2),
                ),
              ),
          ],
        );
      },
    );
  }
}

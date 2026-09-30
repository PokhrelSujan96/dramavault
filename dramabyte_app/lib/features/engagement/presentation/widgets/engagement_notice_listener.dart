import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EngagementNoticeListener extends StatelessWidget {
  const EngagementNoticeListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EngagementCubit, EngagementState>(
      listenWhen: (previous, state) =>
          state.noticeSeq != previous.noticeSeq && state.notice != null,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.notice!))),
      child: child,
    );
  }
}

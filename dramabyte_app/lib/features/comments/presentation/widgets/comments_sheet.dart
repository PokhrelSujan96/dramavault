import 'dart:math';

import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_args.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_composer.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_list.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comments_header.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:dramabyte_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showCommentsSheet(BuildContext context, Reel reel) {
  final profileState = context.read<ProfileCubit>().state;
  final profile = profileState is ResourceLoaded<UserProfile>
      ? profileState.value
      : null;
  final auth = context.read<AuthenticationBloc>().state;
  final args = CommentsArgs(
    episodeId: reel.episodeId,
    authorId: profile?.id ?? (auth is Authenticated ? auth.user.id : ''),
    authorName: profile?.name ?? 'You',
    authorAvatar: profile?.avatarUrl,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => CommentsSheet(args: args),
  );
}

class CommentsSheet extends StatelessWidget {
  const CommentsSheet({super.key, required this.args});

  final CommentsArgs args;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final screen = MediaQuery.sizeOf(context).height;
    return BlocProvider(
      create: (_) => getIt<CommentsCubit>(param1: args)..load(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: inset),
        child: SizedBox(
          height: min(screen * 0.75, screen - inset - 24.h),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: ScaffoldMessenger(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: false,
                  body: BlocListener<CommentsCubit, CommentsState>(
                    listenWhen: (previous, state) =>
                        state.noticeSeq != previous.noticeSeq &&
                        state.notice != null,
                    listener: (context, state) => ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.notice!))),
                    child: Column(
                      children: [
                        CommentsHeader(episodeId: args.episodeId),
                        const Expanded(child: CommentList()),
                        const CommentComposer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

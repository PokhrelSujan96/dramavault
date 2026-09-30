import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentComposer extends StatefulWidget {
  const CommentComposer({super.key});

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send(CommentsCubit cubit) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final error = await cubit.post(text);
    if (error == null || !mounted) return;
    if (_controller.text.isEmpty) _controller.text = text;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommentsCubit>();
    final color = Theme.of(context).colorScheme;
    return BlocListener<CommentsCubit, CommentsState>(
      listenWhen: (previous, state) =>
          state.replyTo != null && state.replyTo != previous.replyTo,
      listener: (_, _) => _focus.requestFocus(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.surface,
          border: Border(
            top: BorderSide(color: color.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocSelector<CommentsCubit, CommentsState, Comment?>(
                selector: (state) => state.replyTo,
                builder: (context, target) => AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: target == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: FlareText(
                                  'Replying to ${target.authorName}',
                                ).xs.grey.setMaxLines(1).ellipsis,
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: cubit.cancelReply,
                                icon: Icon(Icons.close, size: 16.sp),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 8.h),
                child: Row(
                  children: [
                    CommentAvatar(
                      name: cubit.args.authorName,
                      url: cubit.args.authorAvatar,
                      size: 32.w,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: color.surfaceContainerHighest,
                          hintText: 'Add comment...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        final enabled = value.text.trim().isNotEmpty;
                        return IconButton(
                          onPressed: enabled ? () => _send(cubit) : null,
                          icon: Icon(
                            Icons.send_rounded,
                            size: 24.sp,
                            color: enabled ? FlareColors.primary : Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

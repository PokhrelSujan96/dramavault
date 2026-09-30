import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentsHeader extends StatelessWidget {
  const CommentsHeader({super.key, required this.episodeId});

  final String episodeId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommentsCubit>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36.w,
          height: 4.h,
          margin: EdgeInsets.only(top: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(
          height: 48.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BlocSelector<EngagementCubit, EngagementState, int>(
                selector: (state) => state.of(episodeId).comments,
                builder: (context, count) => FlareText(
                  count == 1 ? '1 comment' : '${compactCount(count)} comments',
                ).sm.semiBold,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: BlocSelector<CommentsCubit, CommentsState, CommentSort>(
                  selector: (state) => state.sort,
                  builder: (context, sort) => PopupMenuButton<CommentSort>(
                    tooltip: 'Sort comments',
                    onSelected: cubit.setSort,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: CommentSort.top,
                        child: Text('Top comments'),
                      ),
                      PopupMenuItem(
                        value: CommentSort.newest,
                        child: Text('Newest'),
                      ),
                    ],
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FlareText(
                            sort == CommentSort.top ? 'Top' : 'Newest',
                          ).xs.grey.semiBold,
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18.sp,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.close, size: 20.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

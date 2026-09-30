import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentsEmptyView extends StatelessWidget {
  const CommentsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mode_comment_outlined, size: 44.sp, color: Colors.grey),
          SizedBox(height: 12.h),
          FlareText('No comments yet').lg.semiBold,
          SizedBox(height: 4.h),
          FlareText('Be the first to comment.').sm.grey,
        ],
      ),
    );
  }
}

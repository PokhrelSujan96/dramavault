import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchRecentList extends StatelessWidget {
  const SearchRecentList({
    super.key,
    required this.recents,
    required this.onPick,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> recents;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FlareText('Recent searches').lg.semiBold,
              GestureDetector(
                onTap: onClear,
                child: FlareText('Clear').sm.grey,
              ),
            ],
          ),
        ),
        for (final query in recents)
          InkWell(
            onTap: () => onPick(query),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18.sp, color: Colors.grey),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FlareText(query).base.setMaxLines(1).ellipsis,
                  ),
                  GestureDetector(
                    onTap: () => onRemove(query),
                    child: Icon(Icons.close, size: 16.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

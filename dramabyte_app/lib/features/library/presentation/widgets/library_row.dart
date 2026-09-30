import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LibraryRow extends StatelessWidget {
  const LibraryRow({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onRemove,
  });

  final LibraryItem item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.seriesId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              SizedBox(
                width: 72.w,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: FlareNetworkImage(
                      item.thumbnailUrl,
                      cacheWidth: 240,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlareText(item.title).lg.semiBold.setMaxLines(2).ellipsis,
                    SizedBox(height: 4.h),
                    FlareText(item.subtitle).sm.setColor(FlareColors.primary),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: FlareSvgIcon(
                  'bookmark_fill',
                  size: 22.sp,
                  color: FlareColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LibraryBookmarkButton extends StatelessWidget {
  const LibraryBookmarkButton({super.key, required this.item});

  final LibraryItem item;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, ResourceState<List<LibraryItem>>>(
      builder: (context, _) {
        final saved = context.read<LibraryCubit>().isSaved(item.seriesId);
        return GestureDetector(
          onTap: () => toggleLibrary(context, item),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black45,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: FlareSvgIcon(
                saved ? 'bookmark_fill' : 'bookmark_outline',
                key: ValueKey(saved),
                size: 20.sp,
                color: saved ? FlareColors.primary : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_action_button.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelBookmarkButton extends StatelessWidget {
  const ReelBookmarkButton({super.key, required this.reel});

  final Reel reel;

  LibraryItem get _item => LibraryItem(
    seriesId: reel.seriesId,
    title: reel.title,
    genre: reel.genre,
    thumbnailUrl: reel.thumbnailUrl,
    episodeCount: reel.publishedCount,
    savedAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, ResourceState<List<LibraryItem>>>(
      builder: (context, _) {
        final saved = context.read<LibraryCubit>().isSaved(reel.seriesId);
        return ReelActionButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: FlareSvgIcon(
              saved ? 'bookmark_fill' : 'bookmark_outline',
              key: ValueKey(saved),
              size: 23.sp,
              color: saved ? FlareColors.primary : Colors.white,
            ),
          ),
          label: saved ? 'Saved' : 'Save',
          onTap: () => toggleLibrary(context, _item),
        );
      },
    );
  }
}

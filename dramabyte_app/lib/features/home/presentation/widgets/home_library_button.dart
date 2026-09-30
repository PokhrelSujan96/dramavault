import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeLibraryButton extends StatelessWidget {
  const HomeLibraryButton({super.key, required this.card});

  final SeriesCard card;

  LibraryItem get _item => LibraryItem(
    seriesId: card.seriesId,
    title: card.title,
    genre: card.genre,
    thumbnailUrl: card.thumbnailUrl,
    episodeCount: card.episodeCount,
    freeEpisodeCount: card.freeEpisodeCount,
    savedAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, ResourceState<List<LibraryItem>>>(
      builder: (context, _) {
        final saved = context.read<LibraryCubit>().isSaved(card.seriesId);
        return GestureDetector(
          onTap: () => toggleLibrary(context, _item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: saved ? 0.9 : 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlareSvgIcon(
                  saved ? 'bookmark_fill' : 'bookmark_outline',
                  size: 16.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 8.w),
                FlareText(saved ? 'Saved' : 'Add to Library').sm.semiBold.white,
              ],
            ),
          ),
        );
      },
    );
  }
}

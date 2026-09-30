import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_open_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, this.suggestions = const []});

  final List<SearchSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w),
      child: SearchOpenContainer(
        suggestions: suggestions,
        closedColor: context.surfaceTint,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.r),
        ),
        closedBuilder: (context) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FlareSvgIcon('search', size: 15.sp),
                  SizedBox(width: 12.w),
                  FlareText('Search dramas or series').size(14.sp),
                ],
              ),
              Icon(MdiIcons.chevronRight),
            ],
          ),
        ),
      ),
    );
  }
}

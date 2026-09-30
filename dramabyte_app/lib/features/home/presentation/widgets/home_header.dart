import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_icon_button.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_open_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.suggestions = const []});

  final List<SearchSuggestion> suggestions;

  void _soon(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Coming soon')));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: SafeArea(
        child: Row(
          children: [
            FlareText(
              'DramaByte',
            ).xl3.semiBold.setColor(FlareColors.background),
            const Spacer(),
            // SearchOpenContainer(
            //   suggestions: suggestions,
            //   closedColor: Theme.of(
            //     context,
            //   ).colorScheme.surfaceContainerHighest,
            //   closedShape: const CircleBorder(),
            //   closedBuilder: (_) => SizedBox(
            //     width: 40.w,
            //     height: 40.w,
            //     child: Icon(MdiIcons.magnify, size: 20.sp),
            //   ),
            // ),
            SizedBox(width: 10.w),
            HomeIconButton(
              icon: MdiIcons.bellOutline,
              onTap: () => _soon(context),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: context.surfaceTint,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          FlareSvgIcon('search', size: 15.sp, color: scheme.onSurface),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              maxLength: 80,
              cursorColor: FlareColors.primary,
              style: TextStyle(color: scheme.onSurface, fontSize: 14.sp),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                hintText: 'Search dramas or series',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Icon(
                      Icons.close,
                      size: 18.sp,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

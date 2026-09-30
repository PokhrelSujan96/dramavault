import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

typedef Choice<T> = ({T value, String label});

Future<void> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<Choice<T>> choices,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 0.7.sh),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 12.h),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
              child: FlareText(title).xl.semiBold,
            ),
            for (final choice in choices)
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                title: FlareText(choice.label).base,
                trailing: choice.value == selected
                    ? Icon(
                        MdiIcons.check,
                        color: Theme.of(sheet).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  onSelected(choice.value);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

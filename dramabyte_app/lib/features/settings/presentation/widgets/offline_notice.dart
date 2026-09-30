import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final offline = context.select((ConsentCubit c) => c.state.offline);
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: offline
          ? Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              child: FlareText(
                context.l10n.savedOffline,
              ).sm.setColor(Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

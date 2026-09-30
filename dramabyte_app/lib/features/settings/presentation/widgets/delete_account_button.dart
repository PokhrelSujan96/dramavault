import 'package:dramabyte_app/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({
    super.key,
    required this.controller,
    required this.word,
  });

  final TextEditingController controller;
  final String word;

  @override
  Widget build(BuildContext context) {
    final working = context.select(
      (DeleteAccountCubit c) => c.state == DeleteStatus.working,
    );
    final error = Theme.of(context).colorScheme.error;
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        final armed = value.text.trim().toUpperCase() == word && !working;
        return FilledButton(
          style: FilledButton.styleFrom(backgroundColor: error),
          onPressed: armed ? context.read<DeleteAccountCubit>().confirm : null,
          child: working
              ? SizedBox.square(
                  dimension: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.deleteConfirm),
        );
      },
    );
  }
}

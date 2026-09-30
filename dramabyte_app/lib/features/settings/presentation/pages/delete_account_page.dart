import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/delete_account_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/delete_account_button.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  static const _word = 'DELETE';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return BlocProvider(
      create: (_) => getIt<DeleteAccountCubit>(),
      child: BlocListener<DeleteAccountCubit, DeleteStatus>(
        listener: (context, status) {
          if (status == DeleteStatus.done) {
            context.read<AuthenticationBloc>().add(const SignOutRequested());
          }
          if (status == DeleteStatus.failed) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.deleteAccount)),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(20.r),
              children: [
                Icon(MdiIcons.alertOutline, size: 44.r, color: scheme.error),
                SizedBox(height: 16.h),
                FlareText(
                  l10n.deleteWarning,
                ).base.setColor(scheme.onSurfaceVariant),
                SizedBox(height: 24.h),
                FlareText(l10n.deleteTypeToConfirm(_word)).sm.semiBold,
                SizedBox(height: 8.h),
                TextField(
                  controller: _controller,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: _word),
                ),
                SizedBox(height: 24.h),
                DeleteAccountButton(controller: _controller, word: _word),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

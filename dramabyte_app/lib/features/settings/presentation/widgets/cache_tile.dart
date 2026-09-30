import 'package:dramabyte_app/core/format/file_size.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/cache_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/clear_cache_dialog.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CacheTile extends StatelessWidget {
  const CacheTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<CacheCubit, CacheState>(
      builder: (context, state) {
        final bytes = state.bytes;
        return SettingsTile(
          icon: MdiIcons.broom,
          title: l10n.clearCache,
          subtitle: bytes == null
              ? l10n.cacheCalculating
              : l10n.clearCacheSize(formatBytes(bytes)),
          onTap: state.clearing ? null : () => _confirm(context),
        );
      },
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<CacheCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final done = context.l10n.clearCacheDone;
    if (!await showClearCacheDialog(context)) return;
    await cubit.clear();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }
}

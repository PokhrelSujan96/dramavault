import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

Future<bool> showClearCacheDialog(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.clearCache),
      content: Text(l10n.clearCacheBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(l10n.clear),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

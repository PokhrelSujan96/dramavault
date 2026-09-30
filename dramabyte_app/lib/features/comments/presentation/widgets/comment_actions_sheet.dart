import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const reportReasons = [
  'Spam',
  'Harassment or hate',
  'Inappropriate content',
  'Other',
];

Future<void> showCommentActions(
  BuildContext context,
  Comment comment,
  CommentsCubit cubit,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Copy'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: comment.body));
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.reply_outlined),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(sheetContext);
              cubit.startReply(comment);
            },
          ),
          if (comment.isMine)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                cubit.delete(comment);
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickReason(context, comment, cubit);
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _pickReason(
  BuildContext context,
  Comment comment,
  CommentsCubit cubit,
) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Why are you reporting this?')),
          for (final reason in reportReasons)
            ListTile(
              title: Text(reason),
              onTap: () {
                Navigator.pop(sheetContext);
                cubit.report(comment, reason);
              },
            ),
        ],
      ),
    ),
  );
}

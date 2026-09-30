String timeAgo(DateTime? time, {DateTime? now}) {
  if (time == null) return '';
  final elapsed = (now ?? DateTime.now()).difference(time);
  if (elapsed.inSeconds < 45) return 'now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d';
  if (elapsed.inDays < 30) return '${elapsed.inDays ~/ 7}w';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = time.toLocal();
  final sameYear = local.year == (now ?? DateTime.now()).year;
  return sameYear
      ? '${months[local.month - 1]} ${local.day}'
      : '${months[local.month - 1]} ${local.day}, ${local.year}';
}

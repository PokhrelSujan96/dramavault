import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';

class HistoryPage {
  const HistoryPage(this.items, this.nextCursor);

  final List<HistoryItem> items;
  final String? nextCursor;
}

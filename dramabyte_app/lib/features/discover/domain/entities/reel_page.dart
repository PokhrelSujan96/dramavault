import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';

class ReelPage {
  const ReelPage(this.items, this.nextCursor);

  final List<Reel> items;
  final String? nextCursor;
}

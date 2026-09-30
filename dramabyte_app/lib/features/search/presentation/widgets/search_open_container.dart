import 'package:animations/animations.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:dramabyte_app/features/search/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';

class SearchOpenContainer extends StatelessWidget {
  const SearchOpenContainer({
    super.key,
    required this.closedBuilder,
    required this.closedColor,
    required this.closedShape,
    this.suggestions = const [],
  });

  final WidgetBuilder closedBuilder;
  final Color closedColor;
  final ShapeBorder closedShape;
  final List<SearchSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 450),
      closedElevation: 0,
      openElevation: 0,
      closedColor: closedColor,
      openColor: background,
      middleColor: background,
      closedShape: closedShape,
      openShape: const RoundedRectangleBorder(),
      closedBuilder: (context, _) => closedBuilder(context),
      openBuilder: (context, close) =>
          SearchPage(onClose: () => close(), suggestions: suggestions),
    );
  }
}

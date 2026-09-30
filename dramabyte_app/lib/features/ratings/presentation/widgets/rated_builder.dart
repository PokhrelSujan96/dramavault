import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RatedBuilder extends StatelessWidget {
  const RatedBuilder({
    super.key,
    required this.target,
    required this.id,
    required this.fallback,
    required this.builder,
  });

  final RatingTarget target;
  final String id;
  final RatingSummary fallback;
  final Widget Function(BuildContext context, RatingSummary summary) builder;

  @override
  Widget build(BuildContext context) {
    final RatingsCubit cubit;
    try {
      cubit = context.read<RatingsCubit>();
    } on ProviderNotFoundException {
      return builder(context, fallback);
    }
    return BlocSelector<RatingsCubit, RatingsState, RatingSummary?>(
      bloc: cubit,
      selector: (state) => state.of(target, id),
      builder: (context, summary) => builder(context, summary ?? fallback),
    );
  }
}

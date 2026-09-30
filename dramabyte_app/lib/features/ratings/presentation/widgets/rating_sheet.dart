import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_score_star.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showRatingSheet(
  BuildContext context, {
  required RatingTarget target,
  required String id,
  required String title,
  String? subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RatingSheet(
      target: target,
      id: id,
      title: title,
      subtitle: subtitle,
      cubit: context.read<RatingsCubit>(),
    ),
  );
}

class RatingSheet extends StatefulWidget {
  const RatingSheet({
    super.key,
    required this.target,
    required this.id,
    required this.title,
    required this.cubit,
    this.subtitle,
  });

  final RatingTarget target;
  final String id;
  final String title;
  final String? subtitle;
  final RatingsCubit cubit;

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  late final int? _existing = widget.cubit.state
      .of(widget.target, widget.id)
      ?.myRating;
  late int? _value = _existing;

  Future<void> _commit(int? rating) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    final error = rating == null
        ? await widget.cubit.clear(widget.target, widget.id)
        : await widget.cubit.rate(widget.target, widget.id, rating);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ??
                (rating == null
                    ? 'Rating removed'
                    : 'You rated this $rating/10'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final changed = _value != null && _value != _existing;
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 20.h),
            FlareText('Rate this ${widget.target.name}').xl.semiBold,
            SizedBox(height: 4.h),
            FlareText(
              widget.subtitle ?? widget.title,
            ).sm.grey.center.setMaxLines(2).ellipsis,
            SizedBox(height: 20.h),
            RatingScoreStar(value: _value),
            SizedBox(height: 16.h),
            RatingStars(
              value: _value,
              onChanged: (v) => setState(() => _value = v),
            ),
            SizedBox(height: 4.h),
            FlareText(
              _value == null ? 'Tap or slide across the stars' : '$_value / 10',
            ).sm.grey,
            SizedBox(height: 20.h),
            FlareButton(
              label: changed
                  ? 'Rate $_value'
                  : (_existing == null ? 'Rate' : 'Update rating'),
              onPressed: changed ? () => _commit(_value) : null,
            ),
            if (_existing != null)
              TextButton(
                onPressed: () => _commit(null),
                child: const Text('Remove rating'),
              ),
          ],
        ),
      ),
    );
  }
}

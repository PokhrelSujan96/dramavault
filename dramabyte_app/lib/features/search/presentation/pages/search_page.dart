import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:dramabyte_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_body.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.onClose,
    this.suggestions = const [],
  });

  final VoidCallback onClose;
  final List<SearchSuggestion> suggestions;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final SearchCubit _cubit = getIt<SearchCubit>()..init();
  bool _focusScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusScheduled) return;
    _focusScheduled = true;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _focusNode.requestFocus();
      return;
    }
    void listener(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      animation.removeStatusListener(listener);
      if (mounted) _focusNode.requestFocus();
    }

    animation.addStatusListener(listener);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _cubit.close();
    super.dispose();
  }

  void _pickRecent(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    _cubit.submit(query);
  }

  void _openSeries(String seriesId) {
    _focusNode.unfocus();
    context.pushNamed(
      AppRoutes.seriesName,
      pathParameters: {'seriesId': seriesId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 8.h, 16.w, 8.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: SearchField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _cubit.onQueryChanged,
                        onSubmitted: _cubit.submit,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<SearchCubit, SearchState>(
                  builder: (context, state) => SearchBody(
                    state: state,
                    cubit: _cubit,
                    suggestions: widget.suggestions,
                    onPickRecent: _pickRecent,
                    onOpenSeries: _openSeries,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

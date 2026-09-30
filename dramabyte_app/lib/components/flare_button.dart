import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum FlareButtonVariant { primary, secondary, outline, ghost, danger }

class FlareButton extends StatelessWidget {
  const FlareButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = FlareButtonVariant.primary,
    this.icon,
    this.trailing,
    this.isLoading = false,
    this.expand = true,
    this.height,
    this.width,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final FlareButtonVariant variant;
  final Widget? icon;
  final Widget? trailing;
  final bool isLoading;
  final bool expand;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    final radius = borderRadius ?? BorderRadius.circular(12.r);
    final button = FilledButton(
      onPressed: _enabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, height ?? 52.h)),
        padding: WidgetStatePropertyAll(
          padding ?? EdgeInsets.symmetric(horizontal: 20.w),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? colors.background.withValues(alpha: 0.45)
              : colors.background,
        ),
        foregroundColor: WidgetStatePropertyAll(colors.foreground),
        overlayColor: WidgetStatePropertyAll(
          colors.foreground.withValues(alpha: 0.08),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: borderColor ?? Colors.black),
          ),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? SizedBox.square(
                key: const ValueKey('loader'),
                dimension: 20.r,
                child: CircularProgressIndicator(
                  color: colors.foreground,
                  strokeWidth: 2.2,
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          textStyle ??
                          TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
                ],
              ),
      ),
    );
    return SizedBox(
      width: width ?? (expand ? double.infinity : null),
      height: height ?? 52.h,
      child: button,
    );
  }

  _ButtonColors _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (backgroundColor != null || foregroundColor != null) {
      return _ButtonColors(
        backgroundColor ?? scheme.primary,
        foregroundColor ?? scheme.onPrimary,
        Colors.transparent,
      );
    }
    return switch (variant) {
      FlareButtonVariant.primary => const _ButtonColors(
        AppColors.primary,
        Colors.white,
        Colors.transparent,
      ),
      FlareButtonVariant.secondary => _ButtonColors(
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Colors.transparent,
      ),
      FlareButtonVariant.outline => _ButtonColors(
        Colors.transparent,
        scheme.onSurface,
        scheme.outline,
      ),
      FlareButtonVariant.ghost => _ButtonColors(
        Colors.transparent,
        scheme.primary,
        Colors.transparent,
      ),
      FlareButtonVariant.danger => const _ButtonColors(
        AppColors.error,
        Colors.white,
        Colors.transparent,
      ),
    };
  }
}

class _ButtonColors {
  const _ButtonColors(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color border;
}

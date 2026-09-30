import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FlareText extends StatefulWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final List<Shadow>? shadows;
  final String? fontFamily;
  final FontStyle? fontStyle;
  final TextBaseline? textBaseline;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selectable;
  final bool copyable;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final bool readMore;
  final int? readMoreMaxLines;
  final String? readMoreText;
  final String? readLessText;
  final TextStyle? readMoreTextStyle;
  final Color? readMoreColor;

  const FlareText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
    this.fontFamily,
    this.fontStyle,
    this.textBaseline,
    this.onTap,
    this.onLongPress,
    this.selectable = false,
    this.copyable = false,
    this.gradient,
    this.padding,
    this.readMore = false,
    this.readMoreMaxLines = 3,
    this.readMoreText = 'Read more',
    this.readLessText = 'Read less',
    this.readMoreTextStyle,
    this.readMoreColor,
  });

  // app Theme Colors
  static const Color appPrimary = Color(0xFFE8553E);
  static const Color appPrimaryDark = Color(0xFFD14836);
  static const Color appPrimaryLight = Color(0xFFF07A6A);
  static const Color appBackground = Color(0xFFF5F3EF);
  static const Color appSurface = Color(0xFFFFFFFF);
  static const Color appTextPrimary = Color.fromARGB(255, 0, 0, 0);
  static const Color appTextSecondary = Color(0xFF6B6B6B);
  static const Color appTextTertiary = Color(0xFF9B9B9B);
  static const Color appTextInverse = Color(0xFFFFFFFF);
  static const Color appAccentRose = Color(0xFFC4A484);
  static const Color appAccentGold = Color(0xFFD4A574);
  static const Color appAccentGreen = Color(0xFF7CB69D);
  static const Color appError = Color(0xFFE8553E);
  static const Color appSuccess = Color(0xFF7CB69D);
  static const Color appDivider = Color(0xFFEBE8E3);

  // Default Inter text style
  // ignore: unused_element
  static TextStyle get _interStyle => GoogleFonts.inter();

  FlareText _copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    bool? softWrap,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<Shadow>? shadows,
    String? fontFamily,
    FontStyle? fontStyle,
    TextBaseline? textBaseline,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool? selectable,
    bool? copyable,
    Gradient? gradient,
    EdgeInsetsGeometry? padding,
    bool? readMore,
    int? readMoreMaxLines,
    String? readMoreText,
    String? readLessText,
    TextStyle? readMoreTextStyle,
    Color? readMoreColor,
  }) => FlareText(
    text,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    color: color ?? this.color,
    textAlign: textAlign ?? this.textAlign,
    overflow: overflow ?? this.overflow,
    maxLines: maxLines ?? this.maxLines,
    softWrap: softWrap ?? this.softWrap,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    wordSpacing: wordSpacing ?? this.wordSpacing,
    height: height ?? this.height,
    decoration: decoration ?? this.decoration,
    decorationColor: decorationColor ?? this.decorationColor,
    decorationStyle: decorationStyle ?? this.decorationStyle,
    decorationThickness: decorationThickness ?? this.decorationThickness,
    shadows: shadows ?? this.shadows,
    fontFamily: fontFamily ?? this.fontFamily,
    fontStyle: fontStyle ?? this.fontStyle,
    textBaseline: textBaseline ?? this.textBaseline,
    onTap: onTap ?? this.onTap,
    onLongPress: onLongPress ?? this.onLongPress,
    selectable: selectable ?? this.selectable,
    copyable: copyable ?? this.copyable,
    gradient: gradient ?? this.gradient,
    padding: padding ?? this.padding,
    readMore: readMore ?? this.readMore,
    readMoreMaxLines: readMoreMaxLines ?? this.readMoreMaxLines,
    readMoreText: readMoreText ?? this.readMoreText,
    readLessText: readLessText ?? this.readLessText,
    readMoreTextStyle: readMoreTextStyle ?? this.readMoreTextStyle,
    readMoreColor: readMoreColor ?? this.readMoreColor,
  );

  FlareText size(double fontSize) => _copyWith(fontSize: fontSize);
  FlareText get xs => size(10);
  FlareText get sm => size(12);
  FlareText get base => size(14);
  FlareText get lg => size(16);
  FlareText get xl => size(18);
  FlareText get xl2 => size(20);
  FlareText get xl3 => size(24);
  FlareText get xl4 => size(28);
  FlareText get xl5 => size(32);
  FlareText get xl6 => size(36);

  FlareText weight(int weight) {
    switch (weight) {
      case 100:
        return _copyWith(fontWeight: FontWeight.w100);
      case 200:
        return _copyWith(fontWeight: FontWeight.w200);
      case 300:
        return _copyWith(fontWeight: FontWeight.w300);
      case 400:
        return _copyWith(fontWeight: FontWeight.w400);
      case 500:
        return _copyWith(fontWeight: FontWeight.w500);
      case 600:
        return _copyWith(fontWeight: FontWeight.w600);
      case 700:
        return _copyWith(fontWeight: FontWeight.w700);
      case 800:
        return _copyWith(fontWeight: FontWeight.w800);
      case 900:
        return _copyWith(fontWeight: FontWeight.w900);
      default:
        return _copyWith(fontWeight: FontWeight.normal);
    }
  }

  FlareText get thin => weight(100);
  FlareText get extraLight => weight(200);
  FlareText get light => weight(300);
  FlareText get normal => weight(400);
  FlareText get medium => weight(500);
  FlareText get semiBold => weight(600);
  FlareText get bold => weight(700);
  FlareText get extraBold => weight(800);

  FlareText setColor(Color color) => _copyWith(color: color);
  FlareText get white => setColor(Colors.white);
  FlareText get black => setColor(Colors.black);
  FlareText get grey => setColor(Colors.grey);
  FlareText get red => setColor(Colors.red);
  FlareText get blue => setColor(Colors.blue);
  FlareText get green => setColor(Colors.green);
  FlareText get yellow => setColor(Colors.yellow);
  FlareText get orange => setColor(Colors.orange);
  FlareText get purple => setColor(Colors.purple);
  FlareText get pink => setColor(Colors.pink);
  FlareText get teal => setColor(Colors.teal);
  FlareText get cyan => setColor(Colors.cyan);
  FlareText get indigo => setColor(Colors.indigo);

  // app theme color shortcuts
  FlareText get appPrimaryColor => setColor(appPrimary);
  FlareText get appPrimaryDarkColor => setColor(appPrimaryDark);
  FlareText get appPrimaryLightColor => setColor(appPrimaryLight);
  FlareText get appTextPrimaryColor =>
      setColor(const Color.fromARGB(255, 0, 0, 0));
  FlareText get appTextSecondaryColor => setColor(appTextSecondary);
  FlareText get appTextTertiaryColor => setColor(appTextTertiary);
  FlareText get appTextInverseColor => setColor(appTextInverse);
  FlareText get appAccentRoseColor => setColor(appAccentRose);
  FlareText get appAccentGoldColor => setColor(appAccentGold);
  FlareText get appAccentGreenColor => setColor(appAccentGreen);
  FlareText get appErrorColor => setColor(appError);
  FlareText get appSuccessColor => setColor(appSuccess);

  FlareText align(TextAlign alignment) => _copyWith(textAlign: alignment);
  FlareText get center => align(TextAlign.center);
  FlareText get left => align(TextAlign.left);
  FlareText get right => align(TextAlign.right);
  FlareText get justify => align(TextAlign.justify);
  FlareText get start => align(TextAlign.start);
  FlareText get end => align(TextAlign.end);

  FlareText setDecoration(TextDecoration decoration) =>
      _copyWith(decoration: decoration);
  FlareText get underline => setDecoration(TextDecoration.underline);
  FlareText get overline => setDecoration(TextDecoration.overline);
  FlareText get lineThrough => setDecoration(TextDecoration.lineThrough);
  FlareText get noDecoration => setDecoration(TextDecoration.none);

  FlareText setDecorationColor(Color color) =>
      _copyWith(decorationColor: color);
  FlareText setDecorationStyle(TextDecorationStyle style) =>
      _copyWith(decorationStyle: style);
  FlareText setDecorationThickness(double thickness) =>
      _copyWith(decorationThickness: thickness);

  FlareText setFontStyle(FontStyle style) => _copyWith(fontStyle: style);
  FlareText get italic => setFontStyle(FontStyle.italic);
  FlareText get upright => setFontStyle(FontStyle.normal);

  FlareText setFontFamily(String family) => _copyWith(fontFamily: family);

  FlareText setLetterSpacing(double spacing) =>
      _copyWith(letterSpacing: spacing);
  FlareText setWordSpacing(double spacing) => _copyWith(wordSpacing: spacing);
  FlareText setHeight(double height) => _copyWith(height: height);

  FlareText setOverflow(TextOverflow overflow) => _copyWith(overflow: overflow);
  FlareText get ellipsis => setOverflow(TextOverflow.ellipsis);
  FlareText get clip => setOverflow(TextOverflow.clip);
  FlareText get fade => setOverflow(TextOverflow.fade);
  FlareText get visible => setOverflow(TextOverflow.visible);

  FlareText setMaxLines(int lines) => _copyWith(maxLines: lines);
  FlareText setSoftWrap(bool wrap) => _copyWith(softWrap: wrap);

  FlareText setOnTap(VoidCallback callback) => _copyWith(onTap: callback);
  FlareText setOnLongPress(VoidCallback callback) =>
      _copyWith(onLongPress: callback);
  FlareText get selectable_ => _copyWith(selectable: true);
  FlareText get copyable_ => _copyWith(copyable: true);

  FlareText shadow({
    Color color = Colors.black54,
    double blurRadius = 1.0,
    Offset offset = const Offset(1, 1),
  }) => _copyWith(
    shadows: [Shadow(color: color, blurRadius: blurRadius, offset: offset)],
  );

  FlareText setShadows(List<Shadow> shadows) => _copyWith(shadows: shadows);

  FlareText setGradient(Gradient gradient) => _copyWith(gradient: gradient);
  FlareText linearGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.centerLeft,
    AlignmentGeometry end = Alignment.centerRight,
  }) => setGradient(LinearGradient(colors: colors, begin: begin, end: end));

  FlareText radialGradient({
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 0.5,
  }) => setGradient(
    RadialGradient(colors: colors, center: center, radius: radius),
  );

  FlareText setPadding(EdgeInsetsGeometry padding) =>
      _copyWith(padding: padding);
  FlareText p(double padding) => _copyWith(padding: EdgeInsets.all(padding));
  FlareText px(double padding) =>
      _copyWith(padding: EdgeInsets.symmetric(horizontal: padding));
  FlareText py(double padding) =>
      _copyWith(padding: EdgeInsets.symmetric(vertical: padding));
  FlareText pl(double padding) =>
      _copyWith(padding: EdgeInsets.only(left: padding));
  FlareText pr(double padding) =>
      _copyWith(padding: EdgeInsets.only(right: padding));
  FlareText pt(double padding) =>
      _copyWith(padding: EdgeInsets.only(top: padding));
  FlareText pb(double padding) =>
      _copyWith(padding: EdgeInsets.only(bottom: padding));

  FlareText get p0 => p(0);
  FlareText get p1 => p(4);
  FlareText get p2 => p(8);
  FlareText get p3 => p(12);
  FlareText get p4 => p(16);
  FlareText get p5 => p(20);
  FlareText get p6 => p(24);
  FlareText get p8 => p(32);
  FlareText get p10 => p(40);
  FlareText get p12 => p(48);

  // Read More feature methods
  FlareText get readMore_ => _copyWith(readMore: true);
  FlareText setReadMoreMaxLines(int lines) =>
      _copyWith(readMoreMaxLines: lines);
  FlareText setReadMoreText(String text) => _copyWith(readMoreText: text);
  FlareText setReadLessText(String text) => _copyWith(readLessText: text);
  FlareText setReadMoreTextStyle(TextStyle style) =>
      _copyWith(readMoreTextStyle: style);
  FlareText setReadMoreColor(Color color) => _copyWith(readMoreColor: color);

  @override
  State<FlareText> createState() => _FlareTextState();
}

class _FlareTextState extends State<FlareText> {
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showCopyMenu(BuildContext context, TapDownDetails details) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          onTap: () => _copyToClipboard(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.fontFamily != null
        ? TextStyle(
            fontFamily: widget.fontFamily,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: widget.gradient == null ? widget.color : null,
            letterSpacing: widget.letterSpacing ?? -0.5,
            wordSpacing: widget.wordSpacing,
            height: widget.height,
            decoration: widget.decoration,
            decorationColor: widget.decorationColor,
            decorationStyle: widget.decorationStyle,
            decorationThickness: widget.decorationThickness,
            shadows: widget.shadows,
            fontStyle: widget.fontStyle,
            textBaseline: widget.textBaseline,
          )
        : GoogleFonts.inter(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: widget.gradient == null ? widget.color : null,
            letterSpacing: widget.letterSpacing ?? -0.5,
            wordSpacing: widget.wordSpacing,
            height: widget.height,
            decoration: widget.decoration,
            decorationColor: widget.decorationColor,
            decorationStyle: widget.decorationStyle,
            decorationThickness: widget.decorationThickness,
            shadows: widget.shadows,
            fontStyle: widget.fontStyle,
            textBaseline: widget.textBaseline,
          );
    Widget textWidget;

    if (widget.readMore) {
      textWidget = _buildReadMoreText(context, textStyle);
    } else if (widget.gradient != null) {
      textWidget = ShaderMask(
        shaderCallback: (bounds) => widget.gradient!.createShader(bounds),
        child: Text(
          widget.text,
          style: textStyle.copyWith(color: Colors.white),
          textAlign: widget.textAlign,
          overflow: widget.overflow,
          maxLines: widget.maxLines,
          softWrap: widget.softWrap,
        ),
      );
    } else if (widget.selectable) {
      textWidget = TapRegion(
        onTapOutside: (_) => _focusNode.unfocus(),
        child: SelectableText(
          widget.text,
          style: textStyle,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          onTap: widget.onTap,
          focusNode: _focusNode,
          contextMenuBuilder: (context, editableTextState) {
            return AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            );
          },
        ),
      );
    } else {
      textWidget = Text(
        widget.text,
        style: textStyle,
        textAlign: widget.textAlign,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
        softWrap: widget.softWrap,
      );
    }

    if (widget.copyable && !widget.selectable && !widget.readMore) {
      textWidget = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress ?? () => _copyToClipboard(context),
        onSecondaryTapDown: (details) => _showCopyMenu(context, details),
        child: textWidget,
      );
    } else if ((widget.onTap != null || widget.onLongPress != null) &&
        !widget.readMore) {
      textWidget = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: textWidget,
      );
    }

    if (widget.padding != null) {
      textWidget = Padding(padding: widget.padding!, child: textWidget);
    }

    return textWidget;
  }

  Widget _buildReadMoreText(BuildContext context, TextStyle textStyle) {
    final readMoreStyle =
        widget.readMoreTextStyle ??
        textStyle.copyWith(
          color: widget.readMoreColor ?? FlareText.appPrimary,
          fontWeight: FontWeight.w600,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: widget.textAlign ?? TextAlign.start,
          textDirection: TextDirection.ltr,
          maxLines: widget.readMoreMaxLines,
        );
        textPainter.layout(maxWidth: constraints.maxWidth);

        final needsReadMore = textPainter.didExceedMaxLines;

        if (!needsReadMore) {
          // Text doesn't exceed max lines, show as normal
          if (widget.gradient != null) {
            return ShaderMask(
              shaderCallback: (bounds) => widget.gradient!.createShader(bounds),
              child: Text(
                widget.text,
                style: textStyle.copyWith(color: Colors.white),
                textAlign: widget.textAlign,
              ),
            );
          }
          return Text(
            widget.text,
            style: textStyle,
            textAlign: widget.textAlign,
          );
        }

        if (_isExpanded) {
          // Show full text with "Read less" button
          return Column(
            crossAxisAlignment: widget.textAlign == TextAlign.center
                ? CrossAxisAlignment.center
                : widget.textAlign == TextAlign.right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (widget.gradient != null)
                ShaderMask(
                  shaderCallback: (bounds) =>
                      widget.gradient!.createShader(bounds),
                  child: Text(
                    widget.text,
                    style: textStyle.copyWith(color: Colors.white),
                    textAlign: widget.textAlign,
                  ),
                )
              else
                Text(
                  widget.text,
                  style: textStyle,
                  textAlign: widget.textAlign,
                ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = false),
                child: Text(
                  widget.readLessText ?? 'Read less',
                  style: readMoreStyle,
                ),
              ),
            ],
          );
        } else {
          // Show truncated text with "Read more" button
          return Column(
            crossAxisAlignment: widget.textAlign == TextAlign.center
                ? CrossAxisAlignment.center
                : widget.textAlign == TextAlign.right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (widget.gradient != null)
                ShaderMask(
                  shaderCallback: (bounds) =>
                      widget.gradient!.createShader(bounds),
                  child: Text(
                    widget.text,
                    style: textStyle.copyWith(color: Colors.white),
                    textAlign: widget.textAlign,
                    maxLines: widget.readMoreMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  widget.text,
                  style: textStyle,
                  textAlign: widget.textAlign,
                  maxLines: widget.readMoreMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = true),
                child: Text(
                  widget.readMoreText ?? 'Read more',
                  style: readMoreStyle,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

extension FlareTextExtension on String {
  FlareText get text => FlareText(this);
}

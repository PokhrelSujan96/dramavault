import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchHighlightedText extends StatelessWidget {
  const SearchHighlightedText({
    super.key,
    required this.text,
    required this.query,
  });

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500);
    final at = query.isEmpty
        ? -1
        : text.toLowerCase().indexOf(query.toLowerCase());
    if (at < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, at)),
          TextSpan(
            text: text.substring(at, at + query.length),
            style: const TextStyle(color: Color(0xFFE8553E)),
          ),
          TextSpan(text: text.substring(at + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

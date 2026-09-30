import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardPlaceholderPage extends StatelessWidget {
  const DashboardPlaceholderPage({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.sp, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 16.h),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          SizedBox(height: 8.h),
          const Text('Your drama journey starts here.'),
        ],
      ),
    ),
  );
}

import 'package:dramabyte_app/core/router/app_links.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';

String? authRedirect({
  required bool signedIn,
  required String matchedLocation,
  required Uri uri,
}) {
  final atRoot = matchedLocation == AppRoutes.root;
  if (signedIn && atRoot) {
    return AppLinks.safeNext(uri.queryParameters[AppLinks.nextParam]) ??
        AppRoutes.dashboard;
  }
  if (!signedIn && !atRoot) {
    return Uri(
      path: AppRoutes.root,
      queryParameters: {AppLinks.nextParam: uri.toString()},
    ).toString();
  }
  return null;
}

import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternal(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } on Object {
    return false;
  }
}

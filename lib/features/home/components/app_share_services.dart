import 'dart:io';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  AppShareService._();

  static const String iosAppUrl =
      'https://apps.apple.com/app/live-satellite-view-gps-map/id6756287339';


  static const String appName = 'Live Satellite View & GPS Map';

  static Future<void> shareApp() async {
    final String appUrl = Platform.isIOS
        ? iosAppUrl
        : 'androidAppUrl';

    final String message =
        'Check out $appName!\n\n'
        'Explore satellite maps, GPS location, routes and more.\n\n'
        'Download the app:\n$appUrl';

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: appName,
      ),
    );
  }
}
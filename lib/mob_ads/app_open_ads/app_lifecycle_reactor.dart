import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:satellite_view/mob_ads/app_open_ads/open_app_ad_mob.dart';


class AppLifecycleReactor {
  AppLifecycleReactor._();

  static void startListening() {
    AppStateEventNotifier.startListening();

    AppStateEventNotifier.appStateStream.listen(
          (state) {
        if (state == AppState.foreground) {
          AppOpenAdMob.showAppOpenAd();
        }
      },
    );
  }
}
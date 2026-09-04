import 'dart:developer';

import 'package:firebase_remote_config/firebase_remote_config.dart';

class FirebaseRemoteConfigration {
  FirebaseRemoteConfigration._();

  static final firebaseRemoteConfig = FirebaseRemoteConfig.instance;

  static const _defaultValues = {
    "show_banner_ads": true,
    "show_interstitial_ads": true,
    "show_app_open_ads": true,
    "ios_app_open_ads_unit_id": "ca-app-pub-9286034634524758/2443531205",
    "ios_banner_ads_unit_id": "ca-app-pub-9286034634524758/9008939558",
    "ios_interstitial_ads_unit_id": "ca-app-pub-9286034634524758/2918281720",
  };

  static Future<void> initFirebaseRemoteConfig() async {
    try {
      await firebaseRemoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(minutes: 30),
        ),
      );

      await firebaseRemoteConfig.setDefaults(_defaultValues);

      await firebaseRemoteConfig.fetchAndActivate();

      log(
        'The remote config data app open ad: ${firebaseRemoteConfig.getBool('show_app_open_ads')}',
      );
      log(
        'The remote config data banner: ${firebaseRemoteConfig.getBool('show_banner_ads')}',
      );
      log(
        'The remote config data interstitial: ${firebaseRemoteConfig.getBool('show_interstitial_ads')}',
      );

      firebaseRemoteConfig.onConfigUpdated.listen((update) async {
        try {
          await firebaseRemoteConfig.activate();
          log(
            'The update app open ad: ${firebaseRemoteConfig.getBool('show_app_open_ads')}',
          );
          log(
            'The updated banner: ${firebaseRemoteConfig.getBool('show_banner_ads')}',
          );
          log(
            'The updated interstitial: ${firebaseRemoteConfig.getBool('show_interstitial_ads')}',
          );
        } catch (e) {
          log('Failed to activate updated remote config: $e');
        }
      });
    } catch (e) {
      // Network or config errors shouldn't crash the app; default values will be used.
      log('Failed to init or fetch Firebase Remote Config: $e');
    }
  }

  /// App Open Ad's
  /// static String get androidAppOpenAdsUnitId => firebaseRemoteConfig.getString('android_app_open_ads_unit_id');
  static String get iOSAppOpenAdsUnitId =>
      firebaseRemoteConfig.getString('ios_app_open_ads_unit_id');
  static bool get showAppOpenAds =>
      firebaseRemoteConfig.getBool('show_app_open_ads');

  /// Banner Ad's
  /// static String get androidBannerAdsUnitId => firebaseRemoteConfig.getString('android_banner_ads_unit_id');
  static String get iOSBannerAdsUnitId =>
      firebaseRemoteConfig.getString('ios_banner_ads_unit_id');
  static bool get showBannerAds =>
      firebaseRemoteConfig.getBool('show_banner_ads');

  /// Interstitial Ad's
  /// static String get androidInterstitialAdsUnitId => firebaseRemoteConfig.getString('android_interstitial_ads_unit_id');
  static String get iOSInterstitialAdsUnitId =>
      firebaseRemoteConfig.getString('ios_interstitial_ads_unit_id');
  static bool get showInterstitialAds =>
      firebaseRemoteConfig.getBool('show_interstitial_ads');
}

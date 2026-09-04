import 'dart:io';

import 'package:satellite_view/mob_ads/firebase_remote_configration/firebase_remote_configration.dart';

class AdHelper {
  AdHelper._();

  static String appOpenAdsUnitId() {
    if (Platform.isIOS) {
      return FirebaseRemoteConfigration.iOSAppOpenAdsUnitId;
    } else {
      return "";
    }
  }

  static String bannerAdsUnitId() {
    if (Platform.isIOS) {
      return FirebaseRemoteConfigration.iOSBannerAdsUnitId;
    } else {
      return "";
    }
  }

  static String interstitialAdsUnitId() {
    if (Platform.isIOS) {
      return FirebaseRemoteConfigration.iOSInterstitialAdsUnitId;
    } else {
      return "";
    }
  }
}

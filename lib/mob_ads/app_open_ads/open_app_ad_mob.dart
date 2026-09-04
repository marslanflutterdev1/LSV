import 'dart:developer';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_helper.dart';
import '../firebase_remote_configration/firebase_remote_configration.dart';

class AppOpenAdMob {
  AppOpenAdMob._();

  static AppOpenAd? _appOpenAd;

  static bool _isLoadingAd = false;
  static bool _isShowingAd = false;

  static DateTime? _loadTime;

  static const Duration maxCacheDuration = Duration(hours: 4);

  static bool get isAdAvailable => _appOpenAd != null;

  static bool get isAdExpired {
    if (_loadTime == null) {
      return true;
    }

    return DateTime.now()
        .difference(_loadTime!)
        .compareTo(maxCacheDuration) > 0;
  }

  static void loadAppOpenAd() {
    if (_isLoadingAd || _appOpenAd != null) {
      return;
    }

    _isLoadingAd = true;

    log(
      'Loading App Open Ad: ${AdHelper.appOpenAdsUnitId()}',
    );

    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdsUnitId(),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          log('App Open Ad Loaded');

          _appOpenAd = ad;
          _loadTime = DateTime.now();

          _isLoadingAd = false;
        },
        onAdFailedToLoad: (error) {
          log(
            'App Open Ad Failed To Load: $error',
          );

          _appOpenAd = null;
          _isLoadingAd = false;
        },
      ),
    );
  }

  static void showAppOpenAd() {
    if (!FirebaseRemoteConfigration.showAppOpenAds) {
      return;
    }

    if (_isShowingAd) {
      log('App Open Ad already showing');
      return;
    }

    if (_appOpenAd == null) {
      log('No App Open Ad available');

      loadAppOpenAd();
      return;
    }

    if (isAdExpired) {
      log('App Open Ad expired');

      _appOpenAd?.dispose();
      _appOpenAd = null;

      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            log('App Open Ad Shown');

            _isShowingAd = true;
          },
          onAdDismissedFullScreenContent: (ad) {
            log('App Open Ad Dismissed');

            ad.dispose();

            _appOpenAd = null;
            _isShowingAd = false;
            _loadTime = null;

            loadAppOpenAd();
          },
          onAdFailedToShowFullScreenContent:
              (ad, error) {
            log(
              'App Open Ad Failed To Show: $error',
            );

            ad.dispose();

            _appOpenAd = null;
            _isShowingAd = false;
            _loadTime = null;

            loadAppOpenAd();
          },
        );

    _appOpenAd!.show();
  }

  static void dispose() {
    _appOpenAd?.dispose();

    _appOpenAd = null;
    _loadTime = null;

    _isLoadingAd = false;
    _isShowingAd = false;
  }
}
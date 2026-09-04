import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:satellite_view/mob_ads/ad_helper.dart';
import 'package:satellite_view/mob_ads/firebase_remote_configration/firebase_remote_configration.dart';

class InterstitialAdMob {
  InterstitialAdMob._();

  static InterstitialAd? interstitialAd;
  static bool isLoadedInterstitialAd = false;
  static Timer? _retryTimer;
  static int _retryAttempt = 0;

  static bool get isReady => interstitialAd != null;

  static void loadInterstitialAd() {
    if (isLoadedInterstitialAd || interstitialAd != null) {
      return;
    }

    isLoadedInterstitialAd = true;

    log(
      'Remotely Interstitial Ads Unit Id: ${AdHelper.interstitialAdsUnitId()}',
    );

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdsUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          log('Interstitial loaded');
          _retryTimer?.cancel();
          _retryTimer = null;
          _retryAttempt = 0;
          interstitialAd = ad;
          isLoadedInterstitialAd = false;
          // Keep immersive mode off so the ad's close button is visible
          ad.setImmersiveMode(true);
        },

        onAdFailedToLoad: (LoadAdError error) {
          log('Interstitial failed to load: $error');
          interstitialAd = null;
          isLoadedInterstitialAd = false;
          _scheduleRetry();
        },
      ),
    );
  }

  static void _scheduleRetry() {
    _retryTimer?.cancel();
    final delaySeconds = 5 * (1 << _retryAttempt.clamp(0, 5));
    _retryAttempt = (_retryAttempt + 1).clamp(0, 6);
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      _retryTimer = null;
      loadInterstitialAd();
    });
  }

  static void showInterstitialAd({required VoidCallback onComplete}) {
    if (!FirebaseRemoteConfigration.showInterstitialAds) {
      onComplete();
      return;
    }

    final ad = interstitialAd;
    if (ad == null) {
      onComplete();
      loadInterstitialAd();
      return;
    }

    /// Prevent duplicate show attempts
    interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        log('Interstitial showed');
      },

      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        log('Interstitial dismissed');

        ad.dispose();

        onComplete();

        loadInterstitialAd();
      },

      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        log('Interstitial failed to show: $error');

        ad.dispose();

        onComplete();

        loadInterstitialAd();
      },

      onAdImpression: (InterstitialAd ad) {
        log('Interstitial impression');
      },

      onAdClicked: (InterstitialAd ad) {
        log('Interstitial clicked');
      },
    );

    ad.show();
  }

  static void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    interstitialAd?.dispose();
    interstitialAd = null;
    isLoadedInterstitialAd = false;
    _retryAttempt = 0;
  }
}

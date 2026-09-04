import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:satellite_view/mob_ads/ad_helper.dart';
import 'package:satellite_view/mob_ads/firebase_remote_configration/firebase_remote_configration.dart';

class BannerAdmob extends StatefulWidget {
  const BannerAdmob({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BannerAdmobState();
  }
}

class _BannerAdmobState extends State<BannerAdmob> {
  late BannerAd bannerAd;
  bool isLoadedBannerAd = false;

  Future<AdSize> bannerAdSize() async {
    try {
      final width = ui.window.physicalSize.width / ui.window.devicePixelRatio;
      final int widthInt = width.truncate();
      final AdSize? adaptive =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            widthInt,
          );
      return adaptive ?? AdSize.banner;
    } catch (e) {
      log('Adaptive size computation failed: $e');
      return AdSize.banner;
    }
  }

  @override
  void initState() {
    loadBannerAd();
    super.initState();
  }

  Future<void> loadBannerAd() async {
    final size = await bannerAdSize();
    log('Remotely Banner Ads Unit Id: ${AdHelper.bannerAdsUnitId()}');
    bannerAd = BannerAd(
      // adUnitId: "ca-app-pub-3940256099942544/6300978111",
      adUnitId: AdHelper.bannerAdsUnitId(),
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isLoadedBannerAd = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          setState(() {
            isLoadedBannerAd = false;
          });
          log('BannerAd failed to load: ${err.code} ${err.message}');
          ad.dispose();
        },
      ),
    );
    await bannerAd.load();
  }

  @override
  void dispose() {
    super.dispose();
    bannerAd.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FirebaseRemoteConfigration.showBannerAds) {
      return const SizedBox.shrink();
    }

    if (!isLoadedBannerAd) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}

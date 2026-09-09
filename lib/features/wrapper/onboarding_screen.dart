import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/interstitial_ad_mob.dart';
import '../../../../widgets/custom_button.dart';
import '../../mob_ads/interstitial_ads/ad_frequency_manager.dart';
import '../bottom_nav_bar/bottom_nav_bar_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    /// Interstitial Ad Mob Load
    InterstitialAdMob.loadInterstitialAd();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

     return SafeArea(
      top: false,
      child: Scaffold(
        body: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              top: -10,
              left: -160,
              child: Row(
                children: [
                  ScrollingImages(startingIndex: 0),
                  ScrollingImages(startingIndex: 1),
                  ScrollingImages(startingIndex: 2),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height <= 700 ? 20 : 50,
              child: Text(
                "Live Satellite View",
                textScaleFactor: 2.0,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: CustomColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height <= 700
                    ? h * 0.55
                    : h * 0.54,
                width: w,
                decoration: BoxDecoration(
                  // color: Theme.of(context).colorScheme.onPrimaryContainer,
                  color: Colors.white,
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      // Theme.of(context).colorScheme.onPrimaryContainer,
                      // Theme.of(context).colorScheme.onPrimaryContainer,
                      // Theme.of(context).colorScheme.onPrimaryContainer,
                      Colors.white,
                      Colors.white,
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                  ),
                ),
                // child: Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 8),
                //   child: Column(
                //     spacing: 5,
                //     children: [
                //       // const Spacer(),
                //       Text(
                //         "Welcome To Satellite View\nCommunity🎉",
                //         textScaleFactor: 2,
                //         textAlign: TextAlign.center,
                //         style: Theme.of(context).textTheme.bodySmall
                //             ?.copyWith(
                //           color: CustomColors.primaryColor,
                //           fontSize: 10,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //       SizedBox(height: 10),
                //       buildRow(
                //         context,
                //         text:
                //         "The Live Satellite View app delivers ultra-high-resolution real-time satellite imagery, enabling users to explore any location on Earth with smooth zoom and pan controls.",
                //       ),
                //       buildRow(
                //         context,
                //         text:
                //         "Track moving objects like vehicles, ships, or aircraft live from space, with refresh rates as fast as 1 second for critical monitoring.",
                //       ),
                //       buildRow(
                //         context,
                //         text:
                //         "Overlay weather patterns, cloud cover, wildfire hotspots, and urban heatmaps directly on the satellite view.",
                //       ),
                //       buildRow(
                //         context,
                //         text:
                //         "The app also supports historical satellite replay, offline cached map tiles, and AI-powered location recognition a complete Earth observation platform in your pocket.",
                //       ),
                //       buildRow(
                //         context,
                //         text:
                //         "Need help?💬, Our support team is always here to assist you, 24/7.",
                //       ),
                //       SizedBox(height: 2),
                //       CustomButton(
                //         text: "Let's Go",
                //         onPressed: () async{
                //           final shouldShowAd = await AdFrequencyManager.shouldShowAd('initial', fx: 1);
                //           if (shouldShowAd) {
                //             InterstitialAdMob.showInterstitialAd(onComplete: (){
                //               Navigator.pushAndRemoveUntil(
                //                 context,
                //                 MaterialPageRoute(
                //                   builder: (_) => BottomNavBarScreen(),
                //                 ),
                //                     (r) => false,
                //               );
                //             });
                //           } else {
                //             Navigator.pushAndRemoveUntil(
                //               context,
                //               MaterialPageRoute(
                //                 builder: (_) => BottomNavBarScreen(),
                //               ),
                //                   (r) => false,
                //             );
                //           }
                //           },
                //         isLoading: false,
                //       ),
                //       SizedBox(height: 1),
                //     ],
                //   ),
                // ),

                /// kk
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 5,
                      children: [
                         SizedBox(
                            height:  MediaQuery.of(context).size.height <= 700
                                ? 30
                                : 45,
                        ),

                        Text(
                          "Welcome To Satellite View\nCommunity🎉",
                          textScaleFactor: 2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CustomColors.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        buildRow(
                          context,
                          text:
                          "The Live Satellite View app delivers ultra-high-resolution real-time satellite imagery, enabling users to explore any location on Earth with smooth zoom and pan controls.",
                        ),

                        buildRow(
                          context,
                          text:
                          "Track moving objects like vehicles, ships, or aircraft live from space, with refresh rates as fast as 1 second for critical monitoring.",
                        ),

                        buildRow(
                          context,
                          text:
                          "Overlay weather patterns, cloud cover, wildfire hotspots and urban heatmaps directly on the satellite view.",
                        ),

                        buildRow(
                          context,
                          text:
                          "The app also supports historical satellite replay, offline cached map tiles, and AI-powered location recognition a complete Earth observation platform in your pocket.",
                        ),

                        buildRow(
                          context,
                          text:
                          "Need help?💬, Our support team is always here to assist you, 24/7.",
                        ),

                        const SizedBox(height: 25),

                        CustomButton(
                          text: "Let's Go",
                          onPressed: () async {
                            final shouldShowAd =
                            await AdFrequencyManager.shouldShowAd(
                              'initial',
                              fx: 1,
                            );

                            if (shouldShowAd) {
                              InterstitialAdMob.showInterstitialAd(
                                onComplete: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BottomNavBarScreen(),
                                    ),
                                        (r) => false,
                                  );
                                },
                              );
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BottomNavBarScreen(),
                                ),
                                    (r) => false,
                              );
                            }
                          },
                          isLoading: false,
                        ),

                      ],
                    ),
                  ),
                ),

              ),
            ),
          ],
        ),

      ),
    );
  }
}

class ScrollingImages extends StatefulWidget {
  final int startingIndex;

  const ScrollingImages({super.key, required this.startingIndex});

  @override
  State<ScrollingImages> createState() => _ScrollingImagesState();
}

class _ScrollingImagesState extends State<ScrollingImages> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.offset ==
          _scrollController.position.minScrollExtent) {
        _autoScrollForward();
      } else if (_scrollController.offset ==
          _scrollController.position.maxScrollExtent) {
        _autoScrollbackward();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScrollForward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScrollForward() {
    final currentPosition = _scrollController.offset;
    final endPosition = _scrollController.position.maxScrollExtent;
    scheduleMicrotask(() {
      _scrollController.animateTo(
        currentPosition == endPosition ? 0 : endPosition,
        duration: Duration(seconds: 20 + widget.startingIndex + 2),
        curve: Curves.linear,
      );
    });
  }

  _autoScrollbackward() {
    final currentPosition = _scrollController.offset;
    final endPosition = _scrollController.position.minScrollExtent;
    scheduleMicrotask(() {
      _scrollController.animateTo(
        currentPosition == endPosition ? 0 : endPosition,
        duration: Duration(seconds: 20 + widget.startingIndex + 2),
        curve: Curves.linear,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return Transform.rotate(
      angle: 1.96 * pi,
      child: SizedBox(
        height: h * 0.6,
        width: w * 0.6,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(right: 8, left: 8, top: 10),
              // padding: const EdgeInsets.only(right: 8, left: 8, top: 10),
              height: h * 0.6,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                image: DecorationImage(
                  scale: 0.1,
                  image: NetworkImage(images[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Row buildRow(
  BuildContext context, {
  IconData? icon,
  String? text,
  double? fontSize,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon ?? Icons.bubble_chart, color: CustomColors.primaryColor),
      Expanded(
        child: Text(
          text ??
              "Welcome To Ride Share Community🎉, Your registration has been successfully completed.",
          softWrap: true,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: CustomColors.black,
            fontSize: fontSize ?? 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

List<String> images = [
  "https://images.unsplash.com/photo-1446776899648-aa78eefe8ed0?q=80&w=1172&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",

  "https://images.unsplash.com/photo-1604357209793-fca5dca89f97?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8bWFwfGVufDB8fDB8fHww",

  "https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTh8fG1hcHxlbnwwfHwwfHx8MA%3D%3D",

  "https://media.istockphoto.com/id/958510852/photo/compass-in-hand-mountain-road-background-vintage-tone.webp?a=1&b=1&s=612x612&w=0&k=20&c=h0D4YmHYt1_n8vqAMHxsNP_50ynFC0PjAwVXAWk7uxw=",

  "https://media.istockphoto.com/id/957861226/photo/gps-searching.webp?a=1&b=1&s=612x612&w=0&k=20&c=KHVsymnPsTOq035WtHNZQCIOKP9Ig5UrMowhO1SMxKA=",

  "https://images.unsplash.com/photo-1519709042477-8de6eaf1fdc5?q=80&w=627&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
];

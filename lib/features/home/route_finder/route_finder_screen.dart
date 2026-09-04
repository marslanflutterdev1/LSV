import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/route_finder/components/route_finder_validator.dart';
import 'package:satellite_view/features/home/route_finder/map_route_finder_screen.dart';
import 'package:satellite_view/features/home/route_finder/route_finder_provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/ad_frequency_manager.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/interstitial_ad_mob.dart';

import 'package:satellite_view/widgets/custom_button.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';
import 'package:satellite_view/widgets/custom_text_form_field.dart';
import 'package:satellite_view/widgets/voice_microphone_button.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../core/utils/utils.dart';
import '../../../main.dart';
import '../../../widgets/custom_cherry_toast.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

class RouteFinderScreen extends StatefulWidget {
  const RouteFinderScreen({super.key});

  @override
  State<RouteFinderScreen> createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  final FocusNode sourceFocusNode = FocusNode();

  final FocusNode destinationFocusNode = FocusNode();
  bool _isInitializingLocation = false;

  @override
  void initState() {
    super.initState();

    /// Interstitial Ad Mob Load
    InterstitialAdMob.loadInterstitialAd();

    _initializeCurrentLocation();

    final provider = Provider.of<RouteFinderProvider>(context, listen: false);


    // SOURCE LISTENER
    provider.sourceController.addListener(() {
      if (_isInitializingLocation) return;

      provider.sourceWasAutoLocation = false;
      provider.sourceLatLng = null;
    });

    // DESTINATION LISTENER
    provider.destinationController.addListener(() {
      provider.destinationLatLng = null;
    });
  }

  /// Initialize current location on screen load
  Future<void> _initializeCurrentLocation() async {
    _isInitializingLocation = true;

    try {
      final provider = Provider.of<RouteFinderProvider>(context, listen: false);

      provider.sourceController.clear();
      provider.destinationController.clear();
      provider.clearRoute();

      final position =
          await CustomLocationPermissionHandler.determinePosition();

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = '';

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        List<String> parts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        address = parts.join(', ');
      }

      provider.sourceController.text = address;

      provider.sourceLatLng = LatLng(position.latitude, position.longitude);

      provider.sourceWasAutoLocation = true;
    } catch (e) {
      log("Location Error: $e");
    } finally {
      _isInitializingLocation = false;
    }
  }

  @override
  void dispose() {
    sourceFocusNode.dispose();
    destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer2<RouteFinderProvider, RouteFinderValidator>(
      builder: (context, provider, validator, child) {
        // provider.sourceController = currentAddress();
        return SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: const Color(0xffF5F7FA),
            extendBodyBehindAppBar: true,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
          
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  title: Text(
                    "Route Finder",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  leading:GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => BottomNavBarScreen()),
                        (r) => false,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CustomColors.iconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          // Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                          Icons.arrow_back,
                          color: CustomColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          "assets/images/app_bar_bg.jpg",
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(.2),
                                Colors.black.withOpacity(.7),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.route_rounded,
                                  color: CustomColors.primaryColor,
                                  size: 32,
                                ),
                              ),
          
                              const SizedBox(height: 18),
          
                              Text(
                                "Secure Route Finder",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
          
                              const SizedBox(height: 8),
          
                              Text(
                                "Find shortest and accurate routes\nbetween source and destination.",
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(.9),
                                      height: 1.4,
                                    ),
                              ),
          
                              // const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: size.height),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 6,
                            decoration: BoxDecoration(
                              color: CustomColors.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 35),
          
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.05),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: CustomColors.primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: CustomColors.grey,
                                              width: 2,
                                            ),
                                          ),
                                        ),
          
                                        Container(
                                          width: 2,
                                          height: 90,
                                          color: Colors.grey,
                                        ),
          
                                        Container(
                                          width: 14,
                                          height: 14,
          
                                          decoration: BoxDecoration(
                                            color: CustomColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
          
                                    const SizedBox(width: 15),
          
                                    Expanded(
                                      child: Column(
                                        children: [
                                          CustomTextFormField(
                                            controller: provider.sourceController,
                                            hintText: 'Enter initial address...',
                                            keyboardType:
                                                TextInputType.streetAddress,
                                            focusNode: sourceFocusNode,
                                            prefixIcon: IconButton(
                                              onPressed: () {},
                                              icon: Icon(Icons.location_disabled),
                                            ),
                                            prefixIconColor:
                                                CustomColors.primaryColor,
                                            suffixIcon: VoiceMicrophoneButton(
                                              controller:
                                                  provider.sourceController,
                                            ),
                                            onFieldSubmitted: (value) {
                                              Utils.customChangeFocusOfTextField(
                                                context,
                                                sourceFocusNode,
                                                destinationFocusNode,
                                              );
                                            },
          
                                            onChanged: (value) {
                                              provider.sourceLatLng = null;
                                              provider.sourceWasAutoLocation =
                                                  false;
          
                                              validator.setValidateSource(value);
                                            },
                                            onEditingComplete: () {
                                              validator.clearError(
                                                'sourceValidate',
                                              );
                                            },
                                            errorText:
                                                validator.sourceValidate.isEmpty
                                                ? null
                                                : validator.sourceValidate
                                                      .toString(),
                                          ),
          
                                          const SizedBox(height: 20),
          
                                          CustomTextFormField(
                                            controller:
                                                provider.destinationController,
                                            hintText:
                                                'Enter destination address...',
                                            keyboardType:
                                                TextInputType.streetAddress,
                                            focusNode: destinationFocusNode,
                                            prefixIcon: IconButton(
                                              onPressed: () {},
                                              icon: Icon(Icons.location_on),
                                            ),
                                            prefixIconColor:
                                                CustomColors.primaryColor,
                                            suffixIcon: VoiceMicrophoneButton(
                                              controller:
                                                  provider.destinationController,
                                            ),
                                            onFieldSubmitted: (value) {
                                              Utils.customChangeFocusOfTextField(
                                                context,
                                                destinationFocusNode,
                                                null,
                                              );
                                            },
          
                                            onChanged: (value) {
                                              provider.destinationLatLng = null;
          
                                              validator.setValidateDestination(
                                                value,
                                              );
                                            },
                                            onEditingComplete: () {
                                              validator.clearError(
                                                'destinationValidate',
                                              );
                                            },
                                            errorText:
                                                validator
                                                    .destinationValidate
                                                    .isEmpty
                                                ? null
                                                : validator.destinationValidate
                                                      .toString(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
          
                                const SizedBox(height: 30),
          
                                /// BUTTON
                                SizedBox(
                                  width: double.infinity,
          
                                  child: CustomButton(
                                    text: 'Show Route',
                                    onPressed: () async {
                                      final source = provider
                                          .sourceController
                                          .text
                                          .trim()
                                          .toString();
                                      final destination = provider
                                          .destinationController
                                          .text
                                          .trim()
                                          .toString();
                                      try {
                                        if (validator.setValidateSource(source) !=
                                                null ||
                                            validator.setValidateDestination(
                                                  destination,
                                                ) !=
                                                null) {
                                          CustomCherryToast.warning(
                                            context,
                                            title:
                                                'Please fill all fields correctly.',
                                          );
                                          return;
                                        }
          
                                        final routeProvider =
                                            Provider.of<RouteFinderProvider>(
                                              context,
                                              listen: false,
                                            );
          
                                        final validationError =
                                            await routeProvider.validateRouteInputs(
                                              source: source,
                                              destination: destination,
                                            );
          
                                        if (validationError != null) {
                                          CustomCherryToast.warning(
                                            context,
                                            title: validationError,
                                          );
                                          return;
                                        }

                                        final shouldShowAd = await AdFrequencyManager.shouldShowAd('show_route');
                                        if (shouldShowAd) {

                                          InterstitialAdMob.showInterstitialAd(onComplete: (){
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const MapRouteFinderScreen(),
                                              ),
                                            );

                                          });

                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const MapRouteFinderScreen(),
                                            ),
                                          );
                                        }
          
                                      } catch (e) {
                                        log('Error: $e');
                                        CustomCherryToast.error(
                                          context,
                                          title: 'An error occured: $e',
                                        );
                                      }
                                    },
                                    isLoading: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
          
                          const SizedBox(height: 30),
          
                          Container(
                            padding: const EdgeInsets.all(20),
          
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(.1),
          
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(.03),
                                ],
                              ),
          
                              borderRadius: BorderRadius.circular(10),
                            ),
          
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
          
                                  child: Icon(
                                    Icons.tips_and_updates_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
          
                                const SizedBox(width: 16),
          
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
          
                                    children: [
                                      Text(
                                        "Smart Navigation",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
          
                                      const SizedBox(height: 5),
          
                                      Text(
                                        "Get accurate routes, distance and smooth map navigation experience.",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BannerAdmob(),
          
          ),
        );
      },
    );
  }

}

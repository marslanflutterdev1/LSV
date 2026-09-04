import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_info/flutter_app_info.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/core/services/voice_service.dart';
import 'package:satellite_view/features/home/area_calculator/map_measure_provider.dart';
import 'package:satellite_view/features/home/route_finder/route_finder_provider.dart';
import 'package:satellite_view/globle/globle_pop_scope_provider.dart';
import 'package:satellite_view/local/local_sp.dart';
import 'package:satellite_view/mob_ads/app_open_ads/open_app_ad_mob.dart';
import 'package:satellite_view/mob_ads/firebase_remote_configration/firebase_remote_configration.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';

import 'core/theme/custom_theme.dart';
import 'core/theme/custom_theme_provider.dart';
import 'features/bottom_nav_bar/bottom_nav_bar_provider.dart';
import 'features/home/nearby_places/nearby_places_provider.dart';
import 'features/home/route_finder/components/route_finder_validator.dart';
import 'features/home/satellite_view/satellite_view_provider.dart';
import 'features/home/street_view/street_map_view_provider.dart';
import 'features/home/street_view/street_view_provider.dart';
import 'features/home/traffic/traffic_provider.dart';
import 'features/wrapper/splash_screen.dart';
import 'firebase_options.dart';
import 'mob_ads/app_open_ads/app_lifecycle_reactor.dart';
import 'mob_ads/interstitial_ads/interstitial_ad_mob.dart';

bool isGps = false;

void main() async {
  /// Binding features
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// Reset sp data
  /// This clear data when app restart and load again.
  // await LocalSP.clearAllData();

  /// Initialize firebase remote config
  await FirebaseRemoteConfigration.initFirebaseRemoteConfig();

  /// Ads initialize
  await MobileAds.instance.initialize();

  AppOpenAdMob.loadAppOpenAd();
  AppLifecycleReactor.startListening();

  /// Initialize sp
  await LocalSP.init();

  /// Initialize interstitial ad mob with preloading
  InterstitialAdMob.loadInterstitialAd();

  /// Set orientation FIRST (non-blocking)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  /// Get Current User Location Permission.
  final position = await CustomLocationPermissionHandler.determinePosition();
  log('Position = ${position.latitude} : ${position.longitude}');

  /// Launch features immediately
  runApp(AppInfo(data: await AppInfoData.get(), child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Core providers (needed immediately on app startup)
        ChangeNotifierProvider(create: (_) => CustomThemeProvider()),
        ChangeNotifierProvider(create: (_) => GloblePopScopeProvider()),
        ChangeNotifierProvider(create: (_) => BottomNavBarProvider()),
        ChangeNotifierProvider(create: (_) => SatelliteViewProvider()),
        ChangeNotifierProvider(create: (_) => RouteFinderProvider()),
        ChangeNotifierProvider(create: (_) => RouteFinderValidator()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => NearbyPlacesProvider()),
        ChangeNotifierProvider(create: (_) => MapMeasureProvider()),
        ChangeNotifierProvider(create: (_) => TrafficProvider()),
        ChangeNotifierProvider(
          create: (_) => StreetViewProvider()..loadCountries(),
        ),
        ChangeNotifierProvider(create: (_) => StreetMapViewProvider()),
      ],
      child: Consumer<CustomThemeProvider>(
        builder: (context, theme, child) {
          return MaterialApp(
            title: 'Satellite Live View',
            debugShowCheckedModeBanner: false,
            theme: theme.isDarkTheme
                ? CustomTheme.customDarkTheme
                : CustomTheme.customLightTheme,
            // home: MapSample(),
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}

class HomeUI extends StatelessWidget {
  const HomeUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .center,
              spacing: 10,
              children: [
                IconButton(
                  onPressed: () {
                    themeProvider.setIsDarkTheme(!themeProvider.isDarkTheme);
                  },
                  icon: Icon(
                    color: Colors.purple,
                    themeProvider.isDarkTheme ? Icons.dark_mode : Icons.sunny,
                  ),
                ),
                Text(
                  'Satellite',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

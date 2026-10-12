import 'package:flutter/material.dart';
import 'package:satellite_view/features/home/about_us/about_us_screen.dart';
import 'package:satellite_view/features/home/area_calculator/area_calculator_screen.dart';
import 'package:satellite_view/features/home/camera/camera_screen.dart';
import 'package:satellite_view/features/home/compass/compass_screen.dart';
import 'package:satellite_view/features/home/components/app_share_services.dart';
import 'package:satellite_view/features/home/my_location/my_location_screen.dart';
import 'package:satellite_view/features/home/nearby_places/nearby_places_screen.dart';
import 'package:satellite_view/features/home/route_finder/route_finder_screen.dart';
import 'package:satellite_view/features/home/speedo_meter/speedo_meter_screen.dart';
import 'package:satellite_view/features/home/street_view/street_view_screen.dart';
import 'package:satellite_view/features/home/traffic/traffic_screen.dart';

import '../satellite_view/satellite_view_screen.dart';

class HomeMenuModel {
  final String title;
  final Widget? screen;
  final String url;
  final Future<void> Function()? onTap;

  HomeMenuModel({
    required this.title,
    required this.url,
    this.screen,
    this.onTap,
  });
}

final List<HomeMenuModel> homeMenusList = [
  HomeMenuModel(
    title: 'Satellite View',
    url: 'assets/images/home_icons/home_icon_1.png',
    screen: const SatelliteViewScreen(),
  ),

  HomeMenuModel(
    title: 'Route Finder',
    url: 'assets/images/home_icons/home_icon_2.png',
    screen: const RouteFinderScreen(),
  ),

  HomeMenuModel(
    title: 'Street View',
    url: 'assets/images/home_icons/home_icon_3.png',
    screen: const StreetViewScreen(),
  ),

  HomeMenuModel(
    title: 'Area Calculator',
    url: 'assets/images/home_icons/home_icon_4.png',
    screen: const AreaCalculatorScreen(),
  ),

  HomeMenuModel(
    title: 'My Location',
    url: 'assets/images/home_icons/home_icon_5.png',
    screen: const MyLocationScreen(),
  ),

  HomeMenuModel(
    title: 'Nearby Place',
    url: 'assets/images/home_icons/home_icon_6.png',
    screen: const NearbyPlacesScreen(),
  ),

  HomeMenuModel(
    title: 'Traffic',
    url: 'assets/images/home_icons/home_icon_7.png',
    screen: const TrafficScreen(),
  ),

  HomeMenuModel(
    title: 'Speedometer',
    url: 'assets/images/home_icons/home_icon_8.png',
    screen: const SpeedoMeterScreen(),
  ),

  HomeMenuModel(
    title: 'Compass',
    url: 'assets/images/home_icons/home_icon_9.png',
    screen: const CompassScreen(),
  ),

  HomeMenuModel(
    title: 'Camera',
    url: 'assets/images/home_icons/home_icon_10.png',
    screen: CameraScreen()
  ),

  HomeMenuModel(
    title: 'About Us',
    url: 'assets/images/home_icons/home_icon_11.png',
    screen: const AboutUsScreen(),
  ),

  /// This will be load in milestone or keep in remender
  HomeMenuModel(
    title: 'Share App',
    url: 'assets/images/home_icons/home_icon_12.png',
    onTap: AppShareService.shareApp,
  ),
];

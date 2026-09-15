import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/traffic/traffic_provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';

import '../../../core/theme/custom_colors.dart';
import '../../../core/utils/utils.dart';
import '../../../widgets/custom_marker.dart';
import '../../../widgets/custom_text_form_field.dart';
import '../../../widgets/custom_circle_progress_indicator.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

class TrafficScreen extends StatefulWidget {
  const TrafficScreen({super.key});

  @override
  State<TrafficScreen> createState() => _TrafficScreenState();
}

class _TrafficScreenState extends State<TrafficScreen> {
  bool isSearch = false;
  final FocusNode searchFocusNode = FocusNode();
  late final VoidCallback _searchListener;
  BitmapDescriptor? customMarker;

  @override
  void initState() {
    super.initState();
    _init();
    _searchListener = () => setState(() {});
    context.read<TrafficProvider>().searchController.addListener(_searchListener);
  }

  @override
  void dispose() {
    context.read<TrafficProvider>().searchController.removeListener(_searchListener);
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _setUpCustomMarker();
    if (!mounted) return;
    // Attempt to get location. If permission is denied,
    // the provider handles it gracefully and the app still works.
    await context.read<TrafficProvider>().getCurrentLocation(
      customMarker: customMarker,
    );
  }

  Future<void> _setUpCustomMarker() async {
    customMarker = await CustomMarker.setMarker(
      path: 'assets/images/source_location.png',
      targetWidth: 40,
      targetHeight: 40,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrafficProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: isSearch
                ? AppBar(
              backgroundColor: CustomColors.primaryColor,
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BottomNavBarScreen()),
                        (r) => false,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 12, top: 12, bottom: 12, right: 0),
                  decoration: BoxDecoration(
                    color: CustomColors.iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: CustomColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      size: 24,
                    ),
                  ),
                ),
              ),
              title: SizedBox(
                height: 40,
                child: CustomTextFormField(
                  controller: provider.searchController,
                  hintText: 'Searching...',
                  focusNode: searchFocusNode,
                  onFieldSubmitted: (value) {
                    Utils.customChangeFocusOfTextField(
                        context, searchFocusNode, null);
                  },
                  hintStyle: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                      color: CustomColors.white,
                      fontWeight: FontWeight.bold),
                  textStyle: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: CustomColors.white),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: CustomColors.white),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: CustomColors.white),
                  cursorColor: CustomColors.white,
                  borderRadius: 50,
                  onChanged: (value) => setState(() {}),
                  suffixIcon: provider.searchController.text.isNotEmpty
                      ? IconButton(
                    onPressed: () async {
                      await provider.searchLocation(
                        customMarker: customMarker,
                      );
                      provider.searchController.clear();
                      setState(() => isSearch = false);
                    },
                    icon: provider.isLoading
                        ? const CustomCircleProgressIndicator(
                        width: 18,
                        height: 18,
                        strokeWidth: 1)
                        : const Icon(Icons.send),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    BorderSide(color: CustomColors.white, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    BorderSide(color: CustomColors.white, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    BorderSide(color: CustomColors.white, width: 1),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    BorderSide(color: CustomColors.error, width: 1),
                  ),
                ),
              ),
            )
                : AppBar(
              title: Text(
                'Traffic',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: CustomColors.primaryColor,
              actions: [
                IconButton(
                  onPressed: () => setState(() => isSearch = !isSearch),
                  icon: Icon(Icons.search_rounded,
                      color: CustomColors.white),
                ),
              ],
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BottomNavBarScreen()),
                        (r) => false,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 12, top: 12, bottom: 12, right: 0),
                  decoration: BoxDecoration(
                    color: CustomColors.iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back,
                      color: CustomColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: provider.currentLatLng,
                      zoom: 14,
                    ),
                    trafficEnabled: provider.trafficEnabled,
                    mapType: provider.satelliteMode
                        ? MapType.satellite
                        : MapType.normal,
                    // ✅ CRITICAL: only enable when permission granted.
                    myLocationEnabled: provider.hasLocationPermission,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    buildingsEnabled: true,
                    zoomControlsEnabled: false,
                    markers: provider.markers,
                    onMapCreated: provider.setMapController,
                  ),

                  /// Right-side buttons
                  Positioned(
                    right: 15,
                    bottom: 10,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'traffic',
                          backgroundColor: provider.trafficEnabled
                              ? CustomColors.primaryColor
                              : Colors.white,
                          onPressed: provider.toggleTraffic,
                          child: Icon(Icons.traffic,
                              color: provider.trafficEnabled
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton.small(
                          heroTag: 'satellite',
                          backgroundColor: provider.satelliteMode
                              ? CustomColors.primaryColor
                              : Colors.white,
                          onPressed: provider.toggleSatellite,
                          child: Icon(Icons.satellite_alt,
                              color: provider.satelliteMode
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        const SizedBox(height: 10),
                        // ✅ Only show "My Location" button when permission granted.
                        // Otherwise tapping it does nothing, which Apple may flag.
                        if (provider.hasLocationPermission)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FloatingActionButton.small(
                              heroTag: 'location',
                              backgroundColor: Colors.white,
                              onPressed: () => provider.getCurrentLocation(
                                customMarker: customMarker,
                              ),
                              child: const Icon(Icons.my_location,
                                  color: Colors.black),
                            ),
                          ),
                        FloatingActionButton.small(
                          heroTag: 'zoomIn',
                          backgroundColor: Colors.white,
                          onPressed: provider.zoomIn,
                          child: const Icon(Icons.add, color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton.small(
                          heroTag: 'zoomOut',
                          backgroundColor: Colors.white,
                          onPressed: provider.zoomOut,
                          child: const Icon(Icons.remove, color: Colors.black),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Optional: small hint when permission denied.
                  // It does not block the map and does not push Settings.
                  if (!provider.hasLocationPermission)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5,
                          children: [
                            const Text(
                              'Location permission not granted.',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.start,
                            ),
                            const Text(
                              'Showing default location. Enable location in Settings to see your position.',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            bottomNavigationBar: BannerAdmob(),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/nearby_places/near_by_places_model.dart';
import 'package:satellite_view/features/home/nearby_places/nearby_places_provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/widgets/custom_circle_progress_indicator.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../widgets/custom_cherry_toast.dart';
import '../../../widgets/custom_location_permission_handler.dart';
import '../../../widgets/custom_marker.dart';

class FavouriteNearbyPlacesScreen extends StatefulWidget {
  final String placeTitle;
  final String bannerUnitId;

  const FavouriteNearbyPlacesScreen({
    super.key,
    required this.placeTitle,
    required this.bannerUnitId,
  });

  @override
  State<FavouriteNearbyPlacesScreen> createState() =>
      _FavouriteNearbyPlacesScreenState();
}

class _FavouriteNearbyPlacesScreenState
    extends State<FavouriteNearbyPlacesScreen> {
  Set<Marker> markers = {};
  LatLng? currentLatLng;
  CameraPosition? cameraPosition;
  GoogleMapController? mapController;
  BitmapDescriptor? homeMarker;
  BitmapDescriptor? nearbyMarker;

  /// Whether location permission is granted. Drives UI decisions.
  bool hasLocationPermission = false;

  /// Default fallback region (used when permission is denied).
  static const LatLng _defaultLatLng = LatLng(31.5204, 74.3587);

  @override
  void initState() {
    super.initState();
    setUpCustomMarker();
    getCurrentLocation();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> setUpCustomMarker() async {
    homeMarker = await CustomMarker.setMarker(
      path: 'assets/images/source_location.png',
      targetWidth: 60,
      targetHeight: 60,
    );
    nearbyMarker = await CustomMarker.setMarker(
      path: 'assets/images/nearby.png',
      targetWidth: 60,
      targetHeight: 60,
    );
    if (mounted) setState(() {});
  }

  Future<void> getCurrentLocation() async {
    try {
      final position =
      await CustomLocationPermissionHandler.determinePosition();

      // ✅ Permission denied — keep app functional with default region.
      if (position == null) {
        if (!mounted) return;
        setState(() {
          hasLocationPermission = false;
          currentLatLng = _defaultLatLng;
          cameraPosition = CameraPosition(target: _defaultLatLng, zoom: 10);
        });
        return;
      }

      hasLocationPermission = true;
      currentLatLng = LatLng(position.latitude, position.longitude);
      cameraPosition = CameraPosition(target: currentLatLng!, zoom: 10);

      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLatLng!,
          infoWindow: const InfoWindow(
            title: 'You are here',
            snippet: 'Your current location',
          ),
          icon: homeMarker ?? BitmapDescriptor.defaultMarker,
        ),
      );

      if (!mounted) return;
      setState(() {});
      await searchNearbyPlaces();
    } catch (e) {
      if (!mounted) return;
      // Fail-safe: still show map with default region.
      setState(() {
        hasLocationPermission = false;
        currentLatLng = _defaultLatLng;
        cameraPosition = CameraPosition(target: _defaultLatLng, zoom: 10);
      });
    }
  }

  void updateMarkers(NearByPlacesModel model) {
    markers.clear();

    if (currentLatLng != null && hasLocationPermission) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLatLng!,
          infoWindow: const InfoWindow(
            title: 'You are here',
            snippet: 'Your current location',
          ),
          icon: homeMarker ?? BitmapDescriptor.defaultMarker,
        ),
      );
    }

    final results = model.results;
    if (results == null || results.isEmpty) return;

    for (int i = 0; i < results.length; i++) {
      final place = results[i];
      final lat = place.geometry?.location?.lat ?? 0.0;
      final lng = place.geometry?.location?.lng ?? 0.0;

      if (lat == 0.0 && lng == 0.0) continue;

      markers.add(
        Marker(
          markerId: MarkerId(i.toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: place.name ?? 'Unknown Place',
            snippet: place.vicinity ?? '',
          ),
          icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> searchNearbyPlaces() async {
    if (currentLatLng == null) return;

    final searchText = widget.placeTitle.trim();
    if (searchText.isEmpty) return;

    final provider = Provider.of<NearbyPlacesProvider>(context, listen: false);

    await provider.getNearByPlacesMethod(
      lat: currentLatLng!.latitude,
      lng: currentLatLng!.longitude,
      keyword: searchText,
    );

    if (!mounted) return;

    if (provider.nearByPlacesModel != null &&
        provider.nearByPlacesModel!.results != null &&
        provider.nearByPlacesModel!.results!.isNotEmpty) {
      updateMarkers(provider.nearByPlacesModel!);
    } else if (provider.errorMsg.isNotEmpty) {
      CustomCherryToast.error(context, title: provider.errorMsg);
    } else {
      CustomCherryToast.warning(
        context,
        title: 'No places found for "${widget.placeTitle}"',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NearbyPlacesProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.placeTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: CustomColors.primaryColor,
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(12),
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
            body: cameraPosition == null || provider.isLoading
                ? Center(
              child: CustomCircleProgressIndicator(
                backgroundColor: CustomColors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  CustomColors.primaryColor,
                ),
                strokeWidth: 3,
              ),
            )
                : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: cameraPosition!,
                  // ✅ Conditional on permission
                  myLocationEnabled: hasLocationPermission,
                  tiltGesturesEnabled: true,
                  compassEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  markers: markers,
                ),
                // ✅ Non-blocking info banner when permission denied
                if (!hasLocationPermission)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
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
                            'Showing default area. Enable location in Settings to see nearby results around you.',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.start,
                          ),
                        ],
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
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

  const FavouriteNearbyPlacesScreen({super.key, required this.placeTitle, required this.bannerUnitId});

  @override
  State<FavouriteNearbyPlacesScreen> createState() => _FavouriteNearbyPlacesScreenState();
}

class _FavouriteNearbyPlacesScreenState extends State<FavouriteNearbyPlacesScreen> {
  Set<Marker> markers = {};
  LatLng? currentLatLng;
  CameraPosition? cameraPosition;
  GoogleMapController? mapController;
  BitmapDescriptor? homeMarker;
  BitmapDescriptor? nearbyMarker;

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
    setState(() {});
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await CustomLocationPermissionHandler.determinePosition();
      currentLatLng = LatLng(position.latitude, position.longitude);
      cameraPosition = CameraPosition(target: currentLatLng!, zoom: 10);

      // ✅ Add home marker immediately on location fetch
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

      setState(() {});
      await searchNearbyPlaces();
    } catch (e) {
      if (mounted) {
        CustomCherryToast.error(context, title: 'Failed to get location: $e');
      }
    }
  }

  void updateMarkers(NearByPlacesModel model) {
    markers.clear();

    // ✅ Re-add home marker after clear
    if (currentLatLng != null) {
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
          icon: nearbyMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    setState(() {});
  }

  Future<void> searchNearbyPlaces() async {
    if (currentLatLng == null) {
      if (mounted) CustomCherryToast.warning(context, title: 'Location not ready');
      return;
    }

    final searchText = widget.placeTitle.trim();
    if (searchText.isEmpty) {
      if (mounted) CustomCherryToast.warning(context, title: 'Please enter a place type');
      return;
    }

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
                onTap: (){
                  Navigator.pop(context);
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
                : GoogleMap(
              initialCameraPosition: cameraPosition!,
              myLocationEnabled: true,
              tiltGesturesEnabled: true,
              compassEnabled: true,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: markers,
            ),
            bottomNavigationBar: BannerAdmob(),
          ),
        );
      },
    );
  }
}
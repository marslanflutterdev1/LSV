// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:satellite_view/features/home/nearby_places/near_by_places_model.dart';
//
// import '../../../core/theme/custom_colors.dart';
// import '../../../widgets/custom_marker.dart';
//
// class NearbyPlacesMapScreen extends StatefulWidget {
//   final List<Result> allPlaces;
//   final Result? selectedPlace;
//
//   const NearbyPlacesMapScreen({
//     super.key,
//     required this.allPlaces,
//     this.selectedPlace,
//   });
//
//   @override
//   State<NearbyPlacesMapScreen> createState() => _NearbyPlacesMapScreenState();
// }
//
// class _NearbyPlacesMapScreenState extends State<NearbyPlacesMapScreen> {
//   GoogleMapController? mapController;
//   Set<Marker> markers = {};
//   BitmapDescriptor? homeMarker;
//   BitmapDescriptor? nearbyMarker;
//   BitmapDescriptor? selectMarker;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _buildMarkers();
//     setUpCustomMarker();
//   }
//
//   Future<void> setUpCustomMarker() async {
//     homeMarker = await CustomMarker.setMarker(
//         path: 'assets/images/source_location.png',
//         targetWidth: 60,
//         targetHeight: 60
//     );
//     nearbyMarker = await CustomMarker.setMarker(
//         path: 'assets/images/nearby.png',
//         targetWidth: 60,
//         targetHeight: 60
//     );
//     nearbyMarker = await CustomMarker.setMarker(
//         path: 'assets/images/nearby.png',
//         targetWidth: 60,
//         targetHeight: 60
//     );
//
//     setState(() {});
//   }
//
//   void _buildMarkers() {
//     markers.clear();
//
//     for (int i = 0; i < widget.allPlaces.length; i++) {
//       final place = widget.allPlaces[i];
//       if (place.geometry?.location == null) continue;
//
//       final bool isSelected = widget.selectedPlace != null &&
//           place.placeId == widget.selectedPlace!.placeId;
//
//       markers.add(
//         Marker(
//           markerId: MarkerId(place.placeId ?? "place_$i"),
//           position: LatLng(
//             place.geometry!.location!.lat!,
//             place.geometry!.location!.lng!,
//           ),
//           icon: isSelected
//               ? selectMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
//               : nearbyMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
//           infoWindow: InfoWindow(
//             title: place.name,
//             snippet: place.vicinity,
//           ),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     LatLng target;
//     if (widget.selectedPlace?.geometry?.location != null) {
//       target = LatLng(
//         widget.selectedPlace!.geometry!.location!.lat!,
//         widget.selectedPlace!.geometry!.location!.lng!,
//       );
//     } else if (widget.allPlaces.isNotEmpty) {
//       target = LatLng(
//         widget.allPlaces.first.geometry!.location!.lat!,
//         widget.allPlaces.first.geometry!.location!.lng!,
//       );
//     } else {
//       target = const LatLng(0, 0);
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Nearby Places Map',
//           style: Theme.of(context).textTheme.titleLarge?.copyWith(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: CustomColors.primaryColor,
//         leading: GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: (){
//               Navigator.pop(context);
//             },
//             child: Icon(Icons.arrow_back_sharp, color: CustomColors.white)),
//       ),
//       body: SafeArea(
//         child: GoogleMap(
//           initialCameraPosition: CameraPosition(target: target, zoom: 12),
//           markers: markers,
//           myLocationEnabled: true,
//           myLocationButtonEnabled: true,
//           onMapCreated: (controller) => mapController = controller,
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/nearby_places/near_by_places_model.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../widgets/custom_marker.dart';

class SearchingNearbyPlacesScreen extends StatefulWidget {
  final List<Result> allPlaces;
  final Result? selectedPlace;
  final LatLng currentLocation; // ✅ pass current location from parent

  const SearchingNearbyPlacesScreen({
    super.key,
    required this.allPlaces,
    required this.currentLocation, // ✅ required
    this.selectedPlace,
  });

  @override
  State<SearchingNearbyPlacesScreen> createState() => _SearchingNearbyPlacesScreenState();
}

class _SearchingNearbyPlacesScreenState extends State<SearchingNearbyPlacesScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  BitmapDescriptor? homeMarker;
  BitmapDescriptor? nearbyMarker;
  BitmapDescriptor? selectMarker;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {

    mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await setUpCustomMarker();
    _buildMarkers();
  }

  Future<void> setUpCustomMarker() async {
    homeMarker = await CustomMarker.setMarker(
      path: 'assets/images/source_location.png',       // ✅ home marker
      targetWidth: 60,
      targetHeight: 80,
    );
    nearbyMarker = await CustomMarker.setMarker(
      path: 'assets/images/nearby.png',     // ✅ nearby marker
      targetWidth: 60,
      targetHeight: 60,
    );
    selectMarker = await CustomMarker.setMarker(
      path: 'assets/images/centerMarker.png', // ✅ selected marker
      targetWidth: 60,
      targetHeight: 80,
    );
    setState(() {});
  }

  void _buildMarkers() {
    markers.clear();

    // ✅ Add current user location marker with home icon
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: widget.currentLocation,
        infoWindow: const InfoWindow(
          title: 'You are here',
          snippet: 'Your current location',
        ),
        icon: homeMarker ?? BitmapDescriptor.defaultMarker,
        zIndex: 2.0, // ✅ always on top
      ),
    );

    // ✅ Add all nearby places markers
    for (int i = 0; i < widget.allPlaces.length; i++) {
      final place = widget.allPlaces[i];
      if (place.geometry?.location == null) continue;

      final bool isSelected = widget.selectedPlace != null &&
          place.placeId == widget.selectedPlace!.placeId;

      markers.add(
        Marker(
          markerId: MarkerId(place.placeId ?? 'place_$i'),
          position: LatLng(
            place.geometry!.location!.lat!,
            place.geometry!.location!.lng!,
          ),
          icon: isSelected
              ? selectMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : nearbyMarker ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.vicinity,
          ),
          zIndex: isSelected ? 1.0 : 0.0,
        ),
      );
    }

    setState(() {});

    // ✅ Auto open infoWindow for selected marker
    if (widget.selectedPlace != null) {
      final selectedMarkerId = MarkerId(
        widget.selectedPlace!.placeId ?? 'place_0',
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) mapController?.showMarkerInfoWindow(selectedMarkerId);
      });
    }
  }

  LatLng get _initialTarget {
    if (widget.selectedPlace?.geometry?.location != null) {
      return LatLng(
        widget.selectedPlace!.geometry!.location!.lat!,
        widget.selectedPlace!.geometry!.location!.lng!,
      );
    } else if (widget.allPlaces.isNotEmpty &&
        widget.allPlaces.first.geometry?.location != null) {
      return LatLng(
        widget.allPlaces.first.geometry!.location!.lat!,
        widget.allPlaces.first.geometry!.location!.lng!,
      );
    }
    return widget.currentLocation; // ✅ fallback to current location
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Nearby Places Map',
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
            child: Icon(Icons.arrow_back_sharp, color: CustomColors.white),
          ),
        ),
        body: SafeArea(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialTarget, zoom: 10),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              mapController = controller;
              if (widget.selectedPlace != null) {
                final selectedMarkerId = MarkerId(
                  widget.selectedPlace!.placeId ?? 'place_0',
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) mapController?.showMarkerInfoWindow(selectedMarkerId);
                });
              }
            },
          ),
        ),
        bottomNavigationBar: BannerAdmob(),
      ),
    );
  }
}
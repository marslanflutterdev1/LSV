import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/features/bottom_nav_bar/bottom_nav_bar_screen.dart';
import 'package:satellite_view/features/home/satellite_view/satellite_view_provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/widgets/custom_marker.dart';
import 'package:custom_info_window/custom_info_window.dart';


class SatelliteViewScreen1 extends StatefulWidget {
  const SatelliteViewScreen1({super.key});

  @override
  State<SatelliteViewScreen1> createState() => _SatelliteViewScreen1State();
}

class _SatelliteViewScreen1State extends State<SatelliteViewScreen1> {
  CustomInfoWindowController customInfoWindowController =
  CustomInfoWindowController();
  GoogleMapController? mapController;
  BitmapDescriptor? customMarker;
  LatLng latLng = LatLng(0.0, 0.0);

  @override
  void initState() {
    Provider.of<SatelliteViewProvider>(
      context,
      listen: false,
    ).getLiveLocationMethod();
    initializeMarker();
    super.initState();
  }

  @override
  void dispose() {
    customInfoWindowController.dispose();
    super.dispose();
  }

  Future<void> setUpCustomMarker() async {
    customMarker = await CustomMarker.setMarker(
        path: 'assets/images/source_location.png',
        targetWidth: 40,
        targetHeight: 40
    );

    setState(() {});
  }

  Future<void> initializeMarker() async {
    await setUpCustomMarker();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SatelliteViewProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Map View',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: CustomColors.primaryColor,
              // leading: GestureDetector(
              //   behavior: HitTestBehavior.opaque,
              //   onTap: (){
              //     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> BottomNavBarScreen()), (r)=> false);
              //   },
              //   child: Container(
              //     margin: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: CustomColors.iconBackgroundColor,
              //       shape: BoxShape.circle,
              //     ),
              //     child: Center(
              //       child: Icon(
              //         // Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
              //         Icons.arrow_back,
              //         color: CustomColors.primaryColor,
              //         fontWeight: FontWeight.bold,
              //         size: 24,
              //       ),
              //     ),
              //   ),
              // ),
            ),
            body: provider.isLocationLoaded
                ? SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: provider.currentLatLng,
                            zoom: 0.0,
                          ),

                          mapType: MapType.satellite,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          compassEnabled: true,
                          mapToolbarEnabled: false,
                          markers: {
                            Marker(
                              markerId:  MarkerId("current_location"),
                              position: provider.currentLatLng,
                              icon: customMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet,),
                              // onTap: () {
                              //   customInfoWindowController.addInfoWindow?.call(
                              //     Container(
                              //       decoration: BoxDecoration(
                              //         color: CustomColors.primaryColor,
                              //         borderRadius: BorderRadius.circular(4),
                              //       ),
                              //       child: Padding(
                              //         padding: const EdgeInsets.all(8.0),
                              //         child: Row(
                              //           mainAxisAlignment:
                              //               MainAxisAlignment.start,
                              //           mainAxisSize: MainAxisSize.min,
                              //           children: [
                              //             Icon(
                              //               Icons.account_circle,
                              //               color: Colors.white,
                              //               size: 24,
                              //             ),
                              //             SizedBox(width: 6),
                              //             Text(
                              //               "I am here",
                              //               style: Theme.of(context)
                              //                   .textTheme
                              //                   .bodyMedium
                              //                   ?.copyWith(
                              //                     color: Colors.white,
                              //                     fontWeight: FontWeight.bold,
                              //                   ),
                              //             ),
                              //           ],
                              //         ),
                              //       ),
                              //     ),
                              //     provider.currentLatLng,
                              //   );
                              // },

                              // icon: customMarker ?? BitmapDescriptor.defaultMarker,
                              infoWindow: InfoWindow(
                                title: "📡 Live Satellite Position",
                                snippet:
                                "Lat: ${provider.currentLatLng.latitude.toStringAsFixed(5)}, "
                                    "Lng: ${provider.currentLatLng.longitude.toStringAsFixed(5)}",
                              ),
                            ),
                          },
                          onMapCreated: (controller) {
                            mapController = controller;
                            customInfoWindowController.googleMapController =
                                controller;
                          },
                          onCameraMove: (CameraPosition cameraPosition) {
                            log(
                              'Camera Position: ${cameraPosition.target.longitude}:${cameraPosition.target.latitude}',
                            );
                            latLng = LatLng(
                              cameraPosition.target.latitude,
                              cameraPosition.target.longitude,
                            );
                          },
                          onCameraIdle: () {
                            log('Stop Camera');
                          },
                        ),
                        CustomInfoWindow(
                          controller: customInfoWindowController,
                          height: 75,
                          width: 150,
                          offset: 50,
                        ),
                      ],
                    ),
                  ),
                  // adProvider.isLoadedHomeScreenBannerAds
                  //     ? SizedBox(
                  //   height: adProvider.satelliteViewScreenBannerAds.size.height.toDouble(),
                  //   width: adProvider.satelliteViewScreenBannerAds.size.width.toDouble(),
                  //   child: AdWidget(
                  //     ad: adProvider.satelliteViewScreenBannerAds,
                  //   ),
                  // ) : SizedBox.shrink()
                ],
              ),
            )
                : Center(
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: CustomColors.primaryColor,
              ),
            ),
            bottomNavigationBar: BannerAdmob(),
            // bottomNavigationBar: SafeArea(
            //   child: Container(
            //     width: double.infinity,
            //     decoration: BoxDecoration(
            //       color: CustomColors.white,
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.black12,
            //           blurRadius: 10,
            //           offset: Offset(0, -2),
            //         ),
            //       ],
            //     ),
            //
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 14,
            //       ),
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             'Your Current Location',
            //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
            //               color: CustomColors.primaryColor,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //           const SizedBox(height: 10),
            //           Row(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Expanded(
            //                 child: Text(
            //                   provider.currentAddress,
            //                   style: Theme.of(context).textTheme.bodyMedium,
            //                 ),
            //               ),
            //               const SizedBox(width: 10),
            //               GestureDetector(
            //                 behavior: HitTestBehavior.opaque,
            //                 onTap: () {
            //                   Share.share(provider.currentAddress);
            //                 },
            //                 child: Icon(
            //                   Icons.share,
            //                   color: CustomColors.primaryColor,
            //                 ),
            //               ),
            //               SizedBox(width: 20),
            //               GestureDetector(
            //                 behavior: HitTestBehavior.opaque,
            //                 onTap: () {
            //                   Clipboard.setData(
            //                     ClipboardData(text: provider.currentAddress),
            //                   );
            //                 },
            //                 child: Icon(
            //                   Icons.copy,
            //                   color: CustomColors.primaryColor,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

          ),
        );
      },
    );
  }
}

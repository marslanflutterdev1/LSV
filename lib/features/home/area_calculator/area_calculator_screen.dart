import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/area_calculator/area_converter.dart';
import 'package:satellite_view/features/home/area_calculator/map_measure_provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/widgets/custom_button.dart';

import '../../../core/theme/custom_colors.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

class AreaCalculatorScreen extends StatefulWidget {
  const AreaCalculatorScreen({super.key});

  @override
  State<AreaCalculatorScreen> createState() => _AreaCalculatorScreenState();
}

class _AreaCalculatorScreenState extends State<AreaCalculatorScreen> {



  @override
  Widget build(BuildContext context) {
    return Consumer<MapMeasureProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Area Calculator',
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
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=> BottomNavBarScreen()), (r)=> false);
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

            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(31.5204, 74.3587),
                          zoom: 15,
                        ),
                        mapType: MapType.satellite,
                        polygons: provider.polygons,
                        polylines: provider.polylines,
                        markers: provider.markers,
                        onTap: provider.addPoint,
                        // ✅ Area measurement does not need the user's live location.
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,

                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: CustomColors.primaryColor.withOpacity(.5),
                          ),
                          child: Column(
                            spacing: 5,
                            children: [
                              Text(
                                'Area Measurement',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: CustomColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              buildMeasurementArea(
                                context,
                                'Points',
                                '${provider.points.length}',
                              ),
                              buildMeasurementArea(
                                context,
                                'Perimeter',
                                "${(provider.perimeter / 1000).toStringAsFixed(1)} KM",
                              ),
                              buildMeasurementArea(
                                context,
                                "Area (m²)",
                                provider.area.toStringAsFixed(1),
                              ),
                              buildMeasurementArea(
                                context,
                                "Area (m²)",
                                provider.area.toStringAsFixed(1),
                              ),
                              buildMeasurementArea(
                                context,
                                "Area (km²)",
                                AreaConverter.toKm(provider.area).toStringAsFixed(1),
                              ),
                              buildMeasurementArea(
                                context,
                                "Acre",
                                AreaConverter.toAcre(provider.area).toStringAsFixed(1),
                              ),
                              buildMeasurementArea(
                                context,
                                "Kanal",
                                AreaConverter.toKanal(provider.area).toStringAsFixed(1),
                              ),
                              buildMeasurementArea(
                                context,
                                "Marla",
                                AreaConverter.toMarla(provider.area).toStringAsFixed(1),
                              ),
                              SizedBox(height: 2)
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                BannerAdmob()
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CustomColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Area Measurement:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: CustomColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Undo',
                              onPressed:  provider.undoLastPoint,
                              isLoading: false,
                            ),
                          ),
                          Expanded(
                            child: CustomButton(
                              text: 'Clear',
                              onPressed: provider.clearMap,
                              isLoading: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Padding buildMeasurementArea(
      BuildContext context,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CustomColors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CustomColors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
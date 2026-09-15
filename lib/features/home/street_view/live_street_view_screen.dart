import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:flutter_streetview_web/flutter_streetview.dart';
import 'package:flutter_streetview_web/models/street_view_options.dart';
import 'package:satellite_view/core/utils/constants.dart';
import 'package:satellite_view/features/home/street_view/street_map_view_provider.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../widgets/custom_circle_progress_indicator.dart';

class LiveStreetViewScreen extends StatefulWidget {
  final String address;
  const LiveStreetViewScreen({super.key, required this.address});

  @override
  State<LiveStreetViewScreen> createState() => _LiveStreetViewScreenState();
}

class _LiveStreetViewScreenState extends State<LiveStreetViewScreen> {
  @override
  void initState() {
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<StreetMapViewProvider>(
        context,
        listen: false,
      ).initializeWebView(widget.address);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StreetMapViewProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: CustomColors.primaryColor,
              centerTitle: true,
              title: Text(
                'Street View',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CustomColors.iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: CustomColors.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
            body: provider.isLoading
                ? Center(
              child: CustomCircleProgressIndicator(
                backgroundColor: CustomColors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(
                    CustomColors.primaryColor),
                strokeWidth: 2,
              ),
            )
                : provider.hasError
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 60,
                      color: CustomColors.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Street View unavailable',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This address could not be loaded. '
                          'Please go back and try another place.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
                : SafeArea(
              child: FlutterStreetView(
                apiKey: Constants.mapKey,
                latitude: provider.latitude!,
                longitude: provider.longitude!,
                onMessageReceived: (message) {},
                streetViewOptions: const StreetViewOptions(
                  panControl: true,
                  zoomControl: true,
                  linksControl: true,
                  fullscreenControl: true,
                  motionTrackingControl: true,
                  addressControl: true,
                  showRoadLabels: true,
                  clickToGo: true,
                  scrollwheel: true,
                  disableDefaultUI: true,
                  povHeading: 0,
                  povPitch: 0,
                  povZoom: 1,
                ),
                loadingBuilder: (context) => Center(
                  child: CustomCircleProgressIndicator(
                    backgroundColor: CustomColors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        CustomColors.primaryColor),
                    strokeWidth: 2,
                  ),
                ),
                errorBuilder: (context, errorMessage) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load Street View for this location.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: BannerAdmob(),
          ),
        );
      },
    );
  }
}
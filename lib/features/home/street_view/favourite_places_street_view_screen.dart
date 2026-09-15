import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/street_view/live_street_view_screen.dart';
import 'package:satellite_view/features/home/street_view/street_view_provider.dart';
import 'package:satellite_view/features/home/street_view/street_view_screen.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';

import '../../../core/theme/custom_colors.dart';
import '../../../widgets/custom_circle_progress_indicator.dart';

class FavouritePlacesStreetViewScreen extends StatefulWidget {
  final Country country;

  const FavouritePlacesStreetViewScreen({
    super.key,
    required this.country,
  });

  @override
  State<FavouritePlacesStreetViewScreen> createState() =>
      _FavouritePlacesStreetViewScreenState();
}

class _FavouritePlacesStreetViewScreenState
    extends State<FavouritePlacesStreetViewScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: CustomColors.primaryColor,
          centerTitle: true,
          title: Text(
            'Favourite Places',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            onPressed: () {
              context.read<StreetViewProvider>().clearSearch();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const StreetViewScreen()),
                    (r) => false,
              );
            },
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
        body: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: widget.country.places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final place = widget.country.places[index];
              return _PlaceCard(
                place: place,
                flagUrl: widget.country.flagImage,
                onTap: () {
                  if (place.address == null || place.address!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No address available for this place'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LiveStreetViewScreen(address: place.address!),
                    ),
                  );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: BannerAdmob(),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final String? flagUrl;
  final void Function()? onTap;

  const _PlaceCard({
    required this.place,
    required this.flagUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Card(
        elevation: 10,
        shadowColor: CustomColors.primaryColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: buildNetworkImage(
                    url: place.placeImage,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: buildFlagImage(url: flagUrl),
                  ),
                ),
              ],
            ),
            Padding(
              padding:
              const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.placeName ?? "Unknown Place",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: CustomColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.address ?? "No address available",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildNetworkImage({
  String? url,
  BoxFit fit = BoxFit.cover,
}) {
  if (url == null || url.isEmpty) {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40),
      ),
    );
  }

  return Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;

      return Center(
        child: CustomCircleProgressIndicator(
          backgroundColor: CustomColors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(CustomColors.primaryColor),
          strokeWidth: 2,
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.broken_image, size: 40),
        ),
      );
    },
  );
}

Widget buildFlagImage({String? url}) {
  if (url == null || url.isEmpty) {
    return Container(
      width: 45,
      height: 30,
      color: Colors.grey.shade300,
      child: const Icon(Icons.flag, size: 18),
    );
  }

  return Image.network(
    url,
    width: 45,
    height: 30,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;

      return SizedBox(
        width: 45,
        height: 30,
        child: Center(
          child: CustomCircleProgressIndicator(
            backgroundColor: CustomColors.grey,
            valueColor:
            AlwaysStoppedAnimation<Color>(CustomColors.primaryColor),
            strokeWidth: 2,
          ),
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: 45,
        height: 30,
        color: Colors.grey.shade300,
        child: const Icon(Icons.flag, size: 18),
      );
    },
  );
}
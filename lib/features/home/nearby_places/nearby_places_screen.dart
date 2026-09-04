import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/core/utils/constants.dart';
import 'package:satellite_view/features/home/nearby_places/components/NearByPlacesMenuModel.dart';
import 'package:satellite_view/features/home/nearby_places/favourite_nearby_places_screen.dart';
import 'package:satellite_view/features/home/nearby_places/near_by_places_model.dart';
import 'package:satellite_view/features/home/nearby_places/nearby_places_provider.dart';
import 'package:satellite_view/features/home/nearby_places/searching_nearby_places_screen.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/ad_frequency_manager.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/interstitial_ad_mob.dart';
import 'package:satellite_view/widgets/custom_circle_progress_indicator.dart';
import 'package:satellite_view/widgets/custom_location_permission_handler.dart';
import 'package:satellite_view/widgets/custom_text_form_field.dart';
import '../../../core/theme/custom_colors.dart';
import '../../../core/utils/utils.dart';
import '../../../widgets/custom_cherry_toast.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  bool isSearch = false;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Set<Marker> markers = {};
  LatLng? currentLatLng;
  CameraPosition? cameraPosition;
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();

    /// Interstitial Ad Mob Load
    InterstitialAdMob.loadInterstitialAd();

    getCurrentLocation();
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.removeListener(() {});
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }


  Future<void> getCurrentLocation() async {
    final position = await CustomLocationPermissionHandler.determinePosition();
    currentLatLng = LatLng(position.latitude, position.longitude);
    cameraPosition = CameraPosition(target: currentLatLng!, zoom: 15);
    setState(() {});
  }

  void updateMarkers(NearByPlacesModel model) {
    markers.clear();

    for (int i = 0; i < model.results!.length; i++) {
      final place = model.results![i];
      markers.add(
        Marker(
          markerId: MarkerId(i.toString()),
          position: LatLng(
            place.geometry?.location?.lat ?? 0.0,
            place.geometry?.location?.lng ?? 0.0,
          ),
          infoWindow: InfoWindow(
            title: place.name ?? 'Unknown Place',
            snippet: place.vicinity ?? '',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    }

    setState(() {});
  }

  Future<void> searchNearbyPlaces() async {
    try {
      if (currentLatLng == null) {
        CustomCherryToast.warning(context, title: 'Getting your location...');
        return;
      }

      final provider = Provider.of<NearbyPlacesProvider>(context, listen: false);
      final searchText = searchController.text.trim();

      if (searchText.isEmpty) {
        CustomCherryToast.warning(context, title: 'Please enter a place type');
        return;
      }

      searchFocusNode.unfocus();

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
        searchController.clear();

        // ✅ Pass currentLatLng to bottom sheet
        _showPlacesBottomSheet(context, provider.nearByPlacesModel!);
      } else if (provider.errorMsg.isNotEmpty) {
        CustomCherryToast.error(context, title: provider.errorMsg);
      } else {
        CustomCherryToast.warning(
          context,
          title: 'No places found for "$searchText"',
        );
      }
    } catch (e) {
      CustomCherryToast.error(context, title: 'Error: ${e.toString()}');
    }
  }

  // ✅ Moved inside class so currentLatLng is accessible
  void _showPlacesBottomSheet(BuildContext context, NearByPlacesModel model) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.89,
          ),
          decoration: BoxDecoration(color: CustomColors.white),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(
                  color: CustomColors.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Search Nearby Places',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: CustomColors.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                height: 0.5,
                thickness: 10,
                indent: 20,
                endIndent: 20,
                color: CustomColors.grey200,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: model.results?.length ?? 0,
                  itemBuilder: (context, index) {
                    final place = model.results![index];
                    final photoRef =
                    place.photos != null && place.photos!.isNotEmpty
                        ? place.photos!.first.photoReference
                        : null;

                    return Card(
                      elevation: 10,
                      color: CustomColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadowColor: CustomColors.grey200,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: ListTile(
                        onTap: () async{
                          final shouldShowAd = await AdFrequencyManager.shouldShowAd(
                            place.name.toString()
                          );
                          if (shouldShowAd) {

                            InterstitialAdMob.showInterstitialAd(onComplete: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SearchingNearbyPlacesScreen(
                                    allPlaces: model.results!,
                                    selectedPlace: place,
                                    currentLocation: currentLatLng!,
                                  ),
                                ),
                              );

                            });

                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SearchingNearbyPlacesScreen(
                                  allPlaces: model.results!,
                                  selectedPlace: place,
                                  currentLocation: currentLatLng!,
                                ),
                              ),
                            );
                          }
                        },
                        leading: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: CustomColors.grey200,
                            ),
                            child: photoRef != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl:
                                'https://maps.googleapis.com/maps/api/place/photo'
                                    '?maxwidth=100'
                                    '&photoreference=$photoRef'
                                    '&key=${Constants.mapKey}',
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.image,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                                : const Icon(
                              Icons.image_not_supported_outlined,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        title: Text(
                          place.name ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: CustomColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              place.vicinity ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                color: CustomColors.white,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              place.openingHours?.openNow == true
                                  ? 'Status: Open'
                                  : 'Status: Closed',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                color: CustomColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NearbyPlacesProvider>(
      builder: (context, provider, child) {
        if (provider.errorMsg.isNotEmpty && !provider.isErrorShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CustomCherryToast.error(context, title: provider.errorMsg);
            provider.clearError();
          });
        }

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
                    MaterialPageRoute(builder: (_) => BottomNavBarScreen()),
                        (r) => false,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 12,
                    top: 12,
                    bottom: 12,
                    right: 0,
                  ),
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
                  controller: searchController,
                  hintText: 'Searching...',
                  focusNode: searchFocusNode,
                  onFieldSubmitted: (value) {
                    Utils.customChangeFocusOfTextField(
                      context,
                      searchFocusNode,
                      null,
                    );
                  },
                  hintStyle: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(
                    color: CustomColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textStyle: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: CustomColors.white),
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: CustomColors.white),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: CustomColors.white,
                  ),
                  cursorColor: CustomColors.white,
                  borderRadius: 50,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    onPressed: searchNearbyPlaces,
                    icon: provider.isLoading
                        ? const CustomCircleProgressIndicator(
                      width: 18,
                      height: 18,
                      strokeWidth: 1,
                    )
                        : const Icon(Icons.send),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                      color: CustomColors.white,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                      color: CustomColors.white,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                      color: CustomColors.white,
                      width: 1,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                      color: CustomColors.error,
                      width: 1,
                    ),
                  ),
                ),
              ),
            )
                : AppBar(
              title: Text(
                'Nearby Places',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: CustomColors.primaryColor,
              actions: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      isSearch = !isSearch;
                    });
                  },
                  icon: Icon(
                    Icons.search_rounded,
                    color: CustomColors.white,
                  ),
                ),
              ],
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => BottomNavBarScreen()),
                        (r) => false,
                  );
                },
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
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  hitTestBehavior: HitTestBehavior.opaque,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 70,
                  ),
                  padding: const EdgeInsets.only(top: 10, bottom: 200),
                  itemCount: nearByPlacesMenusList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async{
                        final shouldShowAd = await AdFrequencyManager.shouldShowAd(
                          nearByPlacesMenusList[index].title.toString()
                        );

                        if (shouldShowAd) {

                          InterstitialAdMob.showInterstitialAd(onComplete: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FavouriteNearbyPlacesScreen(
                                  placeTitle: nearByPlacesMenusList[index].title,
                                  bannerUnitId: nearByPlacesMenusList[index].bannerUnitId,
                                ),
                              ),
                            );

                          });

                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FavouriteNearbyPlacesScreen(
                                placeTitle: nearByPlacesMenusList[index].title,
                                bannerUnitId: nearByPlacesMenusList[index].bannerUnitId,
                              ),
                            ),
                          );
                        }

                      },
                      child: Container(
                        width: double.infinity / 2,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            buildContainer(
                              url: nearByPlacesMenusList[index].url.toString(),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              nearByPlacesMenusList[index].title.toString(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                color: CustomColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            bottomNavigationBar: BannerAdmob(),

          ),
        );
      },
    );
  }

  Container buildContainer({String? url}) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: CustomColors.iconBackgroundColor,
      ),
      child: Center(
        child: Image.asset(
          url ?? 'assets/images/home_icons/home_icon_2.png',
          width: 20,
          height: 20,
          color: CustomColors.primaryColor,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image_not_supported_outlined,
              size: 20,
              color: CustomColors.primaryColor,
            );
          },
        ),
      ),
    );
  }
}
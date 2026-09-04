import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/home/street_view/favourite_places_street_view_screen.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';
import 'package:satellite_view/widgets/custom_circle_progress_indicator.dart';

import '../../../core/theme/custom_colors.dart';
import '../../../core/utils/utils.dart';
import '../../../widgets/custom_icon.dart';
import '../../../widgets/custom_text_form_field.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';
import 'street_view_provider.dart';

class StreetViewScreen extends StatefulWidget {
  const StreetViewScreen({super.key});

  @override
  State<StreetViewScreen> createState() => _StreetViewScreenState();
}

class _StreetViewScreenState extends State<StreetViewScreen> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StreetViewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SafeArea(
            child: Scaffold(
              body: Center(
                child: CustomCircleProgressIndicator(
                  backgroundColor: CustomColors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(CustomColors.primaryColor),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        if (provider.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to load countries data.')),
          );
        }

        return SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              title: SizedBox(
                height: 40,
                child: CustomTextFormField(
                  controller: searchController,
                  hintText: 'Searching...',
                  focusNode: searchFocusNode,
                  onChanged: provider.search,
                  onFieldSubmitted: (value) {
                    searchController.clear();
                    provider.clearSearch();
                    Utils.customChangeFocusOfTextField(
                      context,
                      searchFocusNode,
                      null,
                    );
                  },
                  hintStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: CustomColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: CustomColors.white,
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: CustomColors.white,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: CustomColors.white,
                  ),
                  cursorColor: CustomColors.white,
                  borderRadius: 50,
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
              centerTitle: true,
              backgroundColor: CustomColors.primaryColor,
              leading: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const BottomNavBarScreen()),
                        (route) => false,
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
            body: Builder(
              builder: (context) {
                // Initial empty state
                if (!provider.shouldShowSuggestions) {
                  return _buildEmptyState(context);
                }

                // No search results
                if (!provider.hasResults) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomIcon(
                          iconUrl: 'assets/images/search.png',
                          borderRadius: BorderRadius.circular(50),
                          onTap: () {},
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No matching country found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start searching to view your history country',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.searchResults.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 75,
                    ),
                    itemBuilder: (context, index) {
                      final country = provider.searchResults[index];

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          provider.selectCountry(country);
                          provider.clearSearch();
                          searchController.clear();
                          FocusScope.of(context).unfocus();

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FavouritePlacesStreetViewScreen(country: country),
                            ),
                                (r) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(0),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                                color: Colors.black.withOpacity(0.08),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: buildContainer(
                                  url: country.flagImage,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  country.countryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: CustomColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            bottomNavigationBar: BannerAdmob(),

          ),
        );
      },
    );
  }

  Widget buildContainer({String? url}) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 50,
        height: 30,
        color: Colors.grey.shade300,
        child: const Icon(Icons.flag, size: 20),
      );
    }

    return Image.network(
      url,
      width: 50,
      height: 30,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          width: 50,
          height: 35,
          alignment: Alignment.center,
          child: Center(
            child: CustomCircleProgressIndicator(
              backgroundColor: CustomColors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(CustomColors.primaryColor),
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 50,
          height: 30,
          color: Colors.grey.shade300,
          child: const Icon(Icons.image_not_supported_outlined, size: 20),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomIcon(
            iconUrl: 'assets/images/search.png',
            borderRadius: BorderRadius.circular(50),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          Text(
            'No Streets Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start searching to view your history',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
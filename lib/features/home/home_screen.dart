
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/features/home/components/home_banner.dart';
import 'package:satellite_view/features/home/components/home_menu_model.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/ad_frequency_manager.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/interstitial_ad_mob.dart';

import '../../core/utils/utils.dart';
import '../../mob_ads/banner_ads/banner_ad_mob.dart';
import '../../widgets/custom_icon.dart';
import '../../widgets/custom_text_form_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => MapSampleState();
}

class MapSampleState extends State<HomeScreen>{
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  List<HomeMenuModel> filteredMenus = [];

  @override
  void initState() {
    super.initState();

    /// Interstitial Ad Mob Load
    InterstitialAdMob.loadInterstitialAd();


    /// Show all cards initially
    filteredMenus = homeMenusList;

    /// Live search listener
    searchController.addListener(() {
      searchMenu(searchController.text);
    });
  }


  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }




  void searchMenu(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredMenus = homeMenusList;
      });
    } else {
      final results = homeMenusList.where((menu) {
        return menu.title.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        filteredMenus = results;
      });
    }
  }




  Future<void> navigateWithAd(HomeMenuModel menu) async {
    if (menu.onTap != null) {
      await menu.onTap!();
      return;
    }

    // Safety check.
    if (menu.screen == null) {
      return;
    }

    final shouldShowAd = await AdFrequencyManager.shouldShowAd(
      menu.title,
    );

    if (shouldShowAd) {
      InterstitialAdMob.showInterstitialAd(onComplete: () {_navigateTo(menu.screen!);},);
    } else {
      _navigateTo(menu.screen!);
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: CustomColors.primaryColor,
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
            hintStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: CustomColors.white,
              fontWeight: FontWeight.bold,
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: CustomColors.white),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: CustomColors.white),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: CustomColors.white,
            ),
            cursorColor: CustomColors.white,
            borderRadius: 50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: CustomColors.white, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: CustomColors.white, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: CustomColors.white, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: CustomColors.error, width: 1),
            ),
          ),
        ),
        //
        // actions: [
        //   Container(
        //     height: 40,
        //     width: 40,
        //     decoration: BoxDecoration(
        //       color: CustomColors.iconBackgroundColor,
        //       borderRadius: BorderRadius.circular(50),
        //     ),
        //     child: const Center(child: Icon(Icons.person)),
        //   ),
        //   const SizedBox(width: 10),
        // ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              const SizedBox(height: 5),

              const HomeBanner(),

              const SizedBox(height: 10),

              Expanded(
                child: filteredMenus.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                  itemCount: filteredMenus.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 70,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final menu = filteredMenus[index];

                        log('Menu tapped: ${menu.title}');

                        await navigateWithAd(menu);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),

                            buildContainer(
                              url: filteredMenus[index].url
                                  .toString(),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                filteredMenus[index].title.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                  color: CustomColors.white,
                                  fontSize: 14,
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BannerAdmob(),
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
            'Search not match found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

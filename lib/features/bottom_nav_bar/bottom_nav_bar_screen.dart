import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:satellite_view/features/bottom_nav_bar/bottom_nav_bar_provider.dart';
import 'package:satellite_view/features/home/camera/camera_screen.dart';
import 'package:satellite_view/features/home/route_finder/route_finder_screen.dart';
import 'package:satellite_view/features/home/satellite_view/satellite_view_screen.dart';
import 'package:satellite_view/features/home/satellite_view/satellite_view_screen1.dart';
import 'package:satellite_view/main.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/interstitial_ad_mob.dart';
import '../../core/theme/custom_colors.dart';
import '../../globle/globle_pop_scope_provider.dart';
import '../../mob_ads/interstitial_ads/ad_frequency_manager.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {

  // final List<GlobalKey<NavigatorState>> _navigatorKeys = [
  //   GlobalKey<NavigatorState>(),
  //   GlobalKey<NavigatorState>(),
  //   GlobalKey<NavigatorState>(),
  //   GlobalKey<NavigatorState>(),
  // ];

  // Widget _buildNavigator(GlobalKey<NavigatorState> key, Widget page) {
  //   return Navigator(
  //     key: key,
  //     onGenerateRoute: (route) => MaterialPageRoute(builder: (_) => page),
  //   );
  // }

  //   onWillPop: () async {
  //   final currentNavigator = _navigatorKeys[navBarProvider.currentIndex].currentState;
  //
  //   /// 1️⃣ Try popping current tab
  //   if (currentNavigator != null && currentNavigator.canPop()) {
  //   currentNavigator.pop();
  //   return false;
  //   }
  //
  //   /// 2️⃣ Handle double back to exit
  //   return onPopProvider.handleBackPress(context);
  // },
  @override
  void initState() {
    super.initState();
  }



  final List<Widget> _pages = [
        HomeScreen(),
        SatelliteViewScreen1(),
        CameraScreen(),
        // SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<BottomNavBarProvider, GloblePopScopeProvider>(
      builder:
          (
            context,
            BottomNavBarProvider navBarProvider,
            GloblePopScopeProvider onPopProvider,
            Widget? child,
          ) {
            // ignore: deprecated_member_use
            return Scaffold(
              // body: IndexedStack(
              //   index: navBarProvider.currentIndex,
              //   children: [
              //     // _buildNavigator(_navigatorKeys[0], HomeScreen()),
              //     // _buildNavigator(_navigatorKeys[1], SearchScreen()),
              //     // _buildNavigator(_navigatorKeys[2], SavedScreen()),
              //     // _buildNavigator(_navigatorKeys[3], SettingsScreen()),
              //     HomeScreen(),
              //     SearchScreen(),
              //     SavedScreen(),
              //     SettingsScreen(),
              //   ],
              // ),

              body: _pages[navBarProvider.currentIndex],

              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xff9FA8B3),
                      blurRadius: 5,
                      spreadRadius: 2,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Consumer<BottomNavBarProvider>(
                    builder: (context, provider, child) {
                      return BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: CustomColors.white,
                        selectedItemColor: CustomColors.primaryColor,
                        unselectedItemColor: CustomColors.grey,
                        currentIndex: provider.currentIndex,
                        onTap: (index)async{
                          if(index == 2){
                            setState(() {
                              isGps = true;
                            });
                          }else{
                            setState(() {
                              isGps = false;
                            });
                          }
                          final shouldShowAd = await AdFrequencyManager.shouldShowAd(index.toString(), fx: 3);
                          if (shouldShowAd) {
                             InterstitialAdMob.showInterstitialAd(onComplete: (){
                              provider.setCurrentIndex(index);

                            });

                          } else {
                            provider.setCurrentIndex(index);
                          }

                          // provider.setCurrentIndex(index);
                        },
                        selectedLabelStyle: TextStyle(color: CustomColors.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: TextStyle(color: CustomColors.grey, fontSize: 10, fontWeight: FontWeight.bold),


                        items: [
                          BottomNavigationBarItem(
                            icon: Image.asset(
                              provider.currentIndex == 0
                                  ? 'assets/images/nav_bar_icons/nav_bar_select_icon1.png'
                                  : 'assets/images/nav_bar_icons/nav_bar_icon1.png',
                              width: 20,
                              height: 20,
                              color: provider.currentIndex == 0
                                  ? CustomColors.primaryColor
                                  : CustomColors.grey,
                            ),
                            label: 'Home',
                          ),
                          BottomNavigationBarItem(
                            icon: Image.asset(
                              provider.currentIndex == 1
                                  ? 'assets/images/nav_bar_icons/map.png'
                                  : 'assets/images/nav_bar_icons/map.png',
                              width: 20,
                              height: 20,
                              color: provider.currentIndex == 1
                                  ? CustomColors.primaryColor
                                  : CustomColors.grey,
                            ),
                            label: "Map",
                          ),
                          BottomNavigationBarItem(
                            icon: Image.asset(
                              provider.currentIndex == 2
                                  ? 'assets/images/home_icons/home_icon_10.png'
                                  : 'assets/images/home_icons/home_icon_10.png',
                              width: 20,
                              height: 20,
                              color: provider.currentIndex == 2
                                  ? CustomColors.primaryColor
                                  : CustomColors.grey,
                            ),
                            label: "View",
                          ),

                          /// This in remender
                          // BottomNavigationBarItem(
                          //   icon: Image.asset(
                          //     'assets/images/home_icons/home_icon_12.png',
                          //     width: 20,
                          //     height: 20,
                          //     color: provider.currentIndex == 3
                          //         ? CustomColors.primaryColor
                          //         : CustomColors.grey,
                          //   ),
                          //   label: "Share",
                          // ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }
}

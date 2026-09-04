import 'package:flutter/material.dart';
import 'package:flutter_app_info/flutter_app_info.dart';
import 'package:satellite_view/mob_ads/banner_ads/banner_ad_mob.dart';

import '../../../core/theme/custom_colors.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final package = AppInfo.of(context).package;

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'About Us',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
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
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          spacing: 10,
          children: [
            Center(child: Text('Live Satellite View', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: CustomColors.primaryColor, fontWeight: FontWeight.bold),)),
            Center(child: Text('Version: ${package.version}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),)),
          ],
        ),
        bottomNavigationBar: BannerAdmob(),
      ),
    );
  }
}

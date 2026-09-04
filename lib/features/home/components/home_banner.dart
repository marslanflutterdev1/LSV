import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {

  int currentIndex = 0;

  final List<String> imageList = [
    'assets/images/undraw/4.png',
    'assets/images/undraw/5.png',
    'assets/images/undraw/6.png',
    'assets/images/undraw/7.png',
    'assets/images/undraw/9.png',
    'assets/images/undraw/10.png',
  ];


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage('assets/images/banner_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: CarouselSlider.builder(
        itemCount: imageList.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: CustomColors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),

              ),
                child: Center(
                  child: Image.asset(
                    imageList[itemIndex],
                    fit: BoxFit.cover,
                  ),
                ),

            ),
        disableGesture: true,
        options: CarouselOptions(
          height: 110,
          aspectRatio: 16 / 9,
          viewportFraction: 0.8,
          initialPage: 0,
          enableInfiniteScroll: true,
          reverse: false,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 3),
          autoPlayAnimationDuration: Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          enlargeFactor: 0.3,
          onPageChanged: (page, reason) {},
          scrollDirection: Axis.horizontal,
          // disableCenter: true
        ),
      ),
      // child: Center(
      //   child: Padding(
      //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //       children: [
      //         Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           mainAxisAlignment: MainAxisAlignment.start,
      //           spacing: 5,
      //           children: [
      //             Text(
      //               'Need some\nhelp?',
      //               style: Theme.of(context).textTheme.headlineLarge?.copyWith(
      //                 color: CustomColors.white,
      //                 fontSize: 22,
      //               ),
      //             ),
      //             Text(
      //               'Get in touch',
      //               style: Theme.of(context).textTheme.labelMedium?.copyWith(
      //                 color: CustomColors.white,
      //                 decorationColor: CustomColors.white, // underline color
      //                 decorationThickness: 1,
      //                 letterSpacing: -0.6,
      //               ),
      //             ),
      //           ],
      //         ),
      //         Image.asset('assets/images/banner_group.png'),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}


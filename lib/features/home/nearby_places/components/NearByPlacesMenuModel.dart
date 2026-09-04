
class NearByPlacesMenuModel {
  final String title;
  final String url;
  final String bannerUnitId;

  NearByPlacesMenuModel({required this.title, required this.url, required this.bannerUnitId});
}


final List<String> titleList = [
  'Hospital', 'Hotel', 'Restaurant', 'Bank', 'ATM', 'School', 'Bus Station', 'Police Station', 'Doctor',
  'Car Wash', 'GYM', 'Electrician', 'Post Office', 'Car Repair', 'Airport', 'Pharmacy', 'Cafe', 'Cinema',
  'Library', 'Parks', 'Mosque', 'Stadium', 'Train Station', 'Fire Station', 'Embassy', 'Museum', 'Accounting',
  'Aquarium', 'Art Gallery', 'Car Rental', 'Bakery', 'Beauty Salon', 'Book Store', 'Car Dealer', 'Dentist','Gas Station',
  'Hair Care', 'Lawyer', 'Parking','Plumber', 'Post Office', 'Real Estate Agency', 'Shoe Store', 'Zoo'
];

final List<String> bannerUnitIdList =
List.filled(44, 'ca-app-pub-3940256099942544/6300978111');

final List<String> urlList = [
  'assets/images/nearby_place_icons/nearby_place_icon1.png',
  'assets/images/nearby_place_icons/nearby_place_icon2.png',
  'assets/images/nearby_place_icons/nearby_place_icon3.png',
  'assets/images/nearby_place_icons/nearby_place_icon4.png',
  'assets/images/nearby_place_icons/nearby_place_icon5.png',
  'assets/images/nearby_place_icons/nearby_place_icon6.png',
  'assets/images/nearby_place_icons/nearby_place_icon7.png',
  'assets/images/nearby_place_icons/nearby_place_icon8.png',
  'assets/images/nearby_place_icons/nearby_place_icon9.png',
  'assets/images/nearby_place_icons/nearby_place_icon10.png',
  'assets/images/nearby_place_icons/nearby_place_icon11.png',
  'assets/images/nearby_place_icons/nearby_place_icon12.png',
  'assets/images/nearby_place_icons/nearby_place_icon13.png',
  'assets/images/nearby_place_icons/nearby_place_icon14.png',
  'assets/images/nearby_place_icons/nearby_place_icon15.png',
  'assets/images/nearby_place_icons/nearby_place_icon16.png',
  'assets/images/nearby_place_icons/nearby_place_icon17.png',
  'assets/images/nearby_place_icons/nearby_place_icon18.png',
  'assets/images/nearby_place_icons/nearby_place_icon19.png',
  'assets/images/nearby_place_icons/nearby_place_icon20.png',
  'assets/images/nearby_place_icons/nearby_place_icon21.png',
  'assets/images/nearby_place_icons/nearby_place_icon22.png',
  'assets/images/nearby_place_icons/nearby_place_icon23.png',
  'assets/images/nearby_place_icons/nearby_place_icon24.png',
  'assets/images/nearby_place_icons/nearby_place_icon25.png',
  'assets/images/nearby_place_icons/nearby_place_icon26.png',
  'assets/images/nearby_place_icons/nearby_place_icon27.png',
  'assets/images/nearby_place_icons/nearby_place_icon28.png',
  'assets/images/nearby_place_icons/nearby_place_icon29.png',
  'assets/images/nearby_place_icons/nearby_place_icon30.png',
  'assets/images/nearby_place_icons/nearby_place_icon31.png',
  'assets/images/nearby_place_icons/nearby_place_icon32.png',
  'assets/images/nearby_place_icons/nearby_place_icon33.png',
  'assets/images/nearby_place_icons/nearby_place_icon34.png',
  'assets/images/nearby_place_icons/nearby_place_icon35.png',
  'assets/images/nearby_place_icons/nearby_place_icon36.png',
  'assets/images/nearby_place_icons/nearby_place_icon37.png',
  'assets/images/nearby_place_icons/nearby_place_icon38.png',
  'assets/images/nearby_place_icons/nearby_place_icon39.png',
  'assets/images/nearby_place_icons/nearby_place_icon40.png',
  'assets/images/nearby_place_icons/nearby_place_icon41.png',
  'assets/images/nearby_place_icons/nearby_place_icon42.png',
  'assets/images/nearby_place_icons/nearby_place_icon43.png',
  'assets/images/nearby_place_icons/nearby_place_icon44.png',
];

// final List<NearByPlacesMenuModel> nearByPlacesMenusList = titleList.map((title) {return NearByPlacesMenuModel(title: title);}).toList();
final List<NearByPlacesMenuModel> nearByPlacesMenusList =
List.generate(
  titleList.length,
      (index) => NearByPlacesMenuModel(
    title: titleList[index],
    url: urlList[index],
    bannerUnitId: bannerUnitIdList[index]
  ),
);
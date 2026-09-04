# Interstitial Ads System - Production Setup Guide

## Overview

This is a production-ready, scalable interstitial ads system with:
- ✅ Preloading mechanism for instant ad display
- ✅ Timeout protection (prevents UI blocking)
- ✅ Event tracking and analytics
- ✅ Smart frequency management
- ✅ Comprehensive error handling
- ✅ Clean, well-documented code

## Architecture

```
lib/mob_ads/
├── config/
│   ├── ad_config.dart              # Centralized configuration
│   └── ad_event_tracker.dart       # Analytics tracking
├── interstitial_ads/
│   ├── interstitial_ad_manager.dart # Main ad manager
│   └── ad_frequency_manager.dart    # Frequency control
└── banner_ads/
    └── ... (existing code)
```

## Quick Start

### 1. Initialize in main.dart (Already Done ✅)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalSP.init();
  await MobileAds.instance.initialize();
  
  // Initialize ad manager with preloading
  InterstitialAdManager.initialize();
  
  runApp(MyApp());
}
```

### 2. Show Ad with Frequency Control

```dart
import 'package:satellite_view/mob_ads/interstitial_ads/ad_frequency_manager.dart';
import 'package:satellite_view/mob_ads/interstitial_ads/interstitial_ad_manager.dart';

// Check if should show ad based on frequency
final shouldShowAd = await AdFrequencyManager.shouldShowAd(
  'home_tap',           // Unique key for this location
  countNo: 2,           // Show every 2nd tap
);

if (shouldShowAd) {
  await InterstitialAdManager.instance.showAd(
    onComplete: () {
      // Navigate or continue after ad
      Navigator.pop(context);
    },
  );
} else {
  // Navigate immediately without ad
  Navigator.pop(context);
}
```

## Configuration

### Setting Production Ad Unit IDs

**Edit:** `lib/mob_ads/config/ad_config.dart`

Replace the TODO placeholders with your real AdMob Ad Unit IDs:

```dart
class AdConfig {
  // Android Production IDs
  static const String _prodAndroidInterstitialAdUnitId = 'ca-app-pub-YOUR_ID/YOUR_AD_UNIT_ID';
  
  // iOS Production IDs
  static const String _prodIosInterstitialAdUnitId = 'ca-app-pub-YOUR_ID/YOUR_AD_UNIT_ID';
}
```

**How to get your Ad Unit IDs:**
1. Go to https://admob.google.com
2. Sign in with your Google account
3. Select your app from Apps list
4. Go to "Ad units" section
5. Copy your Interstitial Ad Unit IDs for Android and iOS

### Customizing Ad Frequency

**Edit:** `lib/mob_ads/config/ad_config.dart`

```dart
class AdConfig {
  // Change default frequency (show every Nth tap)
  static const int defaultInterstitialFrequency = 2;
  
  // Change frequency for specific screens
  static const int onboardingInterstitialFrequency = 1;
  static const int bottomNavInterstitialFrequency = 3;
}
```

### Adjusting Timeouts

**Edit:** `lib/mob_ads/config/ad_config.dart`

```dart
class AdConfig {
  // Max time to wait for ad to load (seconds)
  static const int adLoadTimeoutSeconds = 5;
  
  // Max time user can interact with ad (seconds)
  static const int adShowTimeoutSeconds = 10;
}
```

### Enable/Disable Preloading

**Edit:** `lib/mob_ads/config/ad_config.dart`

```dart
class AdConfig {
  // Set to true to preload next ad while showing current one
  static const bool enableAdPreloading = true;
}
```

## Usage Examples

### Example 1: Simple Navigation with Ad

```dart
// In home_screen.dart
Future<void> navigateWithAd(HomeMenuModel menu) async {
  final shouldShowAd = await AdFrequencyManager.shouldShowAd(menu.title);
  
  if (shouldShowAd) {
    await InterstitialAdManager.instance.showAd(
      onComplete: () => _navigateTo(menu.screen),
    );
  } else {
    _navigateTo(menu.screen);
  }
}
```

### Example 2: Ad on Bottom Navigation Change

```dart
// In bottom_nav_bar_screen.dart
BottomNavigationBar(
  onTap: (index) async {
    final shouldShowAd = await AdFrequencyManager.shouldShowAd(
      index.toString(),
      countNo: 3,  // Show every 3rd tab change
    );
    
    if (shouldShowAd) {
      await InterstitialAdManager.instance.showAd(
        onComplete: () => provider.setCurrentIndex(index),
      );
    } else {
      provider.setCurrentIndex(index);
    }
  },
)
```

### Example 3: Ad with Custom Frequency

```dart
// Custom frequency for specific action
final shouldShowAd = await AdFrequencyManager.shouldShowAd(
  'special_action',
  countNo: 5,  // Show every 5th time this action is performed
);
```

### Example 4: Reset Frequency Counter

```dart
// Reset when user logs out
await AdFrequencyManager.reset('home_tap');

// Or reset all counters
await AdFrequencyManager.resetAll();
```

### Example 5: Get Frequency Stats (Debugging)

```dart
// Check how many ads have been shown
final stats = AdFrequencyManager.getStats('home_tap', interval: 2);
print('Current count: ${stats['current_count']}');
print('Ads shown so far: ${stats['ads_shown_so_far']}');
print('Taps until next ad: ${stats['taps_until_next_ad']}');
```

## Features Explained

### 🔄 Ad Preloading

The system automatically loads the next ad while the current ad is displaying. This results in:
- **Instant display** of next ad
- **Smoother UX** with no loading delays
- **Better monetization** with consistent ad display

Preloading can be disabled in `AdConfig` if needed.

### ⏱️ Timeout Protection

If an ad fails to load within `adLoadTimeoutSeconds`, the flow continues automatically:
- **Prevents UI freezing** indefinitely
- **Graceful degradation** - user can continue using app
- **Better user experience** even with network issues

### 📊 Event Tracking

All ad events are tracked and can be sent to Firebase Analytics:
- Ad loaded
- Ad impression (shown to user)
- Ad clicked
- Ad closed
- Ad failed to load
- Preload started/completed/failed

To enable Firebase Analytics:

```dart
// In ad_event_tracker.dart, uncomment:
// FirebaseAnalytics.instance.logEvent(...)
// FirebaseCrashlytics.instance.log(...)
```

### 🎯 Frequency Management

Smart frequency control prevents ad fatigue:
- Track user actions in local storage
- Show ads at configured intervals
- Reset counters when needed
- Get detailed statistics for debugging

## Testing

### Using Test Ad Unit IDs

The system uses test Ad Unit IDs automatically in debug mode:
```
Android: ca-app-pub-3940256099942544/1033173712
iOS: ca-app-pub-3940256099942544/5214101572
```

These are always used when `kDebugMode` is true, preventing accidental charges during development.

### Testing Preloading

```dart
// Enable debug logging
// All preload events are logged to console
```

### Testing Frequency

```dart
// Check current count
int count = AdFrequencyManager.getCount('test_key');

// Reset for re-testing
await AdFrequencyManager.reset('test_key');

// Get detailed stats
var stats = AdFrequencyManager.getStats('test_key');
```

## Production Checklist

- [ ] Replace test Ad Unit IDs with real ones from AdMob
- [ ] Add iOS App ID to AdConfig
- [ ] Test on real Android device
- [ ] Test on real iOS device (if targeting iOS)
- [ ] Verify preloading works smoothly
- [ ] Monitor ad load rates in AdMob console
- [ ] Enable Firebase Analytics integration
- [ ] Test network failure scenarios (airplane mode)
- [ ] Verify user consent for personalized ads (GDPR)
- [ ] Monitor revenue in AdMob

## Migration from Old Code

### Old Code:
```dart
// Old ad manager
await InterstitialAdManager.instance.showAd(onComplete: () { ... });
```

### New Code:
```dart
// Same API, but with preloading, timeout, and analytics behind the scenes
// No changes needed to existing call sites!
```

The new system is **100% backward compatible** with existing code. Just update AdConfig with production IDs.

## Troubleshooting

### Ads Not Showing

1. **Check Ad Unit IDs** - Verify they're real AdMob IDs, not test IDs
2. **Check Platform** - Ensure ads are configured for your target platform
3. **Check Timeout** - Increase `adLoadTimeoutSeconds` if network is slow
4. **Check Frequency** - Increase `countNo` to show ads more often
5. **Check Logs** - Look for error messages in console

### Ads Load Too Slow

1. **Enable Preloading** - Set `enableAdPreloading = true`
2. **Increase Timeout** - Set `adLoadTimeoutSeconds` to 8-10
3. **Check Network** - Test on fast network connection
4. **Check AdMob** - Verify ads are available for your app/region

### High Ad Rejection Rate

1. **Adjust Frequency** - Don't show ads too frequently
2. **Check Placement** - Avoid showing ads during critical UI actions
3. **Monitor CTR** - Check click-through rate in AdMob

## Support

For issues with:
- **Google Mobile Ads:** https://developers.google.com/admob
- **Flutter Integration:** https://pub.dev/packages/google_mobile_ads
- **This System:** Review code comments in each file

## File Locations

- Configuration: `lib/mob_ads/config/ad_config.dart`
- Analytics: `lib/mob_ads/config/ad_event_tracker.dart`
- Main Manager: `lib/mob_ads/interstitial_ads/interstitial_ad_manager.dart`
- Frequency Control: `lib/mob_ads/interstitial_ads/ad_frequency_manager.dart`
- Helper: `lib/network/ad_helper.dart`

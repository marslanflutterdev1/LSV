# Voice-to-Text Troubleshooting Guide

## Common Issues and Solutions

### 1. **Voice Feature Not Working at All**

#### On Android:
- **Google Play Services Required**: The app needs Google Play Services to be installed on the device
  - Check if Google Play Services is installed (Settings → Apps → Check for "Google Play Services")
  - If missing, install it from Google Play Store
  
- **Permissions**: Make sure the app has microphone permission
  - Go to Settings → Apps → Satellite View → Permissions → Microphone
  - Enable microphone permission
  
- **Build Setup**: Ensure your `build.gradle` files are updated
  - Minimum SDK should be at least 19
  - Target SDK should be 33 or higher

#### On iOS:
- **Permissions**: Grant microphone permission when prompted
- **Network**: Requires internet connection for speech recognition
- **Language**: iOS may have specific language/locale requirements

---

### 2. **Microphone Icon Appears but Doesn't Respond**

**Solution:**
- Tap the microphone icon and wait 1-2 seconds for initialization
- Check if a permission dialog appears and grant it
- Make sure you're speaking clearly and close to the device microphone
- Try speaking in English (default locale)

---

### 3. **"Speech recognition not available" Error**

**Causes:**
- Google Play Services not installed (Android)
- Device doesn't support speech recognition
- Microphone permission denied
- No internet connection (required for recognition)

**Solutions:**
- Install Google Play Services from Play Store
- Check internet connection
- Ensure microphone permission is granted in app settings

---

### 4. **"No voice detected" Message**

**Causes:**
- Microphone not working
- Speaking too quietly
- Device microphone blocked
- Background noise too high

**Solutions:**
- Speak clearly and louder
- Reduce background noise
- Check microphone works with other apps (Voice Recorder, Google Recorder, etc.)
- Restart the app

---

### 5. **Recognized Text is Incorrect or Empty**

- Try speaking more slowly and clearly
- Reduce background noise
- Ensure microphone is not blocked
- Speak in English (default supported language)
- Try restarting the app

---

### 6. **App Crashes When Tapping Microphone**

**Solution:**
- Ensure all permissions are granted:
  ```
  - RECORD_AUDIO
  - INTERNET
  - MICROPHONE
  ```
- Update the app from Play Store if available
- Uninstall and reinstall the app
- Clear app cache: Settings → Apps → Satellite View → Storage → Clear Cache

---

## Testing the Voice Feature

1. **Test Microphone First:**
   - Use the built-in Voice Recorder app to test if microphone works
   
2. **Test in Route Finder Screen:**
   - Navigate to Route Finder
   - Click microphone icon next to "Enter initial address"
   - Speak clearly: "Sydney"
   - Text should appear in the field

3. **Check Logs:**
   - Connect device to computer
   - Run `flutter logs` in terminal
   - Look for "VoiceService:" messages
   - Check for errors and permission issues

---

## Required Permissions (Already Configured)

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.MICROPHONE"/>
```

### iOS (Info.plist)
```
NSMicrophoneUsageDescription: App needs microphone access for voice input
```

---

## Advanced Debugging

Enable debug output:
- Open Android Studio logcat or run `flutter logs`
- Search for "VoiceService" to see detailed logs
- Look for initialization, permission, and recognition status messages

---

## If Nothing Works

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run` again
4. Ensure device has:
   - Minimum Android 5.0+ or iOS 11.0+
   - Google Play Services (Android only)
   - Active internet connection
   - Microphone permission granted

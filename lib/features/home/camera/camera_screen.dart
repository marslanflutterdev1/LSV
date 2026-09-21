import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/features/home/camera/map_camera_location.dart';

import '../../../main.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraDescription? _camera;

  bool _isLoading = true;
  bool _hasCamera = false;
  bool _permissionDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Recheck camera permission when the app comes back to foreground.
  ///
  /// This handles the case where the user:
  /// 1. Denied camera permission
  /// 2. Went to iOS Settings
  /// 3. Enabled camera manually
  /// 4. Returned to the app
  ///
  /// On the next tap, camera should work without requiring an app restart.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Only re-check if we are currently in the denied state
      // and the camera is not already loaded.
      if (!_hasCamera && _permissionDenied) {
        _loadCamera();
      }
    }
  }

  /// Loads the available device cameras.
  ///
  /// Explicitly requests camera permission BEFORE calling
  /// availableCameras(). Without this, iOS never shows the prompt
  /// and availableCameras() returns an empty list.
  Future<void> _loadCamera() async {
    try {
      log('CameraScreen: Checking camera permission...');

      // 1. Always re-read the CURRENT permission status.
      //    If the user enabled it in Settings, this returns .granted.
      PermissionStatus status = await Permission.camera.status;

      // 2. Request only if not decided yet.
      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      // 3. If denied or permanently denied, show fallback.
      if (status.isDenied ||
          status.isPermanentlyDenied ||
          status.isRestricted) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasCamera = false;
          _permissionDenied = true;
          _errorMessage = status.isPermanentlyDenied
              ? 'Camera access is turned off. Please enable camera access in iOS Settings.'
              : 'Camera access was denied. Allow camera access to use this feature.';
        });
        return;
      }

      // 4. Permission granted — now load cameras.
      log('CameraScreen: Loading available cameras...');
      final List<CameraDescription> cameras = await availableCameras();

      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasCamera = false;
          _permissionDenied = false;
          _errorMessage = 'No camera is available on this device.';
        });
        return;
      }

      // Prefer the back camera.
      CameraDescription selectedCamera = cameras.first;
      for (final CameraDescription availableCamera in cameras) {
        if (availableCamera.lensDirection == CameraLensDirection.back) {
          selectedCamera = availableCamera;
          break;
        }
      }

      log(
        'CameraScreen: Selected camera: ${selectedCamera.name}, '
            'direction: ${selectedCamera.lensDirection}',
      );

      setState(() {
        _camera = selectedCamera;
        _isLoading = false;
        _hasCamera = true;
        _permissionDenied = false;
        _errorMessage = null;
      });
    } on CameraException catch (e, stackTrace) {
      log(
        'CameraScreen CameraException: ${e.code}',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasCamera = false;
        _permissionDenied = e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessDeniedWithoutPrompt' ||
            e.code == 'CameraAccessRestricted';
        _errorMessage = _cameraExceptionMessage(e);
      });
    } catch (e, stackTrace) {
      log(
        'CameraScreen error',
        error: e,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasCamera = false;
        _permissionDenied = false;
        _errorMessage =
        'The camera is currently unavailable. Please try again.';
      });
    }
  }

  String _cameraExceptionMessage(CameraException exception) {
    switch (exception.code) {
      case 'CameraAccessDenied':
        return 'Camera access was denied. Please allow camera access to use this feature.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access is turned off. Please enable camera access in Settings.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      default:
        return 'The camera could not be initialized.';
    }
  }

  void _goBack() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavBarScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_hasCamera || _camera == null) {
      return _buildCameraUnavailableScreen();
    }

    return MapCameraLocation(
      key: ValueKey(_camera!.name),
      camera: _camera!,
      onImageCaptured: _handleImageAndLocationData,
    );
  }

  Widget _buildLoadingScreen() {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildCameraUnavailableScreen() {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(31.5204, 74.3587),
                zoom: 16,
              ),
              mapType: MapType.satellite,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: false,
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: _buildCameraErrorCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraErrorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CustomColors.primaryColor,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _permissionDenied
                ? 'Camera access is off'
                : 'Camera unavailable',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ??
                'The camera is not available on this device.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Camera',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: CustomColors.primaryColor,
      leading: isGps
          ? const SizedBox.shrink()
          : GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goBack,
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
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _handleImageAndLocationData(
      ImageAndLocationData data,
      ) {
    log('Image Path: ${data.imagePath}');
    log('Latitude: ${data.latitude}');
    log('Longitude: ${data.longitude}');
    log('Location Name: ${data.locationName}');
    log('SubLocation: ${data.subLocation}');
  }
}
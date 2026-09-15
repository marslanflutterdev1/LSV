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

class _CameraScreenState extends State<CameraScreen> {
  CameraDescription? camera;
  bool isCameraReady = false;
  bool _cameraError = false;
  bool _permissionDenied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // 1. Check current camera permission status
      PermissionStatus status = await Permission.camera.status;

      // 2. If not yet decided, request it
      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      // 3. If denied or permanently denied, show fallback screen
      if (status.isDenied ||
          status.isPermanentlyDenied ||
          status.isRestricted) {
        if (!mounted) return;
        setState(() {
          _permissionDenied = true;
          _cameraError = true;
          _isLoading = false;
        });
        return;
      }

      // 4. Permission granted — load available cameras
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isNotEmpty) {
        setState(() {
          camera = cameras.first;
          isCameraReady = true;
          _cameraError = false;
          _permissionDenied = false;
          _isLoading = false;
        });
      } else {
        // Permission granted but no camera available (rare, but possible on simulator)
        setState(() {
          isCameraReady = false;
          _cameraError = true;
          _permissionDenied = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Camera initialization error: $e');
      if (!mounted) return;
      setState(() {
        isCameraReady = false;
        _cameraError = true;
        _isLoading = false;
      });
    }
  }

  void _handleImageAndLocationData(ImageAndLocationData data) {
    log('Image Path: ${data.imagePath}');
    log('Latitude: ${data.latitude}');
    log('Longitude: ${data.longitude}');
    log('Location Name: ${data.locationName}');
    log('SubLocation: ${data.subLocation}');
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Loading state
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cameraError || !isCameraReady || camera == null) {
      return SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
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
                ? SizedBox.shrink()
                : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BottomNavBarScreen()),
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              // ✅ Default map — no location features, no permission needed
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(
                    31.5204,
                    74.3587,
                  ), // Lahore — matches app default
                  zoom: 16,
                ),
                mapType: MapType.satellite,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
              ),

              // ✅ Full-screen overlay with the informational message
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _permissionDenied
                            ? 'Camera permission access is off'
                            : 'Camera unavailable',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _permissionDenied
                            ? 'You can enable camera access in iOS Settings to take photos.'
                            : 'This device does not have a camera available.',
    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
    textAlign: TextAlign.start,

                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Camera ready — show map camera screen
    return MapCameraLocation(
      camera: camera!,
      onImageCaptured: _handleImageAndLocationData,
    );
  }
}

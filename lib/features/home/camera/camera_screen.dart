

import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:satellite_view/features/home/camera/map_camera_location.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraDescription? camera;
  bool isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      setState(() {
        camera = cameras.first;
        isCameraReady = true;
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
    if (!isCameraReady || camera == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MapCameraLocation(
      camera: camera!,
      onImageCaptured: _handleImageAndLocationData,
    );
  }
}


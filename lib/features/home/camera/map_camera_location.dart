// ============================================
// COMPLETE MAP CAMERA FLUTTER PACKAGE
// Single file implementation - FIXED VERSION
// ============================================

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as lat;
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/main.dart';
import 'package:satellite_view/widgets/custom_button.dart';
import 'package:satellite_view/widgets/custom_circle_progress_indicator.dart';

import '../../../mob_ads/banner_ads/banner_ad_mob.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';

// ============================================
// DATA MODELS
// ============================================

/// Data class for location information
class LocationData {
  final String? latitude;
  final String? longitude;
  final String? locationName;
  final String? subLocation;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.subLocation,
  });

  @override
  bool operator ==(Object other) {
    return other is LocationData &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        locationName == other.locationName &&
        subLocation == other.subLocation;
  }

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, locationName, subLocation);
}

/// Data class for image and location data combined
class ImageAndLocationData {
  final String? imagePath;
  final LocationData? locationData;

  String? get latitude => locationData?.latitude;
  String? get longitude => locationData?.longitude;
  String? get locationName => locationData?.locationName;
  String? get subLocation => locationData?.subLocation;

  ImageAndLocationData({required this.imagePath, required this.locationData});
}

/// Callback function type for capturing image and location data
typedef ImageAndLocationCallback = void Function(ImageAndLocationData data);

// ============================================
// ENUMS
// ============================================

enum AlignOnUpdate { always, never }

// ============================================
// CUSTOM CURRENT LOCATION LAYER
// ============================================

class CurrentLocationLayer extends StatefulWidget {
  final Stream<double?> alignPositionStream;
  final AlignOnUpdate alignPositionOnUpdate;
  final MapController mapController;
  final bool mapReady;

  const CurrentLocationLayer({
    super.key,
    required this.alignPositionStream,
    required this.alignPositionOnUpdate,
    required this.mapController,
    required this.mapReady,
  });

  @override
  State<CurrentLocationLayer> createState() => _CurrentLocationLayerState();
}

class _CurrentLocationLayerState extends State<CurrentLocationLayer> {
  lat.LatLng? _currentPosition;
  StreamSubscription<double?>? _alignPositionSubscription;

  bool get _isControllerReady {
    try {
      widget.mapController;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _listenToPositionUpdates();
  }

  void _listenToPositionUpdates() {
    _alignPositionSubscription =
        widget.alignPositionStream.listen((zoom) {
      if (!mounted) return;
      _updatePosition();
    });
  }

  Future<void> _updatePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final newPosition = lat.LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _currentPosition = newPosition;
      });

      if (widget.alignPositionOnUpdate == AlignOnUpdate.always &&
          _isControllerReady &&
          widget.mapReady) {
        widget.mapController.move(newPosition, 13.0);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating position: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: [
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentPosition!,
          alignment: Alignment.center,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
        ),
      ],
    );
  }
}

// ============================================
// MAIN WIDGET - MapCameraLocation
// ============================================

class MapCameraLocation extends StatefulWidget {
  final CameraDescription camera;
  final ImageAndLocationCallback? onImageCaptured;

  const MapCameraLocation({
    super.key,
    required this.camera,
    this.onImageCaptured,
  });

  @override
  State<MapCameraLocation> createState() => _MapCameraLocationState();
}

class _MapCameraLocationState extends State<MapCameraLocation> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late AlignOnUpdate _followOnLocationUpdate;
  late StreamController<double?> _followCurrentLocationStreamController;
  late MapController _mapController;
  bool _isMapReady = false;

  File? cameraImagePath;
  String? dateTime;
  LocationData? locationData;
  Timer? _positionTimer;

  final globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize position timer
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        await updatePosition(context);
        _followCurrentLocationStreamController.add(null);
      }
    });

    // Initialize camera controller
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    _mapController = MapController();
    _followOnLocationUpdate = AlignOnUpdate.always;
    _followCurrentLocationStreamController = StreamController<double?>.broadcast();

    // Get current date and time
    dateTime = DateFormat.yMd().add_jm().format(DateTime.now());
  }

  @override
  void dispose() {
    _controller.dispose();
    _followCurrentLocationStreamController.close();
    _positionTimer?.cancel();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          leading: isGps ? SizedBox.shrink() : GestureDetector(
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return RepaintBoundary(
                key: globalKey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller),
                    _buildBottomOverlay(),


                  ],
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent
          ),
          child: CustomButton(text: 'Pick Image', onPressed: _takeScreenshot, isLoading: false),
        ),


      ),
    );
  }

  // ============================================
  // PRIVATE WIDGET BUILDERS
  // ============================================

  Widget _buildBottomOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 5,
      child: Column(
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 160,
              child:Row(
                spacing: 5,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadiusGeometry.circular(4),
                        border: Border.all(
                          color: CustomColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: locationData == null
                          ? const Center(child: CustomCircleProgressIndicator())
                          : Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Center(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const lat.LatLng(0, 0),
                              initialZoom: 0.0,
                              onPositionChanged: (position, hasGesture) {
                                if (hasGesture) {
                                  setState(() {
                                    _followOnLocationUpdate =
                                        AlignOnUpdate.never;
                                  });
                                }
                              },
                              onMapReady: () {
                                setState(() {
                                  _isMapReady = true;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                                userAgentPackageName:
                                'com.example.satellite_view',
                                minZoom: 0.0,
                              ),
                              CurrentLocationLayer(
                                alignPositionStream:
                                _followCurrentLocationStreamController
                                    .stream,
                                alignPositionOnUpdate: _followOnLocationUpdate,
                                mapController: _mapController,
                                mapReady: _isMapReady,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadiusGeometry.circular(4),
                        border: Border.all(
                          color: CustomColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                locationData?.locationName ?? "Loading...",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style:Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                            const SizedBox(height: 5),
                            Text(
                                locationData?.subLocation ?? "Loading ..",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style:Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                            const SizedBox(height: 10),
                            Text(
                                "Lat ${locationData?.latitude ?? "Loading.."}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style:Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                            const SizedBox(height: 5),
                            Text(
                                "Long ${locationData?.longitude ?? "Loading.."}",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style:Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                            const SizedBox(height: 10),
                            Text(
                                dateTime ?? "Loading...",
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style:Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            ),
          ),
          BannerAdmob(),

        ],
      ),
    );
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  Future<void> _takeScreenshot() async {
    try {
      await _initializeControllerFuture;
      await _captureScreenshot();
    } catch (e) {
      if (kDebugMode) {
        print('Error taking screenshot: $e');
      }
    }
  }

  Future<void> _captureScreenshot() async {
    var rng = Random();
    final RenderRepaintBoundary boundary =
        globalKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage();
    final directory = await getApplicationDocumentsDirectory();

    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    File imgFile = File('${directory.path}/screenshot${rng.nextInt(200)}.png');
    await imgFile.writeAsBytes(pngBytes);

    if (imgFile.existsSync()) {
      setState(() {
        cameraImagePath = imgFile;
      });

      if (widget.onImageCaptured != null) {
        ImageAndLocationData data = ImageAndLocationData(
          imagePath: imgFile.path,
          locationData: locationData,
        );
        widget.onImageCaptured!(data);
      }
    } else {
      debugPrint('File does not exist');
    }
  }

  Future<void> updatePosition(BuildContext context) async {
    try {
      final position = await _determinePosition();
      final placeMarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      LocationData newLocationData;
      if (placeMarks.isNotEmpty) {
        final placeMark = placeMarks.first;
        newLocationData = LocationData(
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
          locationName:
              "${placeMark.locality ?? ""}, ${placeMark.administrativeArea ?? ""}, ${placeMark.country ?? ""}",
          subLocation:
              "${placeMark.street ?? ""}, ${placeMark.thoroughfare ?? ""} ${placeMark.administrativeArea ?? ""}",
        );
      } else {
        newLocationData = LocationData(
          longitude: null,
          latitude: null,
          locationName: 'No Location Data',
          subLocation: "",
        );
      }

      if (newLocationData != locationData) {
        setState(() {
          locationData = newLocationData;
        });
      }

      if (kDebugMode) {
        print(
          "Latitude: ${newLocationData.latitude}, "
          "Longitude: ${newLocationData.longitude}, "
          "Location: ${newLocationData.locationName}",
        );
      }
    } catch (e) {
      setState(() {
        locationData = LocationData(
          longitude: null,
          latitude: null,
          locationName: 'Error Retrieving Location',
          subLocation: "",
        );
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }
}


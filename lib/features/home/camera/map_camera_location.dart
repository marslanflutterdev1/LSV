import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as lat;
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';

import 'package:satellite_view/core/theme/custom_colors.dart';
import 'package:satellite_view/widgets/custom_button.dart';
import 'package:satellite_view/widgets/custom_circle_progress_indicator.dart';

import '../../../mob_ads/banner_ads/banner_ad_mob.dart';
import '../../bottom_nav_bar/bottom_nav_bar_screen.dart';
import '../../../main.dart';


// ============================================================
// DATA MODELS
// ============================================================

class LocationData {
  final String? latitude;
  final String? longitude;
  final String? locationName;
  final String? subLocation;

  const LocationData({
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
  int get hashCode {
    return Object.hash(
      latitude,
      longitude,
      locationName,
      subLocation,
    );
  }
}


class ImageAndLocationData {
  final String? imagePath;
  final LocationData? locationData;

  const ImageAndLocationData({
    required this.imagePath,
    required this.locationData,
  });

  String? get latitude => locationData?.latitude;

  String? get longitude => locationData?.longitude;

  String? get locationName => locationData?.locationName;

  String? get subLocation => locationData?.subLocation;
}


typedef ImageAndLocationCallback = void Function(
    ImageAndLocationData data,
    );


// ============================================================
// CAMERA ERROR TYPE
// ============================================================

enum _CameraErrorType {
  denied,
  deniedWithoutPrompt,
  restricted,
  unavailable,
  unknown,
}


// ============================================================
// MAIN WIDGET
// ============================================================

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


// ============================================================
// STATE
// ============================================================

class _MapCameraLocationState extends State<MapCameraLocation>
    with WidgetsBindingObserver {

  // ----------------------------------------------------------
  // Camera
  // ----------------------------------------------------------

  CameraController? _controller;

  Future<void>? _initializeControllerFuture;

  _CameraErrorType? _cameraErrorType;

  String? _cameraErrorMessage;

  bool _isCameraInitializing = true;


  // ----------------------------------------------------------
  // Location
  // ----------------------------------------------------------

  bool hasLocationPermission = false;

  bool _isLoadingLocation = false;

  LocationData? locationData;


  // ----------------------------------------------------------
  // Screenshot
  // ----------------------------------------------------------

  File? cameraImagePath;

  final GlobalKey _globalKey = GlobalKey();


  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  String? dateTime;

  final MapController _mapController = MapController();

  bool _isMapReady = false;

  lat.LatLng? _currentLatLng;


  // ----------------------------------------------------------
  // Lifecycle
  // ----------------------------------------------------------

  bool _isDisposed = false;

  bool _locationRequestInProgress = false;


  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    dateTime = DateFormat.yMd().add_jm().format(
      DateTime.now(),
    );

    _initializeCamera();

    // Location is OPTIONAL.
    //
    // We deliberately do not make camera initialization depend
    // on location.
    //
    // Camera must work even if:
    // - Location Services are disabled
    // - location permission is denied
    // - location permission is restricted
    // - geocoding fails
    //
    Future.delayed(
      const Duration(milliseconds: 700),
          () {
        if (mounted) {
          _loadLocation();
        }
      },
    );
  }


  // ==========================================================
  // CAMERA INITIALIZATION
  // ==========================================================

  Future<void> _initializeCamera() async {
    if (_isDisposed) {
      return;
    }

    if (mounted) {
      setState(() {
        _isCameraInitializing = true;
        _cameraErrorType = null;
        _cameraErrorMessage = null;
      });
    }

    CameraController? previousController = _controller;

    if (previousController != null) {
      try {
        await previousController.dispose();
      } catch (_) {}
    }

    final CameraController controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    final Future<void> initialization = controller.initialize();

    _initializeControllerFuture = initialization;

    try {
      await initialization;

      if (_isDisposed || !mounted) {
        return;
      }

      if (!controller.value.isInitialized) {
        throw CameraException(
          'CameraInitializationFailed',
          'The camera controller did not initialize correctly.',
        );
      }

      setState(() {
        _isCameraInitializing = false;
        _cameraErrorType = null;
        _cameraErrorMessage = null;
      });

      log(
        'Camera initialized successfully: ${widget.camera.name}',
      );

    } on CameraException catch (e, stackTrace) {
      log(
        'Camera initialization failed: ${e.code}',
        error: e,
        stackTrace: stackTrace,
      );

      if (_isDisposed || !mounted) {
        return;
      }

      setState(() {
        _isCameraInitializing = false;

        // ✅ Neutral error messages — no Settings references
        switch (e.code) {
          case 'CameraAccessDenied':
            _cameraErrorType = _CameraErrorType.denied;
            _cameraErrorMessage =
            "This feature isn't available right now.";
            break;

          case 'CameraAccessDeniedWithoutPrompt':
            _cameraErrorType =
                _CameraErrorType.deniedWithoutPrompt;
            _cameraErrorMessage =
            "This feature isn't available right now.";
            break;

          case 'CameraAccessRestricted':
            _cameraErrorType =
                _CameraErrorType.restricted;
            _cameraErrorMessage =
            "This feature isn't available right now.";
            break;

          default:
            _cameraErrorType =
                _CameraErrorType.unknown;
            _cameraErrorMessage =
            'The camera could not be initialized. Please try again.';
        }
      });

    } catch (e, stackTrace) {
      log(
        'Unexpected camera initialization error',
        error: e,
        stackTrace: stackTrace,
      );

      if (_isDisposed || !mounted) {
        return;
      }

      setState(() {
        _isCameraInitializing = false;
        _cameraErrorType = _CameraErrorType.unknown;
        _cameraErrorMessage =
        'The camera could not be initialized. Please try again.';
      });
    }
  }


  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    super.didChangeAppLifecycleState(state);

    final CameraController? controller = _controller;

    if (controller == null) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      log('Camera lifecycle: disposing controller');

      controller.dispose();

      _controller = null;
      _initializeControllerFuture = null;

      if (mounted) {
        setState(() {
          _isCameraInitializing = true;
        });
      }

    } else if (state == AppLifecycleState.resumed) {
      log('Camera lifecycle: reinitializing controller');

      if (_controller == null && mounted) {
        _initializeCamera();
      }
    }
  }


  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<void> _loadLocation() async {
    if (_isDisposed ||
        _locationRequestInProgress ||
        !mounted) {
      return;
    }

    _locationRequestInProgress = true;

    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
      });
    }

    try {
      final Position? position = await _getOptionalPosition();

      if (_isDisposed || !mounted) {
        return;
      }

      if (position == null) {
        setState(() {
          hasLocationPermission = false;
          _isLoadingLocation = false;

          locationData = const LocationData(
            latitude: null,
            longitude: null,
            locationName: 'Location unavailable',
            subLocation:
            'Camera works without location access.',
          );

          _currentLatLng = null;
        });

        return;
      }

      final LocationData data =
      await _createLocationData(position);

      if (_isDisposed || !mounted) {
        return;
      }

      setState(() {
        hasLocationPermission = true;
        _isLoadingLocation = false;
        locationData = data;

        _currentLatLng = lat.LatLng(
          position.latitude,
          position.longitude,
        );
      });

    } catch (e, stackTrace) {
      log(
        'Optional location error',
        error: e,
        stackTrace: stackTrace,
      );

      if (_isDisposed || !mounted) {
        return;
      }

      setState(() {
        hasLocationPermission = false;
        _isLoadingLocation = false;

        locationData = const LocationData(
          latitude: null,
          longitude: null,
          locationName: 'Location unavailable',
          subLocation:
          'Camera works without location access.',
        );

        _currentLatLng = null;
      });

    } finally {
      _locationRequestInProgress = false;
    }
  }


  /// Optional location access.
  ///
  /// This method NEVER opens Settings.
  /// It NEVER blocks camera functionality.
  Future<Position?> _getOptionalPosition() async {
    try {
      final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        log('Location Services are disabled.');
        return null;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        log('Location permission denied.');
        return null;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        log('Location permission permanently denied.');
        return null;
      }

      final Position position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return position;

    } catch (e, stackTrace) {
      log(
        'Optional location failed',
        error: e,
        stackTrace: stackTrace,
      );

      return null;
    }
  }


  Future<LocationData> _createLocationData(
      Position position,
      ) async {
    try {
      final List<Placemark> placemarks =
      await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        final String locationName =
        _cleanLocationText(
          [
            place.locality,
            place.administrativeArea,
            place.country,
          ],
        );

        final String subLocation =
        _cleanLocationText(
          [
            place.street,
            place.thoroughfare,
            place.subAdministrativeArea,
          ],
        );

        return LocationData(
          latitude: position.latitude.toStringAsFixed(6),
          longitude: position.longitude.toStringAsFixed(6),
          locationName:
          locationName.isEmpty
              ? 'Current location'
              : locationName,
          subLocation:
          subLocation.isEmpty
              ? 'Location details unavailable'
              : subLocation,
        );
      }

    } catch (e, stackTrace) {
      log(
        'Reverse geocoding failed',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return LocationData(
      latitude: position.latitude.toStringAsFixed(6),
      longitude: position.longitude.toStringAsFixed(6),
      locationName: 'Current location',
      subLocation: 'Address unavailable',
    );
  }


  String _cleanLocationText(
      List<String?> values,
      ) {
    return values
        .where(
          (value) =>
      value != null &&
          value.trim().isNotEmpty,
    )
        .map((value) => value!.trim())
        .join(', ');
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor:
        Theme.of(context).scaffoldBackgroundColor,

        body: _buildBody(),

        bottomNavigationBar:
        _buildBottomNavigationBar(),
      ),
    );
  }


  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isCameraInitializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_cameraErrorType != null ||
        _controller == null) {
      return _buildCameraErrorView();
    }

    final CameraController controller =
    _controller!;

    if (!controller.value.isInitialized) {
      return _buildCameraErrorView();
    }

    return RepaintBoundary(
      key: _globalKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),

          _buildBottomOverlay(),
        ],
      ),
    );
  }


  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Camera',
        style:
        Theme.of(context).textTheme.titleLarge?.copyWith(
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
        onTap: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BottomNavBarScreen(),
            ),
                (route) => false,
          );
        },
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
            CustomColors.iconBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back,
              color:
              CustomColors.primaryColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // CAMERA ERROR VIEW
  // ==========================================================

  Widget _buildCameraErrorView() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                _cameraErrorType ==
                    _CameraErrorType.restricted
                    ? Icons.block
                    : Icons.camera_alt_outlined,
                size: 72,
                color: CustomColors.primaryColor,
              ),

              const SizedBox(height: 20),

              Text(
                // ✅ Neutral title — no directive language
                'Camera unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _cameraErrorMessage ??
                    "This feature isn't available right now.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _initializeCamera();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Try Again',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ==========================================================
  // BOTTOM OVERLAY
  // ==========================================================

  Widget _buildBottomOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    child: _buildMiniMap(),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    flex: 2,
                    child: _buildLocationCard(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          BannerAdmob(),
        ],
      ),
    );
  }


  // ==========================================================
  // MINI MAP
  // ==========================================================

  Widget _buildMiniMap() {
    final lat.LatLng center =
        _currentLatLng ??
            const lat.LatLng(
              31.5204,
              74.3587,
            );

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius:
        BorderRadius.circular(4),
        border: Border.all(
          color: CustomColors.primaryColor,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(2),
        child: FlutterMap(
          mapController: _mapController,

          options: MapOptions(
            initialCenter: center,
            initialZoom:
            _currentLatLng == null
                ? 5
                : 13,

            onMapReady: () {
              if (!mounted) return;

              setState(() {
                _isMapReady = true;
              });
            },
          ),

          children: [
            TileLayer(
              urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',

              subdomains:
              const [
                'a',
                'b',
                'c',
                'd',
              ],

              userAgentPackageName:
              'com.maps.sateliteview',
            ),

            if (_currentLatLng != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLatLng!,
                    width: 50,
                    height: 50,
                    alignment:
                    Alignment.center,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // LOCATION CARD
  // ==========================================================

  Widget _buildLocationCard() {
    final bool locationAvailable =
        hasLocationPermission &&
            locationData != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius:
        BorderRadius.circular(4),
        border: Border.all(
          color: CustomColors.primaryColor,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      child: _isLoadingLocation
          ? const Center(
        child:
        CustomCircleProgressIndicator(),
      )
          : Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            locationAvailable
                ? locationData!
                .locationName ??
                'Current location'
                : 'Location unavailable',

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              color: Colors.white,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            locationAvailable
                ? locationData!
                .subLocation ??
                ''
                : 'Camera works without location access.',

            maxLines: 2,

            overflow:
            TextOverflow.ellipsis,

            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Lat: ${locationData?.latitude ?? '--'}',

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Long: ${locationData?.longitude ?? '--'}',

            maxLines: 1,

            overflow:
            TextOverflow.ellipsis,

            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color: Colors.white,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            dateTime ?? '',
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // BOTTOM BUTTON
  // ==========================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      color: Colors.transparent,

      child: CustomButton(
        text: 'Capture Image',
        onPressed: _takeScreenshot,
        isLoading: false,
      ),
    );
  }


  // ==========================================================
  // CAPTURE SCREENSHOT
  // ==========================================================

  Future<void> _takeScreenshot() async {
    if (!mounted) {
      return;
    }

    final CameraController? controller =
        _controller;

    if (controller == null ||
        !controller.value.isInitialized) {
      _showMessage(
        'Camera is not ready yet.',
      );

      return;
    }

    try {
      final Future<void>? initialization =
          _initializeControllerFuture;

      if (initialization != null) {
        await initialization;
      }

      await WidgetsBinding
          .instance
          .endOfFrame;

      await _captureScreenshot();

    } on CameraException catch (e) {
      log(
        'Camera capture error: ${e.code}',
        error: e,
      );

      _showMessage(
        'Unable to capture image.',
      );

    } catch (e, stackTrace) {
      log(
        'Screenshot error',
        error: e,
        stackTrace: stackTrace,
      );

      _showMessage(
        'Unable to capture image. Please try again.',
      );
    }
  }


  Future<void> _captureScreenshot() async {
    final BuildContext? repaintContext =
        _globalKey.currentContext;

    if (repaintContext == null) {
      throw StateError(
        'Camera capture area is not ready.',
      );
    }

    final RenderObject? renderObject =
    repaintContext.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'Camera capture boundary is not available.',
      );
    }

    final double pixelRatio =
    MediaQuery.of(context)
        .devicePixelRatio
        .clamp(
      1.0,
      3.0,
    );

    final ui.Image image =
    await renderObject.toImage(
      pixelRatio: pixelRatio,
    );

    try {
      final ByteData? byteData =
      await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw StateError(
          'Could not convert captured image.',
        );
      }

      final Uint8List pngBytes =
      byteData.buffer.asUint8List();

      final Directory directory =
      await getApplicationDocumentsDirectory();

      final String fileName =
          'camera_${DateTime.now().millisecondsSinceEpoch}.png';

      final File imageFile =
      File(
        '${directory.path}/$fileName',
      );

      await imageFile.writeAsBytes(
        pngBytes,
        flush: true,
      );

      if (!await imageFile.exists()) {
        throw StateError(
          'Captured image was not saved.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        cameraImagePath = imageFile;
      });

      final ImageAndLocationData data =
      ImageAndLocationData(
        imagePath: imageFile.path,
        locationData: locationData,
      );

      widget.onImageCaptured?.call(data);

      _showMessage(
        'Image captured successfully.',
      );

    } finally {
      image.dispose();
    }
  }


  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }


  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _isDisposed = true;

    WidgetsBinding.instance
        .removeObserver(this);

    final CameraController? controller =
        _controller;

    _controller = null;

    if (controller != null) {
      controller.dispose();
    }

    super.dispose();
  }
}
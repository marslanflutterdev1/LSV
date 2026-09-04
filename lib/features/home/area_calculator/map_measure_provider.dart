import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class MapMeasureProvider extends ChangeNotifier {

  final List<LatLng> _points = [];

  final Set<Marker> _markers = {};

  final Set<Polyline> _polylines = {};

  final Set<Polygon> _polygons = {};

  double _area = 0;

  double _perimeter = 0;

  List<LatLng> get points => _points;

  Set<Marker> get markers => _markers;

  Set<Polyline> get polylines => _polylines;

  Set<Polygon> get polygons => _polygons;

  double get area => _area;

  double get perimeter => _perimeter;

  /// ADD POINT
  void addPoint(LatLng position) {

    _points.add(position);

    _updateMap();

    notifyListeners();
  }

  /// UPDATE MAP
  void _updateMap() {

    _markers.clear();

    for (int i = 0; i < _points.length; i++) {

      _markers.add(
        Marker(
          markerId: MarkerId(i.toString()),

          position: _points[i],

          draggable: true,

          onDragEnd: (newPosition) {

            _points[i] = newPosition;

            _updateMap();

            notifyListeners();
          },
        ),
      );
    }

    /// POLYLINE
    _polylines.clear();

    _polylines.add(
      Polyline(
        polylineId: const PolylineId("polyline"),

        points: _points,

        width: 4,

        geodesic: true,
      ),
    );

    /// POLYGON
    _polygons.clear();

    if (_points.length >= 3) {

      _polygons.add(
        Polygon(
          polygonId: const PolygonId("polygon"),

          points: _points,

          strokeWidth: 3,

          geodesic: true,

          strokeColor: Colors.blue,

          fillColor: Colors.blue.withOpacity(0.25),
        ),
      );

      /// AREA
      _area = mp.SphericalUtil.computeArea(_points.map((e) => mp.LatLng(e.latitude, e.longitude,),).toList()).toDouble();
    }

    /// PERIMETER
    _perimeter = 0;

    for (int i = 0; i < _points.length - 1; i++) {

      _perimeter += mp.SphericalUtil.computeDistanceBetween(
        mp.LatLng(
          _points[i].latitude,
          _points[i].longitude,
        ),

        mp.LatLng(
          _points[i + 1].latitude,
          _points[i + 1].longitude,
        ),
      );
    }
  }

  /// UNDO LAST POINT
  void undoLastPoint() {

    if (_points.isNotEmpty) {

      _points.removeLast();

      _updateMap();

      notifyListeners();
    }
  }

  /// CLEAR MAP
  void clearMap() {

    _points.clear();

    _markers.clear();

    _polylines.clear();

    _polygons.clear();

    _area = 0;

    _perimeter = 0;

    notifyListeners();
  }
}
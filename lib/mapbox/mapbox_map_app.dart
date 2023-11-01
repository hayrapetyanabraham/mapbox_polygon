import 'dart:async';
import 'dart:math';

import 'package:flexy_task/const.dart';
import 'package:flexy_task/selected_locations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxMapApp extends StatefulWidget {
  const MapboxMapApp({Key? key}) : super(key: key);

  @override
  State<MapboxMapApp> createState() => _MapboxMapAppState();
}

class _MapboxMapAppState extends State<MapboxMapApp> {
  List<Position> zone = [];
  List<LatLng> markerCoordinates = [];
  List<LatLng> locationsInArea = [];
  var options = <PolygonAnnotationOptions>[];
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointMarkerAnnotationManager;
  PointAnnotationManager? polygonMarkerAnnotationManager;
  PolygonAnnotationManager? polygonAnnotationManager;
  PointAnnotation? pointAnnotation;
  PointAnnotation? polygonAnnotation;

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    // Create a PointAnnotationManager for point markers
    mapboxMap.annotations.createPointAnnotationManager().then((value) async {
      pointMarkerAnnotationManager = value;
      createMarkers();
    });

    // Create a separate PointAnnotationManager for polygon markers
    mapboxMap.annotations.createPointAnnotationManager().then((value) {
      polygonMarkerAnnotationManager = value;
    });

    mapboxMap.location
        .updateSettings(LocationComponentSettings(enabled: true, pulsingEnabled: true));
    mapboxMap.annotations.createPolygonAnnotationManager().then((value) {
      polygonAnnotationManager = value;
      options.clear();
      options.add(PolygonAnnotationOptions(
          geometry: Polygon(coordinates: [zone]).toJson(),
          fillColor: Colors.white.value,
          fillOpacity: 0.9));
      polygonAnnotationManager?.createMulti(options);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        MapWidget(
          key: const ValueKey("mapWidget"),
          onMapCreated: _onMapCreated,
          onTapListener: (ScreenCoordinate coordinate) {
            _createMarkerPolygon(currentLat: coordinate.x, currentLong: coordinate.y);
            zone.add(Position(coordinate.y, coordinate.x));
            showArea();
          },
          resourceOptions: ResourceOptions(accessToken: Constants.mapKey),
          cameraOptions: CameraOptions(
              center: Point(
                  coordinates: Position(
                44.5093212,
                40.1830486,
              )).toJson(),
              zoom: 13.0),
        ),
        const Positioned(
          left: 0, // You can adjust left position if needed
          right: 0, // You can adjust right position if needed
          top: 0,
          child: Padding(
              padding: EdgeInsets.only(top: 56.0),
              child: Center(
                  child: Text(
                'Select minimum 2 points on map',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ))),
        ),
        Positioned(
          bottom: 0, // Set the bottom position
          left: 0, // You can adjust left position if needed
          right: 0, // You can adjust right position if needed
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  label: const Text('Reset'),
                  icon: const Icon(Icons.clear),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.red), // Change the background color here
                  ),
                  onPressed: () {
                    polygonAnnotationManager?.deleteAll();
                    zone.clear();
                    deleteAllPolygonMarkers();
                  },
                ),
                const SizedBox(
                  width: 40,
                ),
                ElevatedButton.icon(
                  label: const Text('Submit'),
                  icon: const Icon(Icons.done),
                  onPressed: zone.length < 3
                      ? null
                      : () {
                          findLocationsInAreaAndShowDialog(context);
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  void findLocationsInAreaAndShowDialog(
    BuildContext context,
  ) {
    locationsInArea.clear();
    List<LatLng> zoneMarkers =
        zone.map((element) => LatLng(element.lat.toDouble(), element.lng.toDouble())).toList();
    for (var element in markerCoordinates) {
      bool isArea = isPointInPolygon(LatLng(element.latitude, element.longitude), zoneMarkers);
      if (isArea == true) {
        locationsInArea.add(LatLng(element.latitude, element.longitude));
      }
    }
    showDialog(context, SelectedLocationsPage(coordinateMarkers: locationsInArea));
  }

  void showArea() {
    options.clear();
    options.add(PolygonAnnotationOptions(
        geometry: Polygon(coordinates: [zone]).toJson(),
        fillColor: Colors.white.value,
        fillOpacity: 0.7));
    polygonAnnotationManager?.deleteAll();
    polygonAnnotationManager?.createMulti(options);
    setState(() {});
  }

  List<LatLng> generateRandomCoordinates(LatLng center, double radiusKm, int count) {
    List<LatLng> coordinates = [];
    final random = Random();
    // Radius in degrees (approximately, as the Earth is not a perfect sphere)
    final radiusDegrees = radiusKm / 111.32;
    for (int i = 0; i < count; i++) {
      final double randomAngle = random.nextDouble() * (2 * pi);
      final double randomDistance = random.nextDouble() * radiusDegrees;
      final double latitude = center.latitude + (randomDistance * cos(randomAngle));
      final double longitude = center.longitude + (randomDistance * sin(randomAngle));
      coordinates.add(LatLng(latitude, longitude));
    }
    return coordinates;
  }

  Future<void> createMarkers() async {
    const center = LatLng(40.1830486, 44.5093212); // Center coordinate
    const radiusKm = 15.0; //
    if (markerCoordinates.isEmpty) {
      markerCoordinates = generateRandomCoordinates(center, radiusKm, 90);
    }
    for (LatLng coordinate in markerCoordinates) {
      await _createMarker(
        currentLat: coordinate.latitude,
        currentLong: coordinate.longitude,
      );
    }
  }

  Future<void> _createMarker({
    double currentLat = 40.1830486,
    double currentLong = 44.5093212,
  }) async {
    final ByteData bytes = await rootBundle.load('assets/images/marker.png');
    final Uint8List list = bytes.buffer.asUint8List();
    pointMarkerAnnotationManager
        ?.create(PointAnnotationOptions(
            geometry: Point(
                coordinates: Position(
              currentLong,
              currentLat,
            )).toJson(),
            iconSize: 2.5,
            iconOffset: [0.0, -10.0],
            symbolSortKey: 10,
            image: list))
        .then((value) => pointAnnotation = value);
  }

  Future<void> _createMarkerPolygon({
    double currentLat = 40.1830486,
    double currentLong = 44.5093212,
  }) async {
    final ByteData bytes = await rootBundle.load('assets/images/point.png');
    final Uint8List list = bytes.buffer.asUint8List();
    polygonMarkerAnnotationManager
        ?.create(PointAnnotationOptions(
            geometry: Point(
                coordinates: Position(
              currentLong,
              currentLat,
            )).toJson(),
            iconSize: 2.5,
            iconOffset: [0.0, -10.0],
            symbolSortKey: 10,
            image: list))
        .then((value) => polygonAnnotation = value);
  }

  Future<void> deleteAllPolygonMarkers() async {
    if (polygonMarkerAnnotationManager != null) {
      await polygonMarkerAnnotationManager!.deleteAll();
    }
  }

  static showDialog(BuildContext context, Widget widget) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => widget,
    );
  }

  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int i, j = polygon.length - 1;
    bool inside = false;

    for (i = 0; i < polygon.length; i++) {
      final double xi = polygon[i].longitude;
      final double yi = polygon[i].latitude;
      final double xj = polygon[j].longitude;
      final double yj = polygon[j].latitude;

      final bool intersect = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }
}

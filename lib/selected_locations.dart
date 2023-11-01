import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class SelectedLocationsPage extends StatefulWidget {
  final List<LatLng> coordinateMarkers;

  const SelectedLocationsPage({Key? key, required this.coordinateMarkers}) : super(key: key);

  @override
  State<SelectedLocationsPage> createState() => _SelectedLocationsPageState();
}

class _SelectedLocationsPageState extends State<SelectedLocationsPage> {
  double dialogHeight = Get.height * 0.9;
  Map<DismissDirection, double> dismissMap = {DismissDirection.down: 0.4};

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      direction: DismissDirection.down,
      dismissThresholds: dismissMap,
      onDismissed: (direction) {
        Navigator.of(context).pop();
      },
      key: UniqueKey(),
      child: SizedBox(
        height: Get.height * 0.9,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            // height: dialogHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 30, left: 30),
              child: widget.coordinateMarkers.isEmpty
                  ? Container()
                  : SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: SingleChildScrollView(
                          child: CupertinoListSection.insetGrouped(
                            margin: const EdgeInsets.all(0),
                            additionalDividerMargin: 5,
                            children: widget.coordinateMarkers.asMap().entries.map((entry) {
                              LatLng latLng = entry.value;
                              return CupertinoListTile(
                                title: Text(
                                  'latitude: ${latLng.latitude.toStringAsFixed(6)} longitude: ${latLng.longitude.toStringAsFixed(6)}',
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:centrex/core/constants/constants.dart';
import 'package:centrex/ui/components/app_constants.dart';
import 'package:provider/provider.dart';

class VisitNavigationMapView extends StatefulWidget {
  final Visit visit;
  const VisitNavigationMapView({super.key, required this.visit});

  @override
  State<VisitNavigationMapView> createState() => _VisitNavigationMapViewState();
}

class _VisitNavigationMapViewState extends State<VisitNavigationMapView> {
  late GoogleMapController _controller;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployesController>().clearMapData();
      _addVisitMarker();
    });
  }

  void _addVisitMarker() {
    final controller = context.read<EmployesController>();
    final visitPos = LatLng(
      double.parse(widget.visit.latitude),
      double.parse(widget.visit.longitude),
    );
    final Set<Marker> initialMarkers = {
      Marker(
        markerId: const MarkerId('destination'),
        position: visitPos,
        infoWindow: InfoWindow(
          title: widget.visit.placeName,
          snippet: widget.visit.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      )
    };
    controller.updateMarkers(initialMarkers);
  }

  Future<void> _startNavigation() async {
    final controller = context.read<EmployesController>();
    controller.setNavigating(true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);

      final Set<Marker> currentMarkers = Set.from(controller.markers);
      currentMarkers.removeWhere((m) => m.markerId == const MarkerId('user_pos'));
      currentMarkers.add(
        Marker(
          markerId: const MarkerId('user_pos'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      controller.updateMarkers(currentMarkers);

      PolylinePoints polylinePoints = PolylinePoints(
        apiKey: Constants.GOOGLE_MAPS_API_KEY,
      );
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          destination: PointLatLng(
            double.parse(widget.visit.latitude),
            double.parse(widget.visit.longitude),
          ),
          mode: TravelMode.driving,
        ),
      );

      final Set<Polyline> newPolylines = {};
      if (result.points.isNotEmpty) {
        List<LatLng> roadPoints = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        newPolylines.add(
          Polyline(
            polylineId: const PolylineId("nav_route"),
            points: roadPoints,
            color: AppColor.appColor1,
            width: 5,
            geodesic: true,
            jointType: JointType.round,
          ),
        );
      } else {
        newPolylines.add(
          Polyline(
            polylineId: const PolylineId("nav_route"),
            points: [
              _currentPosition!,
              LatLng(
                double.parse(widget.visit.latitude),
                double.parse(widget.visit.longitude),
              ),
            ],
            color: AppColor.appColor1.withValues(alpha: 0.5),
            width: 5,
          ),
        );
      }
      controller.updatePolylines(newPolylines);
      _fitBounds();
    } catch (e) {
      debugPrint("Navigation Error: $e");
    } finally {
      controller.setNavigating(false);
    }
  }

  void _fitBounds() {
    if (_currentPosition == null) return;

    LatLng dest = LatLng(
      double.parse(widget.visit.latitude),
      double.parse(widget.visit.longitude),
    );

    double minLat = _currentPosition!.latitude < dest.latitude
        ? _currentPosition!.latitude
        : dest.latitude;
    double maxLat = _currentPosition!.latitude > dest.latitude
        ? _currentPosition!.latitude
        : dest.latitude;
    double minLng = _currentPosition!.longitude < dest.longitude
        ? _currentPosition!.longitude
        : dest.longitude;
    double maxLng = _currentPosition!.longitude > dest.longitude
        ? _currentPosition!.longitude
        : dest.longitude;

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.visit.placeName),
      body: Stack(
        children: [
          Consumer<EmployesController>(
            builder: (context, controller, child) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    double.parse(widget.visit.latitude),
                    double.parse(widget.visit.longitude),
                  ),
                  zoom: 15,
                ),
                markers: controller.markers,
                polylines: controller.polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (c) => _controller = c,
              );
            },
          ),

          Positioned(
            bottom: 4.h,
            left: 5.w,
            right: 5.w,
            child: Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadow.soft,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: AppColor.appColor1.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: AppColor.appColor1,
                          size: 6.w,
                        ),
                      ),
                      4.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.visit.placeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 4.sp,
                                color: AppColor.appDarkColor,
                              ),
                            ),
                            Text(
                              widget.visit.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColor.grey,
                                fontSize: 2.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  3.height,
                  Consumer<EmployesController>(
                    builder: (context, controller, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.isNavigating ? null : _startNavigation,
                          icon: controller.isNavigating
                              ? SizedBox(
                                  width: 4.w,
                                  height: 4.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.near_me_rounded),
                          label: Text(
                            controller.isNavigating ? "CALCULATING..." : "START NAVIGATION",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.appDarkColor,
                            foregroundColor: AppColor.white,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

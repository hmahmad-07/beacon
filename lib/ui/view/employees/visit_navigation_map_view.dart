// ignore_for_file: deprecated_member_use

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

class VisitNavigationMapView extends StatefulWidget {
  final Visit visit;
  const VisitNavigationMapView({super.key, required this.visit});

  @override
  State<VisitNavigationMapView> createState() => _VisitNavigationMapViewState();
}

class _VisitNavigationMapViewState extends State<VisitNavigationMapView> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _addVisitMarker();
  }

  void _addVisitMarker() {
    final visitPos = LatLng(
      double.parse(widget.visit.latitude),
      double.parse(widget.visit.longitude),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: visitPos,
        infoWindow: InfoWindow(
          title: widget.visit.placeName,
          snippet: widget.visit.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _startNavigation() async {
    setState(() => _isNavigating = true);

    try {
      // 1. Get Current Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);

      // 2. Clear previous polylines & Add Current Location Marker
      _markers.removeWhere((m) => m.markerId == const MarkerId('user_pos'));
      _markers.add(
        Marker(
          markerId: const MarkerId('user_pos'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // 3. Fetch Real Road Polyline
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

      if (result.points.isNotEmpty) {
        List<LatLng> roadPoints = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        _polylines.clear();
        _polylines.add(
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
        // Fallback to straight line if API fails or key missing
        _polylines.clear();
        _polylines.add(
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

      // 4. Zoom to fit both points
      _fitBounds();
    } catch (e) {
      debugPrint("Navigation Error: $e");
    } finally {
      setState(() => _isNavigating = false);
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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                double.parse(widget.visit.latitude),
                double.parse(widget.visit.longitude),
              ),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _controller = c,
          ),

          // Bottom Navigation Card
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isNavigating ? null : _startNavigation,
                      icon: _isNavigating
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
                        _isNavigating ? "CALCULATING..." : "START NAVIGATION",
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

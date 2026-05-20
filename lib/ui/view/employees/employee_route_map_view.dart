import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:intl/intl.dart';

import '../../components/app_constants.dart';

class EmployeeRouteMapView extends StatefulWidget {
  final EmployesWorkingDetailModel detail;
  const EmployeeRouteMapView({super.key, required this.detail});

  @override
  State<EmployeeRouteMapView> createState() => _EmployeeRouteMapViewState();
}

class _EmployeeRouteMapViewState extends State<EmployeeRouteMapView> {
  late GoogleMapController _controller;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  final List<LatLng> _points = [];
  bool _isSheetVisible = false;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  String _formatTo12Hour(String timeString) {
    try {
      if (timeString.isEmpty) return "--:--";
      final DateTime time = DateFormat("HH:mm:ss").parse(timeString);
      return DateFormat("hh:mm a").format(time);
    } catch (e) {
      return timeString;
    }
  }

  void _prepareData() {
    setState(() {
      _points.clear();
      _markers.clear();

      // 1. Add Check-in safely
      if (widget.detail.checkin != null &&
          widget.detail.checkin!.latitude.isNotEmpty &&
          widget.detail.checkin!.longitude.isNotEmpty) {
        try {
          final checkinPos = LatLng(
            double.parse(widget.detail.checkin!.latitude.toString()),
            double.parse(widget.detail.checkin!.longitude.toString()),
          );
          if (checkinPos.latitude != 0.0) {
            _points.add(checkinPos);
            _markers.add(
              Marker(
                markerId: const MarkerId('checkin'),
                position: checkinPos,
                infoWindow: InfoWindow(
                  title: "Start Point (Check-in)",
                  snippet:
                      "Time: ${_formatTo12Hour(widget.detail.checkin!.time)}",
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Checkin parse error: $e");
        }
      }

      // 2. Add Visits safely
      for (var visit in widget.detail.visits) {
        try {
          final pos = LatLng(
            double.parse(visit.latitude.toString()),
            double.parse(visit.longitude.toString()),
          );
          if (pos.latitude != 0.0) {
            _points.add(pos);
            _markers.add(
              Marker(
                markerId: MarkerId('visit_${visit.id}'),
                position: pos,
                infoWindow: InfoWindow(
                  title: visit.placeName,
                  snippet: "Visit Time: ${visit.createdAt}",
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Visit parse error: $e");
        }
      }

      // 3. Add Check-out safely
      if (widget.detail.checkout != null &&
          widget.detail.checkout!['latitude'] != null &&
          widget.detail.checkout!['longitude'] != null) {
        try {
          final checkoutPos = LatLng(
            double.parse(widget.detail.checkout!['latitude'].toString()),
            double.parse(widget.detail.checkout!['longitude'].toString()),
          );
          if (checkoutPos.latitude != 0.0) {
            _points.add(checkoutPos);
            _markers.add(
              Marker(
                markerId: const MarkerId('checkout'),
                position: checkoutPos,
                infoWindow: InfoWindow(
                  title: "End Point (Check-out)",
                  snippet:
                      "Time: ${_formatTo12Hour(widget.detail.checkout!['time'])}",
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint("Checkout parse error: $e");
        }
      }

      // 4. Create Polyline
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _points,
          color: AppColor.appColor1,
          width: 5,
          geodesic: true,
          jointType: JointType.round,
        ),
      );

      // 5. Create Polygon
      if (_points.length > 2) {
        _polygons.add(
          Polygon(
            polygonId: const PolygonId('coverage'),
            points: _points,
            fillColor: AppColor.appColor1.withValues(alpha: 0.1),
            strokeColor: AppColor.appColor1.withValues(alpha: 0.3),
            strokeWidth: 2,
          ),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_points.isEmpty || !mounted) return;

    double? minLat, maxLat, minLng, maxLng;
    for (final p in _points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }

    _controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat!, minLng!),
          northeast: LatLng(maxLat!, maxLng!),
        ),
        100.0,
      ),
    );
  }

  void _toggleSheet() {
    setState(() {
      _isSheetVisible = !_isSheetVisible;
    });
    if (_isSheetVisible) {
      _sheetController.animateTo(
        0.3,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else {
      _sheetController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: const CustomAppBar(title: 'Intelligent Map'),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _points.isNotEmpty ? _points.first : const LatLng(0, 0),
              zoom: 12,
              tilt: 40,
            ),
            markers: _markers,
            polylines: _polylines,
            polygons: _polygons,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (_) {
              if (_isSheetVisible) _toggleSheet();
            },
          ),
          _buildMapControls(),
          _buildTripMonitor(),
          _buildTimelineToggleButton(),
          _buildDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 15.h,
      right: 4.w,
      child: Column(
        children: [
          FloatingActionButton.small(
            onPressed: _fitBounds,
            heroTag: "fit",
            backgroundColor: AppColor.white,
            foregroundColor: AppColor.appDarkColor,
            child: const Icon(Icons.zoom_out_map_rounded),
          ),
          1.height,
          FloatingActionButton.small(
            onPressed: () {
              if (_points.isNotEmpty) {
                _controller.animateCamera(
                  CameraUpdate.newLatLng(_points.first),
                );
              }
            },
            heroTag: "center",
            backgroundColor: AppColor.appDarkColor,
            child: const Icon(
              Icons.gps_fixed_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripMonitor() {
    bool isCheckinDone = widget.detail.checkin != null;
    bool isCheckoutDone = widget.detail.checkout != null;
    return Positioned(
      top: 2.h,
      left: 4.w,
      child: Container(
        padding: EdgeInsets.all(4.w),
        width: 45.w,
        decoration: BoxDecoration(
          color: AppColor.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadow.soft,
        ),
        child: Column(
          children: [
            _monitorRow(
              "In",
              isCheckinDone
                  ? _formatTo12Hour(widget.detail.checkin!.time)
                  : "Pending",
              isCheckinDone ? AppColor.green : AppColor.grey,
            ),
            1.height,
            _monitorRow(
              "Out",
              isCheckoutDone
                  ? _formatTo12Hour(widget.detail.checkout!['time'])
                  : "Pending",
              isCheckoutDone ? AppColor.red : AppColor.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _monitorRow(String label, String time, Color color) {
    return Row(
      children: [
        Container(
          width: 2.w,
          height: 2.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        2.width,
        Text(
          "$label:",
          style: TextStyle(
            fontSize: 2.5.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.grey,
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: TextStyle(
            fontSize: 2.8.sp,
            fontWeight: FontWeight.w900,
            color: AppColor.appDarkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineToggleButton() {
    return Positioned(
      bottom: 4.h,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _toggleSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.appDarkColor, AppColor.appColor1],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColor.appColor1.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline_rounded, color: Colors.white, size: 5.w),
                2.width,
                Text(
                  "Activity Timeline",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 3.5.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
            itemCount: widget.detail.visits.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.w,
                    vertical: 1.5.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Activity Intelligence",
                        style: TextStyle(
                          fontSize: 4.2.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleSheet,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColor.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final v = widget.detail.visits[index - 1];
              return _buildTimelineItem(
                v,
                index - 1,
                index - 1 == widget.detail.visits.length - 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(Visit v, int index, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppColor.appColor1.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColor.appColor1,
                  size: 5.w,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: AppColor.appLightColor),
                ),
            ],
          ),
          4.width,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 3.h),
              child: GestureDetector(
                onTap: () {
                  _controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        double.parse(v.latitude),
                        double.parse(v.longitude),
                      ),
                      16.5,
                    ),
                  );
                  _controller.showMarkerInfoWindow(MarkerId('visit_${v.id}'));
                  _toggleSheet();
                },
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppColor.scaffold.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.placeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 3.5.sp,
                          color: AppColor.appDarkColor,
                        ),
                      ),
                      0.5.height,
                      Text(
                        v.createdAt,
                        style: TextStyle(
                          fontSize: 2.8.sp,
                          color: AppColor.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

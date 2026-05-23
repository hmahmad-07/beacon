// ignore_for_file: deprecated_member_use

import 'package:centrex/core/controllers/employes_controller.dart';
import 'package:centrex/core/models/emp_working_detail_model.dart';
import 'package:centrex/core/resources/app_colors.dart';
import 'package:centrex/ui/components/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:centrex/core/extensions/sizer.dart';
import 'package:intl/intl.dart';
import 'package:centrex/core/utils/utils.dart';
import 'package:provider/provider.dart';
import '../../components/app_constants.dart';
import '../../../core/constants/constants.dart';

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
  final List<LatLng> _points = [];

  @override
  void initState() {
    super.initState();
    // Clear old map data when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployesController>().clearMapData();
      _initMapData();
    });
  }

  Future<void> _initMapData() async {
    _prepareStaticMarkers();
    await _fetchRoadRoutes();
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

  void _prepareStaticMarkers() {
    final controller = context.read<EmployesController>();
    final Set<Marker> localMarkers = {};
    final Set<Polyline> localPolylines = {};

    _points.clear();

    // Sort visits chronologically
    widget.detail.visits.sort(
      (a, b) => Utils.parseDateTime(
        a.createdAt,
      ).compareTo(Utils.parseDateTime(b.createdAt)),
    );

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
          localMarkers.add(
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

    for (var visit in widget.detail.visits) {
      try {
        final pos = LatLng(
          double.parse(visit.latitude.toString()),
          double.parse(visit.longitude.toString()),
        );
        if (pos.latitude != 0.0) {
          _points.add(pos);
          localMarkers.add(
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

    if (widget.detail.checkout != null &&
        widget.detail.checkout!.latitude.isNotEmpty &&
        widget.detail.checkout!.longitude.isNotEmpty) {
      try {
        final checkoutPos = LatLng(
          double.parse(widget.detail.checkout!.latitude),
          double.parse(widget.detail.checkout!.longitude),
        );
        if (checkoutPos.latitude != 0.0) {
          _points.add(checkoutPos);
          localMarkers.add(
            Marker(
              markerId: const MarkerId('checkout'),
              position: checkoutPos,
              infoWindow: InfoWindow(
                title: "End Point (Check-out)",
                snippet:
                    "Time: ${_formatTo12Hour(widget.detail.checkout!.time)}",
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

    localPolylines.add(
      Polyline(
        polylineId: const PolylineId('route_initial'),
        points: List.from(_points),
        color: AppColor.appColor1.withValues(alpha: 0.3),
        width: 3,
      ),
    );

    controller.updateMarkers(localMarkers);
    controller.updatePolylines(localPolylines);
  }

  Future<void> _fetchRoadRoutes() async {
    if (_points.length < 2) return;

    final controller = context.read<EmployesController>();
    controller.setLoadingRoutes(true);

    try {
      PolylinePoints polylinePoints = PolylinePoints(
        apiKey: Constants.GOOGLE_MAPS_API_KEY,
      );
      List<LatLng> roadJourneyPoints = [];

      for (int i = 0; i < _points.length - 1; i++) {
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          request: PolylineRequest(
            origin: PointLatLng(_points[i].latitude, _points[i].longitude),
            destination: PointLatLng(
              _points[i + 1].latitude,
              _points[i + 1].longitude,
            ),
            mode: TravelMode.driving,
          ),
        );

        if (result.points.isNotEmpty) {
          roadJourneyPoints.addAll(
            result.points.map((p) => LatLng(p.latitude, p.longitude)),
          );
        } else {
          roadJourneyPoints.add(_points[i]);
          roadJourneyPoints.add(_points[i + 1]);
        }
      }

      final Set<Polyline> newPolylines = {
        Polyline(
          polylineId: const PolylineId('road_journey'),
          points: roadJourneyPoints,
          color: AppColor.appColor1,
          width: 5,
          jointType: JointType.round,
        ),
      };

      final Set<Polygon> newPolygons = {};
      if (roadJourneyPoints.length > 2) {
        newPolygons.add(
          Polygon(
            polygonId: const PolygonId('coverage'),
            points: roadJourneyPoints,
            fillColor: AppColor.appColor1.withValues(alpha: 0.08),
            strokeColor: AppColor.appColor1.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        );
      }

      controller.updatePolylines(newPolylines);
      controller.updatePolygons(newPolygons);
    } catch (e) {
      debugPrint("Road Route Error: $e");
    } finally {
      controller.setLoadingRoutes(false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_points.isEmpty) return;

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
    final controller = context.read<EmployesController>();
    controller.toggleSheetVisible();
    if (controller.isSheetVisible) {
      _sheetController.animateTo(
        0.5,
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
      appBar: const CustomAppBar(title: 'Activity Route Intelligence'),
      body: Stack(
        children: [
          Consumer<EmployesController>(
            builder: (context, controller, child) {
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _points.isNotEmpty
                      ? _points.first
                      : const LatLng(0, 0),
                  zoom: 12,
                  tilt: 40,
                ),
                markers: controller.markers,
                polylines: controller.polylines,
                polygons: controller.polygons,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (_) {
                  if (controller.isSheetVisible) _toggleSheet();
                },
              );
            },
          ),

          Consumer<EmployesController>(
            builder: (context, controller, child) {
              if (controller.isLoadingRoutes) {
                return Positioned(
                  top: 10.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: AppShadow.soft,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 3.w,
                            height: 3.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          2.width,
                          Text(
                            "Synthesizing Road Routes...",
                            style: TextStyle(
                              fontSize: 2.5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColor.appDarkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          _buildMapControls(),
          _buildTripMonitor(),
          if (widget.detail.visits.isNotEmpty) _buildTimelineToggleButton(),
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
            onPressed: () {
              _fitBounds();
              _fetchRoadRoutes();
            },
            heroTag: "fit",
            backgroundColor: AppColor.white,
            foregroundColor: AppColor.appDarkColor,
            child: const Icon(Icons.refresh_rounded),
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
              "Start",
              isCheckinDone
                  ? _formatTo12Hour(widget.detail.checkin!.time)
                  : "Pending",
              isCheckinDone ? AppColor.green : AppColor.grey,
            ),
            1.height,
            _monitorRow(
              "End",
              isCheckoutDone
                  ? _formatTo12Hour(widget.detail.checkout!.time)
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
                  "Field Journey Timeline",
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
      maxChildSize: 0.5,
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
          child: Column(
            children: [
              // Fixed Header
              Padding(
                padding: EdgeInsets.fromLTRB(6.w, 1.5.h, 6.w, 0.5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Journey Intelligence",
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
              ),
              const Divider(height: 1),
              // Scrollable Content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  itemCount: widget.detail.visits.length,
                  itemBuilder: (context, index) {
                    final v = widget.detail.visits[index];
                    return _buildTimelineItem(
                      v,
                      index,
                      index == widget.detail.visits.length - 1,
                    );
                  },
                ),
              ),
            ],
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
                        "Reached at: ${v.createdAt}",
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

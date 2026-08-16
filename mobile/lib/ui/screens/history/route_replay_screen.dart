import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../models/ride.dart';

class RouteReplayScreen extends StatefulWidget {
  final String rideId;
  final Ride rideSummary;

  const RouteReplayScreen({
    super.key,
    required this.rideId,
    required this.rideSummary,
  });

  @override
  State<RouteReplayScreen> createState() => _RouteReplayScreenState();
}

class _RouteReplayScreenState extends State<RouteReplayScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _routePoints = [];
  bool _isLoading = true;

  // Replay State
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 2.0; // 1x, 2x, 5x
  Timer? _replayTimer;

  @override
  void initState() {
    super.initState();
    _fetchRouteData();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRouteData() async {
    try {
      final res = await ApiClient.get("/rides/${widget.rideId}/route");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final points = List<Map<String, dynamic>>.from(data["points"] ?? []);
        setState(() {
          _routePoints = points;
          _isLoading = false;
        });

        if (points.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(LatLng(points[0]["latitude"], points[0]["longitude"]), 15.0);
          });
        }
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _replayTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_currentIndex >= _routePoints.length - 1) {
        _currentIndex = 0;
      }
      setState(() => _isPlaying = true);
      _startPlayback();
    }
  }

  void _startPlayback() {
    _replayTimer?.cancel();
    final intervalMs = (400 / _playbackSpeed).round();

    _replayTimer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (_currentIndex < _routePoints.length - 1) {
        setState(() {
          _currentIndex++;
        });
        final pt = _routePoints[_currentIndex];
        _mapController.move(LatLng(pt["latitude"], pt["longitude"]), _mapController.camera.zoom);
      } else {
        _replayTimer?.cancel();
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPt = _routePoints.isNotEmpty ? _routePoints[_currentIndex] : null;
    final currentLatLng = currentPt != null
        ? LatLng(currentPt["latitude"], currentPt["longitude"])
        : const LatLng(12.9716, 77.5946);

    final polylineList = _routePoints.map((p) => LatLng(p["latitude"], p["longitude"])).toList();
    final progressPolyline = _routePoints.take(_currentIndex + 1).map((p) => LatLng(p["latitude"], p["longitude"])).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          "${widget.rideSummary.totalDistanceKm.toStringAsFixed(1)} km Route Replay",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : _routePoints.isEmpty
              ? const Center(child: Text("No GPS telemetry points recorded for this ride.", style: TextStyle(color: AppColors.textSecondary)))
              : Stack(
                  children: [
                    // Map View
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: currentLatLng,
                        initialZoom: 15.0,
                        backgroundColor: AppColors.background,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        // Full Dim Track
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylineList,
                              strokeWidth: 4.0,
                              color: AppColors.primaryCyan.withOpacity(0.3),
                            ),
                          ],
                        ),
                        // Replayed Track
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: progressPolyline,
                              strokeWidth: 6.0,
                              color: AppColors.primaryCyan,
                            ),
                          ],
                        ),
                        // Moving Bike Marker
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentLatLng,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryCyan,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryCyan.withOpacity(0.8),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.two_wheeler_rounded, size: 16, color: AppColors.background),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Floating Replay Controls
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.surfaceBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Instantaneous Speed & Elevation Telemetry
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text("SPEED: ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                    Text(
                                      "${currentPt?['speed_kmh']?.toStringAsFixed(0) ?? 0} km/h",
                                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryCyan),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Text("ALTITUDE: ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                    Text(
                                      "${currentPt?['altitude']?.toStringAsFixed(0) ?? 0} m",
                                      style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Progress Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryCyan,
                                inactiveTrackColor: Colors.white.withOpacity(0.1),
                                thumbColor: AppColors.primaryCyan,
                                overlayColor: AppColors.primaryCyanGlow,
                                trackHeight: 4.0,
                              ),
                              child: Slider(
                                value: _currentIndex.toDouble(),
                                min: 0,
                                max: (_routePoints.length - 1).toDouble(),
                                onChanged: (val) {
                                  setState(() {
                                    _currentIndex = val.round();
                                  });
                                  final pt = _routePoints[_currentIndex];
                                  _mapController.move(LatLng(pt["latitude"], pt["longitude"]), _mapController.camera.zoom);
                                },
                              ),
                            ),

                            // Controls Row (Play/Pause & 1x/2x/5x Speed)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Play / Pause
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryCyan,
                                    foregroundColor: AppColors.background,
                                  ),
                                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                                  onPressed: _togglePlayPause,
                                ),

                                // Speed Selectors
                                Row(
                                  children: [1.0, 2.0, 5.0].map((spd) {
                                    final isSelected = _playbackSpeed == spd;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          setState(() => _playbackSpeed = spd);
                                          if (_isPlaying) _startPlayback();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primaryCyan.withOpacity(0.2) : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primaryCyan : AppColors.surfaceBorder,
                                            ),
                                          ),
                                          child: Text(
                                            "${spd.toStringAsFixed(0)}x",
                                            style: TextStyle(
                                              fontFamily: 'JetBrains Mono',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
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

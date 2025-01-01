import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/emergency_footer.dart';
import '../widgets/location_button.dart';
import '../models/emergency_request.dart';
import '../models/ambulance_info.dart';
import '../models/hospital_info.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart'; // Import ApiService

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = true;
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  final Location _location = Location();
  List<LatLng>? _routePoints;
  AmbulanceInfo? _assignedAmbulance;
  HospitalInfo? _assignedHospital;
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription? _locationSubscription;
  Timer? _locationUpdateTimer; // Add _locationUpdateTimer

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _webSocketService.dispose();
    _locationUpdateTimer?.cancel(); // Cancel _locationUpdateTimer
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    }
  }

  void _handleEmergencyResponse(EmergencyResponse response) {
    if (response.routePolyline != null && response.assignedAmbulance != null) {
      setState(() {
        // Decode route geometry
        _routePoints = _decodeRouteGeometry(response.routePolyline!);
        _assignedAmbulance = response.assignedAmbulance;
        _assignedHospital = response.assignedHospital;
      });

      // Start WebSocket connection for ambulance updates
      if (response.assignedAmbulance?.id != null) {
        _startAmbulanceUpdates(response.assignedAmbulance!.id);
      }

      // Fit map bounds to show entire route
      if (_routePoints != null && _routePoints!.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(_routePoints!);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
        );
      }
    }
  }

  List<LatLng> _decodeRouteGeometry(String geometry) {
    // Simple polyline decoding
    List<LatLng> points = [];
    int index = 0;
    int len = geometry.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = geometry.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        b = geometry.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _startAmbulanceUpdates(int ambulanceId) {
    // Cancel existing subscription if any
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel(); // Cancel _locationUpdateTimer

    // Connect to WebSocket
    _webSocketService.connectToAmbulanceUpdates(ambulanceId);

    // Subscribe to WebSocket updates
    _locationSubscription = _webSocketService.ambulanceLocations?.listen(
      (ambulance) {
        if (mounted) {
          setState(() {
            _assignedAmbulance = ambulance;
          });
        }
      },
      onError: (error) {
        debugPrint('Error receiving ambulance updates: $error');
      },
    );

    // Start periodic HTTP updates as backup
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      
      final ambulance = await ApiService.getAmbulanceLocation(ambulanceId);
      if (ambulance != null && mounted) {
        setState(() {
          _assignedAmbulance = ambulance;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(33.55725, -7.61667),
                    initialZoom: _currentLocation != null ? 15 : 11.82,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                      additionalOptions: {
                        'accessToken': 'pk.eyJ1IjoieWFjaW5lbWFuc291ciIsImEiOiJjbTRzbTBuZmowMnAxMnBzZ3ozZWNyMTQ1In0.MuCDPa78D1cgrKqm3LDX2Q',
                        'id': 'mapbox/streets-v12',
                      },
                    ),
                    if (_routePoints != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints!,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        if (_assignedAmbulance != null)
                          Marker(
                            point: LatLng(_assignedAmbulance!.latitude, _assignedAmbulance!.longitude),
                            width: 80,
                            height: 80,
                            child: GestureDetector(
                              onTap: () => _showAmbulanceInfo(context),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          ),
                        if (_assignedHospital != null)
                          Marker(
                            point: LatLng(_assignedHospital!.latitude, _assignedHospital!.longitude),
                            width: 80,
                            height: 80,
                            child: GestureDetector(
                              onTap: () => _showHospitalInfo(context),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                LocationButton(
                  onPressed: () {
                    _getCurrentLocation().then((_) => _centerOnLocation());
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: EmergencyFooter(
                    onEmergencyResponse: _handleEmergencyResponse,
                  ),
                ),
              ],
            ),
    );
  }

  void _showAmbulanceInfo(BuildContext context) {
    if (_assignedAmbulance == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ambulance Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${_assignedAmbulance!.driverName}'),
            Text('Status: ${_assignedAmbulance!.available ? 'Available' : 'Busy'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHospitalInfo(BuildContext context) {
    if (_assignedHospital == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hospital Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_assignedHospital!.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

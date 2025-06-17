import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isRoutingLoading = false;

  // Route related variables
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _destinationPosition;
  String? _routeDistance;
  String? _routeDuration;

  // Replace with your Google Maps API key
  final String _apiKey = 'AIzaSyCzfgauT0ABJ0mevSehcpglz0YrXoozmP0';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        _showLocationServiceDialog();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        _showPermissionDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Set initial markers
      _setInitialMarkers();
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setInitialMarkers() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: 'Current Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
  }

  // Get coordinates from place name using Geocoding API
  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }

  // Get route using Google Directions API
  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    setState(() => _isRoutingLoading = true);

    try {
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}&'
              'destination=${destination.latitude},${destination.longitude}&'
              'key=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Get route info
          _routeDistance = leg['distance']['text'];
          _routeDuration = leg['duration']['text'];

          // Decode polyline
          final points = _decodePolyline(route['overview_polyline']['points']);

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route'),
                points: points,
                color: Colors.blue,
                width: 5,
                patterns: [],
              ),
            );

            // Add destination marker
            _markers.removeWhere(
                (marker) => marker.markerId.value == 'destination');
            _markers.add(
              Marker(
                markerId: MarkerId('destination'),
                position: destination,
                infoWindow: InfoWindow(
                  title: 'Destination',
                  snippet: _destinationController.text,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            );
          });

          // Fit map to show entire route
          _fitMapToRoute(points);

          // Show route info
          _showRouteInfo();
        }
      }
    } catch (e) {
      print('Error getting route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRoutingLoading = false);
    }
  }

// Decode Google polyline algorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (_mapController != null && points.isNotEmpty) {
      double minLat =
          points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      double maxLat =
          points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      double minLng =
          points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      double maxLng =
          points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    }
  }

  void _showRouteInfo() {
    if (_routeDistance != null && _routeDuration != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route: $_routeDistance, $_routeDuration'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use maps.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
              'This app needs location permission to show your current position on the map.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  void _startTrip() async {
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both source and destination'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current location not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get destination coordinates
    LatLng? destinationCoords =
        await _getCoordinatesFromAddress(_destinationController.text);

    if (destinationCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find destination address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _destinationPosition = destinationCoords;

    // Get route
    LatLng origin =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    await _getRoute(origin, destinationCoords);
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _markers.removeWhere((marker) => marker.markerId.value == 'destination');
      _routeDistance = null;
      _routeDuration = null;
    });
    _setInitialMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Animate camera to current location when map is ready
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _goToCurrentLocation() async {
    if (_mapController != null && _currentPosition != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Driver Monitor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_polylines.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearRoute,
              tooltip: 'Clear Route',
            ),
        ],
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Source TextField
                TextField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    hintText: 'Enter source location',
                    prefixIcon: Icon(Icons.my_location, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.gps_fixed, color: Colors.blue[700]),
                      onPressed: () async {
                        if (_currentPosition != null) {
                          // In a real app, you'd use reverse geocoding to get address
                          _sourceController.text = 'Current Location';
                        }
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 12),

                // Destination TextField
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter destination',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),

                // Start Trip Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRoutingLoading ? null : _startTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.orange.withOpacity(0.6),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 3,
                    ),
                    child: _isRoutingLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Finding Route...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Get Directions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Route Info Card
          if (_routeDistance != null && _routeDuration != null)
            Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Distance: $_routeDistance • Duration: $_routeDuration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Map Section
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.blue[700]),
                            SizedBox(height: 16),
                            Text(
                              'Loading your location...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _currentPosition == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Unable to get your location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please check location permissions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _getCurrentLocation,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  zoom: 15.0,
                                ),
                                onMapCreated: _onMapCreated,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: true,
                                compassEnabled: true,
                                mapToolbarEnabled: false,
                                markers: _markers,
                                polylines: _polylines,
                                onTap: (LatLng position) {
                                  print(
                                      'Map tapped at: ${position.latitude}, ${position.longitude}');
                                },
                              ),

                              // Custom Location Button
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: Column(
                                  children: [
                                    FloatingActionButton(
                                      mini: true,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.blue[700],
                                      onPressed: _goToCurrentLocation,
                                      child: Icon(Icons.my_location),
                                      heroTag: "location_btn",
                                    ),
                                  ],
                                ),
                              ),

                              // Location Info Card
                              if (_currentPosition != null)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  right: 10,
                                  child: Card(
                                    color: Colors.white.withOpacity(0.9),
                                    child: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.location_on,
                                              color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                              'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}

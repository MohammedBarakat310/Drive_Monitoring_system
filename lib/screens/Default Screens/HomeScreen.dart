import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

// Navigation Step Model
class NavigationStep {
  final String instruction;
  final double distance;
  final String duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
  });
}

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
  bool _isTripActive = false;

  // Text-to-Speech
  FlutterTts flutterTts = FlutterTts();

  // Route related
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _destinationPosition;
  String? _routeDistance;
  String? _routeDuration;
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;

  // Mode
  String _selectedMode = 'driving'; // driving, walking, transit

  // Tracking
  StreamSubscription<Position>? _positionStream;
  Timer? _navigationTimer;
  double _remainingDistance = 0;
  String _remainingTime = '';
  String _currentInstruction = '';
  double _distanceToNextTurn = 0;

  // Your Google API key
  final String _apiKey = 'AIzaSyCzfgauT0ABJ0mevSehcpglz0YrXoozmP0';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        _showLocationServiceDialog();
        return;
      }
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      _setInitialMarkers();
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setInitialMarkers() {
    if (_currentPosition != null) {
      _markers.add(Marker(
        markerId: MarkerId('current_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ));
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          return LatLng(loc['lat'], loc['lng']);
        }
      }
    } catch (e) {
      print('Geocode error: $e');
    }
    return null;
  }

  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    setState(() => _isRoutingLoading = true);
    try {
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}&'
              'destination=${destination.latitude},${destination.longitude}&'
              'mode=$_selectedMode&key=$_apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          _routeDistance = leg['distance']['text'];
          _routeDuration = leg['duration']['text'];
          _remainingDistance = leg['distance']['value'].toDouble();
          _remainingTime = leg['duration']['text'];
          _navigationSteps = _parseNavigationSteps(leg['steps']);
          _currentStepIndex = 0;
          if (_navigationSteps.isNotEmpty) {
            _currentInstruction = _navigationSteps[0].instruction;
            _distanceToNextTurn = _navigationSteps[0].distance;
          }
          final points = _decodePolyline(route['overview_polyline']['points']);
          setState(() {
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: PolylineId('route'),
              points: points,
              color: _selectedMode == 'walking'
                  ? Colors.blue
                  : _selectedMode == 'transit'
                      ? Colors.green
                      : Colors.purple,
              width: 5,
            ));
            _markers.removeWhere((m) => m.markerId.value == 'destination');
            _markers.add(Marker(
              markerId: MarkerId('destination'),
              position: destination,
              infoWindow: InfoWindow(
                title: 'Destination',
                snippet: _destinationController.text,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ));
          });
          _fitMapToRoute(points);
          _showRouteInfo();
        }
      }
    } catch (e) {
      print('Route error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error getting route: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isRoutingLoading = false);
    }
  }

  List<NavigationStep> _parseNavigationSteps(List<dynamic> steps) {
    return steps.map((s) {
      return NavigationStep(
        instruction: _cleanHtmlInstruction(s['html_instructions']),
        distance: s['distance']['value'].toDouble(),
        duration: s['duration']['text'],
        startLocation:
            LatLng(s['start_location']['lat'], s['start_location']['lng']),
        endLocation: LatLng(s['end_location']['lat'], s['end_location']['lng']),
        maneuver: s['maneuver'] ?? '',
      );
    }).toList();
  }

  String _cleanHtmlInstruction(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
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
    if (_mapController == null || points.isEmpty) return;
    double minLat =
        points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      100,
    ));
  }

  void _showRouteInfo() {
    if (_routeDistance != null && _routeDuration != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Route: $_routeDistance • $_routeDuration (${_selectedMode.toUpperCase()})'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ));
    }
  }

  void _startTrip() async {
    if (_sourceController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter both source and destination'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Current location not available'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    LatLng? dest =
        await _getCoordinatesFromAddress(_destinationController.text);
    if (dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not find destination'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    _destinationPosition = dest;
    LatLng origin =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    await _getRoute(origin, dest);
  }

  void _startNavigation() {
    if (_navigationSteps.isEmpty) return;
    setState(() {
      _isTripActive = true;
      _currentStepIndex = 0;
    });
    _positionStream = Geolocator.getPositionStream(
      locationSettings:
          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen(_onLocationUpdate);
    _speak(_navigationSteps[0].instruction);
    _navigationTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _updateNavigationStatus();
    });
  }

  void _onLocationUpdate(Position position) {
    if (!_isTripActive) return;
    setState(() => _currentPosition = position);

    // Update marker
    _markers.removeWhere((m) => m.markerId.value == 'current_location');
    _markers.add(Marker(
      markerId: MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    // **Follow the user with the camera:**
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 17.0,
        bearing: position.heading,
        tilt: 60,
      ),
    ));

    // Next-turn logic…
    if (_currentStepIndex < _navigationSteps.length) {
      double distToNext = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _navigationSteps[_currentStepIndex].endLocation.latitude,
        _navigationSteps[_currentStepIndex].endLocation.longitude,
      );
      setState(() => _distanceToNextTurn = distToNext);

      if (distToNext < 50 && _currentStepIndex < _navigationSteps.length - 1) {
        _currentStepIndex++;
        setState(() => _currentInstruction =
            _navigationSteps[_currentStepIndex].instruction);
        _speak(_currentInstruction);
      }

      // Arrival check
      if (_destinationPosition != null) {
        double distToDest = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _destinationPosition!.latitude,
          _destinationPosition!.longitude,
        );
        if (distToDest < 30) _arriveAtDestination();
      }
    }
  }

  void _updateNavigationStatus() {
    if (!_isTripActive ||
        _currentPosition == null ||
        _destinationPosition == null) return;
    double rem = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );
    setState(() {
      _remainingDistance = rem;
      _remainingTime = _estimateRemainingTime(rem);
    });
  }

  String _estimateRemainingTime(double distMeters) {
    double speed = _selectedMode == 'walking' ? 5.0 : 50.0;
    int mins = ((distMeters / 1000) / speed * 60).round();
    return '$mins min';
  }

  void _arriveAtDestination() {
    _speak('You have arrived');
    _stopNavigation();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('🎉 Arrived!'),
        content: Text('You have reached your destination.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))
        ],
      ),
    );
  }

  void _stopNavigation() {
    setState(() => _isTripActive = false);
    _positionStream?.cancel();
    _navigationTimer?.cancel();
    _clearRoute();
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _markers.removeWhere((m) => m.markerId.value == 'destination');
      _routeDistance = null;
      _routeDuration = null;
      _navigationSteps.clear();
      _currentInstruction = '';
      _distanceToNextTurn = 0;
      _remainingDistance = 0;
      _remainingTime = '';
    });
    _setInitialMarkers();
  }

  // Launch native Google Maps with your route
  Future<void> _openInGoogleMaps() async {
    if (_currentPosition == null || _destinationPosition == null) return;
    final origin =
        '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final dest =
        '${_destinationPosition!.latitude},${_destinationPosition!.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$dest'
      '&travelmode=$_selectedMode',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enable Location'),
        content: Text('Please turn on location services.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Permission Needed'),
        content: Text('App needs location permission.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
              onPressed: Geolocator.openAppSettings, child: Text('Settings')),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController ctrl) {
    _mapController = ctrl;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _goToCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 17,
          ),
        ),
      );
    }
  }

  Widget _buildModeButton(String mode, IconData icon, String label) {
    bool sel = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = mode),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? Colors.blue[700]! : Colors.white),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Icon(icon,
                    size: 16, color: sel ? Colors.blue[700] : Colors.white),
              ),
              SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: sel ? Colors.blue[700] : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateArrivalTime() {
    if (_routeDuration == null) return '';
    final m = RegExp(r'(\d+)').firstMatch(_routeDuration!);
    if (m == null) return '';
    final mins = int.parse(m.group(1)!);
    final eta = DateTime.now().add(Duration(minutes: mins));
    final h = eta.hour % 12 == 0 ? 12 : eta.hour % 12;
    final mm = eta.minute.toString().padLeft(2, '0');
    final ap = eta.hour >= 12 ? 'PM' : 'AM';
    return '$h:$mm $ap';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Monitor',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        actions: [
          if (_polylines.isNotEmpty && !_isTripActive)
            IconButton(icon: Icon(Icons.clear), onPressed: _clearRoute),
          if (_isTripActive)
            IconButton(icon: Icon(Icons.stop), onPressed: _stopNavigation),
        ],
      ),
      body: Column(
        children: [
          // Input + mode selectors (unchanged)...
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Mode row
                Row(
                  children: [
                    Text('Transportation:',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          _buildModeButton(
                              'driving', Icons.directions_car, 'Car'),
                          SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Source
                TextField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    hintText: 'Enter source location',
                    prefixIcon: Icon(Icons.my_location, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.gps_fixed, color: Colors.white),
                      onPressed: () {
                        if (_currentPosition != null) {
                          _sourceController.text = 'Current Location';
                        }
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 12),
                // Destination
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter destination',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isRoutingLoading ? null : _startTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: StadiumBorder(),
                        ),
                        child: _isRoutingLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Finding Route...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions),
                                  SizedBox(width: 8),
                                  Text('Get Route')
                                ],
                              ),
                      ),
                    ),
                    if (_navigationSteps.isNotEmpty && !_isTripActive) ...[
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _startNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: StadiumBorder(),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 4),
                          Text('Start')
                        ]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Active navigation card (unchanged)...

          // Map + overlays
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(color: Colors.blue[700]))
                    : _currentPosition == null
                        ? Center(
                            child: Text('Unable to get location',
                                style: TextStyle(fontSize: 18)))
                        : Stack(children: [
                            // Base map
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                  target: LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  zoom: 15),
                              onMapCreated: _onMapCreated,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              markers: _markers,
                              polylines: _polylines,
                            ),

                            // Go-to button
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[700],
                                onPressed: _goToCurrentLocation,
                                child: Icon(Icons.my_location),
                              ),
                            ),

                            // Top banner
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.green[800],
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_upward,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Expanded(
                                          child: Text('Ramses',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      IconButton(
                                        icon: Icon(Icons.mic,
                                            color: Colors.white),
                                        onPressed: () {},
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Next turn pill
                            Positioned(
                              top: 60,
                              left: 12,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.green[800],
                                    borderRadius: BorderRadius.circular(6)),
                                child: Row(children: [
                                  Text('Then',
                                      style: TextStyle(color: Colors.white)),
                                  SizedBox(width: 4),
                                  Icon(Icons.turn_right,
                                      size: 16, color: Colors.white),
                                ]),
                              ),
                            ),

                            // Bottom status + Open-in-maps
                            if (_routeDuration != null &&
                                _routeDistance != null)
                              Positioned(
                                bottom: 24,
                                left: 16,
                                right: 16,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8)
                                      ]),
                                  child: Row(children: [
                                    Text(_routeDuration!,
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    Text(' • ',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.grey[600])),
                                    Text(_routeDistance!,
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700])),
                                    SizedBox(width: 8),
                                    Text(_calculateArrivalTime(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700])),
                                    Spacer(),
                                    Flexible(
                                      child: IconButton(
                                        icon: Icon(Icons.map,
                                            color: Colors.grey[800]),
                                        onPressed: _openInGoogleMaps,
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                          ]),
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
    _positionStream?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }
}

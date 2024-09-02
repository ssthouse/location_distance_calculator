import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const defaultZoom = 10;
const defaultPadding = 50;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Distance Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LocationPage(),
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  Position? _currentPosition;
  String _selectedCity = '';
  double _distance = 0;
  final MapController _mapController = MapController();

  final Map<String, LatLng> cities = {
    'Chicago': LatLng(41.8781, -87.6298),
    'New York': LatLng(40.7128, -74.0060),
    'Paris': LatLng(48.8566, 2.3522),
    'Singapore': LatLng(1.3521, 103.8198),
  };

  @override
  void initState() {
    super.initState();
    _startLocationService();
  }

  Future<void> _startLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: defaultZoom,
      ),
    ).listen((Position position) {
      // Check if this is the first time we're getting the position
      var isFirstPosition = _currentPosition == null;
      setState(() {
        _currentPosition = position;
        if (isFirstPosition) {
          _focusMapOnUser();
        }
      });
      _calculateDistance();
    });
  }

  void _focusMapOnUser() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        10, // Zoom level
      );
    }
  }

  Future<void> _calculateDistance() async {
    if (_currentPosition == null || _selectedCity.isEmpty) return;

    LatLng destination = cities[_selectedCity]!;
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destination.latitude,
      destination.longitude,
    );

    setState(() {
      _distance = distanceInMeters / 1000; // Convert to kilometers
    });
  }

  void _focusMap() {
    if (_currentPosition == null || _selectedCity.isEmpty) return;

    LatLng userLocation =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    LatLng cityLocation = cities[_selectedCity]!;

    // Calculate the bounds that include both the user's location and the selected city
    final bounds = LatLngBounds.fromPoints([userLocation, cityLocation]);

    // Fit the map to the calculated bounds with some padding
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(defaultPadding.toDouble()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Distance Calculator'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : LatLng(0, 0),
                initialZoom: defaultZoom.toDouble(),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_currentPosition != null && _selectedCity.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          cities[_selectedCity]!,
                        ],
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on,
                            color: Colors.blueAccent, size: 40),
                      ),
                    if (_selectedCity.isNotEmpty)
                      Marker(
                        point: cities[_selectedCity]!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_city,
                            color: Colors.blueAccent, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _selectedCity.isNotEmpty ? _selectedCity : null,
                  hint: const Text('Select a city'),
                  items: cities.keys.map((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue!;
                    });
                    _calculateDistance();
                    _focusMap(); // Add this line to focus the map when a city is selected
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Current Location:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _currentPosition != null
                      ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Distance: ${_distance.toStringAsFixed(2)} km',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

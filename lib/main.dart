import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  final Map<String, LatLng> cities = {
    'Chicago': LatLng(41.8781, -87.6298),
    'New York': LatLng(40.7128, -74.0060),
    'Paris': LatLng(48.8566, 2.3522),
    'Singapore': LatLng(1.3521, 103.8198),
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _calculateDistance() async {
    if (_currentPosition == null || _selectedCity.isEmpty) return;

    LatLng destination = cities[_selectedCity]!;
    double distanceInMeters = await Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      destination.latitude,
      destination.longitude,
    );

    setState(() {
      _distance = distanceInMeters / 1000; // Convert to kilometers
    });
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
              options: MapOptions(
                center: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : LatLng(0, 0),
                zoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
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
                            color: Colors.red, size: 40),
                      ),
                    if (_selectedCity.isNotEmpty)
                      Marker(
                        point: cities[_selectedCity]!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_city,
                            color: Colors.blue, size: 40),
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

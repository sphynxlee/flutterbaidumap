import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // beijing coordinates (GCJ-02 coordinate system, suitable for AMap)
  final LatLng beijingCenter = const LatLng(39.9087, 116.3976);
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter 高德地图'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: beijingCenter,
              zoom: _currentZoom,
              maxZoom: 18,
              minZoom: 3,
              onMapReady: () {
                _mapController.move(beijingCenter, _currentZoom);
              },
            ),
            children: [
              // AMap tile layer - using vector map style
              TileLayer(
                urlTemplate: 'https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7',
                subdomains: const ['1', '2', '3', '4'],
                maxZoom: 18,
                minZoom: 3,
                // Add HTTP headers to handle referer restrictions
                additionalOptions: const {
                  'referrerPolicy': 'no-referrer-when-downgrade',
                },
              ),
              // marker point
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: beijingCenter,
                    builder: (ctx) => const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // zoom control buttons
          Positioned(
            right: 16.0,
            bottom: 16.0,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
                      _mapController.move(_mapController.center, _currentZoom);
                    });
                  },
                ),
                const SizedBox(height: 8.0),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  child: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
                      _mapController.move(_mapController.center, _currentZoom);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
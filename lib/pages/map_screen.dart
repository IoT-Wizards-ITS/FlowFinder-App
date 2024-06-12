import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flowfinder/utils/api.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late LatLng myPoint;
  bool isLoading = false;

  @override
  void initState() {
    myPoint = defaultPoint;
    super.initState();
    fetchAvoidStreets();
  }

  final defaultPoint = const LatLng(-7.2816569, 112.7951051);

  List listOfPoints = [];
  List<LatLng> regularRoutePoints = [];
  List<LatLng> floodRoutePoints = [];
  List<Marker> markers = [];
  List<LatLng> avoidRoutePoints = [];
  List<String> avoidStreetNames = [];

  double regularRouteDistance = 0;
  double floodRouteDistance = 0;
  String regularRouteDuration = '';
  String floodRouteDuration = '';

  Future<void> fetchAvoidStreets() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await fetchData(
        'http://103.127.137.208/api/avoid_streets'
      );

      if (response['avoid_streets'] != null) {
        List<dynamic> avoidStreets = response['avoid_streets'];
        setState(() {
          avoidRoutePoints = [];
          avoidStreetNames = [];
          for (var street in avoidStreets) {
            List<dynamic> coords = street['coords'];
            String streetName = street['name'];

            avoidRoutePoints.addAll(
              coords.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList(),
            );

            avoidStreetNames.add(streetName);
          }
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      AlertDialog(
        title: const Text("Error"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      );
    }
  }

  Future<void> getRoutes(LatLng coordOrigin, LatLng coordDestination) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await fetchData(
        'http://103.127.137.208/api/route?lat1=${coordOrigin.latitude}&long1=${coordOrigin.longitude}&lat2=${coordDestination.latitude}&long2=${coordDestination.longitude}'
      );

      if (response['regular_route'] != null) {
        final regularRoute = response['regular_route']['features'][0]['geometry']['coordinates'];
        final regularRouteDistance = response['regular_route']['features'][0]['properties']['summary']['distance'];
        final regularRouteDuration = response['regular_route']['features'][0]['properties']['summary']['duration'];

        setState(() {
          regularRoutePoints = regularRoute.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
          this.regularRouteDistance = regularRouteDistance;
          this.regularRouteDuration = regularRouteDuration.toString();
        });
      }

      if (response['flood_route'] != null) {
        final floodRoute = response['flood_route']['features'][0]['geometry']['coordinates'];
        final floodRouteDistance = response['flood_route']['features'][0]['properties']['summary']['distance'];
        final floodRouteDuration = response['flood_route']['features'][0]['properties']['summary']['duration'];

        setState(() {
          floodRoutePoints = floodRoute.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
          this.floodRouteDistance = floodRouteDistance;
          this.floodRouteDuration = floodRouteDuration.toString();
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      AlertDialog(
        title: const Text("Error"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      );
    }
  }

  final MapController mapController = MapController();

  void _handleTap(LatLng latLng) {
    setState(() {
      if (markers.length < 2) {
        markers.add(
          Marker(
            point: latLng,
            width: 80,
            height: 80,
            builder: (context) => Draggable(
              feedback: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.location_on),
                color: Colors.black,
                iconSize: 45,
              ),
              onDragEnd: (details) {
                setState(() {
                  // print("Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}");
                });
              },
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.location_on),
                color: Colors.black,
                iconSize: 45,
              ),
            ),
          ),
        );
      }

      if (markers.length == 1) {
        double zoomLevel = 16.5;
        mapController.move(latLng, zoomLevel);
      }

      if (markers.length == 2) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            isLoading = true;
          });
        });

        getRoutes(markers[0].point, markers[1].point);

        LatLngBounds bounds = LatLngBounds.fromPoints(markers.map((marker) => marker.point).toList());
        mapController.fitBounds(bounds);
      }
    });
  }

  void _showRouteInfo(String routeType, double distance, String duration) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$routeType Route Info"),
          content: Text("Distance: ${distance.toStringAsFixed(2)} meters\nDuration: ${duration}s"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolyline({required List<LatLng> points, required Color color, required double strokeWidth, required String routeType, required double distance, required String duration}) {
    return TappablePolylineLayer(
      polylineCulling: false,
      polylines: [
        TaggedPolyline(
          points: points,
          color: color,
          strokeWidth: strokeWidth,
          tag: routeType,
        )
      ],
      onTap: (p0, tapPosition) => _showRouteInfo(routeType, distance, duration)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              zoom: 16,
              center: myPoint,
              onTap: (tapPosition, latLng) => _handleTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              ),
              MarkerLayer(
                markers: markers,
              ),
              if (avoidRoutePoints.isNotEmpty)
                _buildPolyline(
                  points: avoidRoutePoints,
                  color: Colors.red,
                  strokeWidth: 10,
                  routeType: 'Avoided',
                  distance: 0,
                  duration: '',
                ),
              _buildPolyline(
                points: regularRoutePoints,
                color: Colors.black,
                strokeWidth: 5,
                routeType: 'Regular',
                distance: regularRouteDistance,
                duration: regularRouteDuration,
              ),
              if (floodRoutePoints.isNotEmpty)
                _buildPolyline(
                  points: floodRoutePoints,
                  color: Colors.blue,
                  strokeWidth: 5,
                  routeType: 'Flood',
                  distance: floodRouteDistance,
                  duration: floodRouteDuration,
                ),
              
            ],
          ),
          Visibility(
            visible: isLoading,
            child: Container(
              color: const Color.fromARGB(1, 66, 72, 116).withOpacity(0.7),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20.0,
            left: MediaQuery.of(context).size.width / 2 - 110,
            child: Align(
              child: TextButton(
                onPressed: () {
                  if (markers.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Alert"),
                          content: const Text("Please add two markers"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    setState(() {
                      markers = [];
                      regularRoutePoints = [];
                      floodRoutePoints = [];
                    });
                  }
                },
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 66, 72, 116).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      markers.isEmpty ? "No markers" : "Clear markers",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 66, 72, 116),
            onPressed: () {
              mapController.move(mapController.center, mapController.zoom + 0.5);
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 66, 72, 116),
            onPressed: () {
              mapController.move(mapController.center, mapController.zoom - 0.5);
            },
            child: const Icon(
              Icons.remove,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

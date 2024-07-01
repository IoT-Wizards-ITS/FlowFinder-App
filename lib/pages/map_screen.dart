import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flowfinder/utils/api.dart';
import 'package:flowfinder/pages/history_screen.dart';

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

  List<LatLng> regularRoutePoints = [];
  List<LatLng> floodRoutePoints = [];
  List<Marker> markers = [];
  List<Map<String, dynamic>> avoidRoutePoints = [];
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
      final response = await fetchData('http://103.127.137.208/api/avoid_streets');

      if (response['avoid_streets'] != null) {
        List<dynamic> avoidStreets = response['avoid_streets'];
        List<Map<String, dynamic>> tempRoutePoints = [];
        List<String> tempStreetNames = [];

        for (var street in avoidStreets) {
          List<dynamic> coords = street['coords'];
          String streetName = street['name'];
          int level = street['level'];

          List<LatLng> streetPoints = coords.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
          tempRoutePoints.add({'points': streetPoints, 'level': level});
          tempStreetNames.add(streetName);
        }

        setState(() {
          avoidRoutePoints = tempRoutePoints;
          avoidStreetNames = tempStreetNames;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
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
        },
      );
    }
  }

  Future<void> getRoutes(LatLng coordOrigin, LatLng coordDestination) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await fetchData(
          'http://103.127.137.208/api/route?lat1=${coordOrigin.latitude}&long1=${coordOrigin.longitude}&lat2=${coordDestination.latitude}&long2=${coordDestination.longitude}');

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

  void _refreshState() {
    setState(() {
      markers.clear();
      regularRoutePoints.clear();
      floodRoutePoints.clear();
      avoidRoutePoints.clear();
      avoidStreetNames.clear();
    });
    fetchAvoidStreets();
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
    double distanceInKm = distance / 1000;
    double durationInSeconds = double.parse(duration);
    String formattedDuration;

    if (durationInSeconds >= 3600) {
      int hours = (durationInSeconds / 3600).floor();
      int minutes = ((durationInSeconds % 3600) / 60).floor();
      formattedDuration = '$hours h $minutes m';
    } else if (durationInSeconds >= 60) {
      int minutes = (durationInSeconds / 60).floor();
      int seconds = (durationInSeconds % 60).floor();
      formattedDuration = '$minutes m $seconds s';
    } else {
      formattedDuration = '${durationInSeconds.toStringAsFixed(0)} s';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$routeType Route Info"),
          content: Text("Distance: ${distanceInKm.toStringAsFixed(2)} km\nDuration: $formattedDuration"),
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

  void _showFloodInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Flood Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: avoidStreetNames
                .map(
                  (name) => Row(
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )
                .toList(),
          ),
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
                PolylineLayer(
                  polylines: avoidRoutePoints.map((route) {
                    Color color;
                    switch (route['level']) {
                      case 1:
                        color = Colors.yellow;
                        break;
                      case 2:
                        color = Colors.orange;
                        break;
                      case 3:
                        color = Colors.red;
                        break;
                      default:
                        color = Colors.black;
                    }
                    return Polyline(points: route['points'], color: color, strokeWidth: 10);
                  }).toList(),
                ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: regularRoutePoints,
                    color: Colors.black,
                    strokeWidth: 5,
                  ),
                  if (floodRoutePoints.isNotEmpty)
                    Polyline(
                      points: floodRoutePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                ],
              ),
            ],
          ),
          if (isLoading)
            Center(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const CircularProgressIndicator(),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10.0,
            left: 0.0,
            right: 0.0,
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    markers.clear();
                    regularRoutePoints = [];
                    floodRoutePoints = [];
                    avoidRoutePoints = [];
                    avoidStreetNames = [];
                  });
                },
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 66, 72, 116),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
          Positioned(
            top: MediaQuery.of(context).padding.bottom + 790.0,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Align(
              child: ElevatedButton(
                onPressed: _refreshState,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 66, 72, 116),
                ),
                child: const Text(
                  "Refresh",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 66, 72, 116),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            child: const Icon(Icons.history, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 66, 72, 116),
            onPressed: () {
              if (floodRoutePoints.isNotEmpty) {
                _showRouteInfo('Regular', regularRouteDistance, regularRouteDuration);
                _showRouteInfo('Flood', floodRouteDistance, floodRouteDuration);
              } else if (regularRoutePoints.isNotEmpty) {
                _showRouteInfo('Regular', regularRouteDistance, regularRouteDuration);
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Error"),
                      content: const Text("Please select two points first"),
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
            },
            child: const Icon(Icons.info_outline, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 66, 72, 116),
            onPressed: _showFloodInfoDialog,
            child: const Icon(Icons.warning, color: Colors.white),
          ),
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
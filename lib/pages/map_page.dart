import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';

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
  }

  final defaultPoint = const LatLng(-7.2816569,112.7951051);

  List listOfPoints = [];
  List<LatLng> points = [];
  List<Marker> markers = [];

  Future<void> getCoordinates(LatLng lat1, LatLng lat2) async {
    setState(() {
      isLoading = true;
    });

    final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf624863612a1de12245a396f6ea37d234dbd6',
    );

    final List<ORSCoordinate> routeCoordinates =
        await client.directionsRouteCoordsGet(
      startCoordinate:
          ORSCoordinate(latitude: lat1.latitude, longitude: lat1.longitude),
      endCoordinate:
          ORSCoordinate(latitude: lat2.latitude, longitude: lat2.longitude),
    );

    final List<LatLng> routePoints = routeCoordinates
        .map((coordinate) => LatLng(coordinate.latitude, coordinate.longitude))
        .toList();

    setState(() {
      points = routePoints;
      isLoading = false;
    });
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
                  print(
                      "Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}");
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

        getCoordinates(markers[0].point, markers[1].point);

        // calculate the bounds of the markers
        LatLngBounds bounds = LatLngBounds.fromPoints(markers.map((marker) => marker.point).toList());
        // Zoom out so the extension fits the screen
        mapController.fitBounds(bounds);
      }
    });
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
              PolylineLayer(
                polylineCulling: false,
                polylines: [
                  Polyline(
                    points: points,
                    color: Colors.black,
                    strokeWidth: 5,
                  ),
                ],
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
                      points = [];
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
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reto 9 - GPS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MapController _mapController;
  Position? _currentPosition;
  double _radio = 1.0; // Radio inicial en kilómetros
  String _placeType = "Hospital"; // Tipo de punto de interés
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadPreferences();
    _getCurrentPosition();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
  var status = await Permission.location.request();

  if (status.isGranted) {
    print("Permiso de ubicación concedido.");
    // Aquí puedes continuar accediendo a la ubicación
  } else if (status.isDenied) {
    print("Permiso de ubicación denegado.");
    // Muestra un mensaje o maneja el rechazo
  } else if (status.isPermanentlyDenied) {
    print("Permiso denegado permanentemente. Abre configuraciones.");
    await openAppSettings(); // Abre la configuración de la app
  }
}

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _radio = prefs.getDouble('radio') ?? 1.0;
      _placeType = prefs.getString('placeType') ?? "hospital";
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('radio', _radio);
    await prefs.setString('placeType', _placeType);
  }

  Future<void> _getCurrentPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      _fetchNearbyPlaces();
    } catch (e) {
      print("Error al obtener la posición: $e");
    }
  }

  List<Map<String, dynamic>> _places =
      []; // Nueva lista para almacenar los lugares

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) return;

    final overpassApiUrl =
        "https://overpass-api.de/api/interpreter?data=[out:json];node[\"amenity\"=\"${_placeType.toLowerCase()}\"](around:${(_radio * 1000).toInt()},${_currentPosition!.latitude},${_currentPosition!.longitude});out;";

    try {
      final response = await http.get(Uri.parse(overpassApiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List<dynamic>;

        setState(() {
          _places = elements.map((element) {
            return {
              'name': element['tags']?['name'] ?? "Sin nombre",
              'lat': element['lat'] as double,
              'lon': element['lon'] as double,
            };
          }).toList();

          _markers = _places.map((place) {
            return Marker(
              point: LatLng(place['lat'], place['lon']),
              builder: (ctx) => Icon(Icons.location_on, color: Colors.red),
            );
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error al consultar puntos de interés: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al obtener puntos de interés: $e")),
      );
    }
  }

  void _showSettingsDialog() {
    final List<String> placeTypes = [
      "atm",
      "Bar",
      "biergarten",
      "Cafe",
      "cinema",
      "dancing_school",
      "doctors",
      "fast_food",
      "fire_station",
      "food_court",
      "Hospital",
      "ice_cream",
      "marketplace",
      "Pub",
      "Park",
      "pharmacy",
      "police",
      "post_office",
      "prison",
      "Restaurant",
      "School",
      "telephone",
      "social_centre",
      "theatre",
      "university",
      "veterinary",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Configuración"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _radio.toString(),
                decoration: InputDecoration(labelText: "Radio (km)"),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _radio = double.tryParse(value) ?? 1.0;
                },
              ),
              DropdownButtonFormField<String>(
                value: placeTypes.contains(_placeType)
                    ? _placeType
                    : null, // Valida el valor inicial
                decoration: InputDecoration(
                  labelText: "Tipo de lugar",
                  border: OutlineInputBorder(),
                ),
                items: placeTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _placeType = value!;
                  });
                },
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _savePreferences();
                Navigator.of(context).pop();
                _fetchNearbyPlaces();
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reto 9 - GPS'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa en la parte superior
          Expanded(
            child: (_currentPosition != null)
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      zoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(markers: _markers),
                    ],
                  )
                : Center(child: CircularProgressIndicator()),
          ),
          // Lista de lugares en la parte inferior
          Container(
            height: 200, // Altura fija para la lista
            child: _places.isNotEmpty
                ? ListView.builder(
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return ListTile(
                        leading: Icon(Icons.place, color: Colors.blue),
                        title: Text(place['name']),
                        subtitle:
                            Text("Lat: ${place['lat']}, Lon: ${place['lon']}"),
                        onTap: () {
                          // Centrar el mapa en el lugar seleccionado
                          _mapController.move(
                            LatLng(place['lat'], place['lon']),
                            16.0, // Zoom
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                      "No se encontraron puntos de interés.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

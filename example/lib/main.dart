import 'package:flutter/material.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int amountItems = 5;
  List<Marker> markers = [];

  // Controller to coordinate multiple CircularMenus on the map
  final CircularMenuGroupController _menuController = CircularMenuGroupController();

  // Sample charging station data (clustered locations in Berlin)
  final List<Map<String, dynamic>> _chargingStations = [
    {
      'name': 'Station Alpha',
      'lat': 52.5200,
      'lng': 13.4050,
      'color': Colors.blue,
      'available': 3,
    },
    {
      'name': 'Station Beta',
      'lat': 52.5210,
      'lng': 13.4070,
      'color': Colors.green,
      'available': 5,
    },
    {
      'name': 'Station Gamma',
      'lat': 52.5195,
      'lng': 13.4030,
      'color': Colors.orange,
      'available': 2,
    },
    {
      'name': 'Station Delta',
      'lat': 52.5205,
      'lng': 13.4055,
      'color': Colors.purple,
      'available': 0,
    },
    {
      'name': 'Station Epsilon',
      'lat': 52.5198,
      'lng': 13.4065,
      'color': Colors.teal,
      'available': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set up the bring-to-front callback
    _menuController.onBringToFront = _bringMarkerToFront;
    _buildMarkers();
  }

  void _buildMarkers() {
    // Build markers with CircularMenu for each station
    markers = List.generate(_chargingStations.length, (index) {
      final station = _chargingStations[index];
      final key = GlobalKey<CircularMenuState>();
      _menuController.register(key);

      return Marker(
        point: LatLng(station['lat'], station['lng']),
        width: 200,
        height: 200,
        child: CircularMenu(
          key: key,
          toggleButtonMargin: 0,
          toggleButtonPadding: 8,
          toggleButtonIconInactive: Icons.ev_station,
          toggleButtonIconActive: Icons.close,
          toggleButtonIconColor: Colors.white,
          toggleButtonColor: station['color'],
          toggleButtonSize: 24,
          // Badge showing available chargers
          toggleButtonBadgeEnabled: true,
          toggleButtonBadgeLabel: '${station['available']}',
          toggleButtonBadgeColor: station['available'] > 0 ? Colors.green : Colors.red,
          toggleButtonBadgeTextColor: Colors.white,
          toggleButtonBadgeTopOffset: -5,
          toggleButtonBadgeRightOffset: -5,
          toggleButtonBadgeHideOnOpen: true,
          animationDuration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
          radius: 60,
          alignment: Alignment.center,
          onOpen: () {
            _menuController.onMenuOpened(key);
          },
          onClose: () {
            _menuController.onMenuClosed(key);
          },
          items: [
            CircularMenuItem(
              iconSize: 20,
              icon: Icons.info_outline,
              color: station['color'],
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${station['name']}: ${station['available']} chargers available'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            CircularMenuItem(
              iconSize: 20,
              icon: Icons.navigation,
              color: Colors.blue,
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigate to ${station['name']}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            CircularMenuItem(
              iconSize: 20,
              icon: Icons.bolt,
              color: Colors.amber,
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Start charging at ${station['name']}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  /// Brings the marker with the given key to the front (end of list)
  void _bringMarkerToFront(GlobalKey<CircularMenuState> key) {
    final oldIndex = _menuController.bringKeyToFront(key);
    if (oldIndex == -1 || oldIndex == markers.length - 1) return;

    setState(() {
      final marker = markers.removeAt(oldIndex);
      markers.add(marker);
    });
  }

  @override
  void dispose() {
    // Unregister all keys
    for (final key in _menuController.menuKeys) {
      _menuController.unregister(key);
    }
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text('Clustered Markers Demo'),
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(52.5200, 13.4050), // Berlin center
              initialZoom: 16, // Zoomed in to see clustered markers
              maxZoom: 18,
              minZoom: 2,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.circular_menu_example',
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                popupInitialDisplayDuration: const Duration(seconds: 3),
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Info panel
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              color: Colors.white.withOpacity(0.9),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Tap a station marker to open its menu.\n'
                  'Other markers will hide automatically!',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Circular Menu overlay for general actions
          CircularMenu(
            toggleButtonMargin: 10,
            toggleButtonPadding: 5,
            toggleButtonIconInactive: Icons.menu,
            toggleButtonIconActive: Icons.close,
            toggleButtonIconColor: Colors.white,
            toggleButtonColor: Colors.blue,
            animationDuration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            reverseCurve: Curves.easeOut,
            radius: 70,
            alignment: Alignment.bottomRight,
            items: [
              for (int i = 0; i < amountItems; i++)
                CircularMenuItem(
                  iconSize: 30,
                  enableBadge: true,
                  badgeTextColor: Colors.white,
                  badgeTopOffset: 50,
                  badgeLabel: "$i",
                  icon: Icons.ev_station,
                  color: Colors.pink,
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Map action $i selected'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                )
            ],
          ),
        ],
      ),
    );
  }
}

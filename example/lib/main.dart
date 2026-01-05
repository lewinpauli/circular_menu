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

  @override
  void initState() {
    super.initState();
    // Add some sample markers
    markers = [
      Marker(
        point: const LatLng(52.5200, 13.4050), // Berlin
        width: 200,
        height: 200,
        child: CircularMenu(
          toggleButtonMargin: 0,
          toggleButtonPadding: 5,
          errorMessageIfItemsIsEmpty: "no Items found",
          toggleButtonIconInactive: Icons.menu,
          toggleButtonIconActive: Icons.close,
          toggleButtonIconColor: Colors.white,
          toggleButtonColor: Colors.blue,
          animationDuration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          reverseCurve: Curves.easeOut,
          radius: 70,
          alignment: Alignment.center,
          items: [
            CircularMenuItem(
              iconSize: 30,
              enableBadge: true,
              badgeTextColor: Colors.white,
              badgeTopOffset: 50,

              icon: Icons.info,
              color: Colors.green,

              badgeLabel: "Info",

              // badgeTopOffset: 25,
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Berlin Station Info'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            CircularMenuItem(
              iconSize: 20,
              icon: Icons.navigation,
              color: Colors.orange,
              enableBadge: true,
              badgeLabel: "Nav",
              badgeTextColor: Colors.white,
              badgeTopOffset: 25,
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Berlin'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      Marker(
        point: const LatLng(48.1351, 11.5820), // Munich
        width: 80,
        height: 80,
        child: const Icon(
          Icons.ev_station,
          color: Colors.green,
          size: 40,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text('Flutter Map with Circular Menu'),
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.16423, 10.45412), // Germany center
              initialZoom: 6,
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
          // Circular Menu overlay
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

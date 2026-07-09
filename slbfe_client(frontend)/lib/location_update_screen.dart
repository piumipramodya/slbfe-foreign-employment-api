import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Import for GPS logic
import 'api_service.dart';

class LocationUpdateScreen extends StatefulWidget {
  const LocationUpdateScreen({super.key});

  @override
  _LocationUpdateScreenState createState() => _LocationUpdateScreenState();
}

class _LocationUpdateScreenState extends State<LocationUpdateScreen> {
  // Controllers
  final _nidController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  // State Management
  bool _isFound = false;
  bool _isVerified = false;
  String _citizenName = "";
  bool _isLoading = false;

  @override
  void dispose() {
    _nidController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  // --- NEW LOGIC: GPS Location Fetching ---
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLoading = true);

    // 1. Check if GPS services are on
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar(
          "Location services are disabled. Please turn on GPS.", Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    // 2. Handle Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permissions are denied.", Colors.red);
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          "Location permissions are permanently denied. Check settings.",
          Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    // 3. Get the coordinates
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _longController.text = position.longitude.toStringAsFixed(6);
        _isLoading = false;
      });

      _showSnackBar("Current location detected!", Colors.green);
    } catch (e) {
      _showSnackBar("Error fetching location: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC 1: Identity Check ---
  void _checkIdentity() async {
    final String nid = _nidController.text.trim();
    if (nid.isEmpty) {
      _showSnackBar("Please enter an NID", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final data = await ApiService.checkStatus(nid);

    setState(() {
      _isLoading = false;
      if (data != null) {
        _isFound = true;
        _citizenName = data['name'];
        _isVerified = data['isVerified'];
        _latController.text = data['currentLat'].toString();
        _longController.text = data['currentLong'].toString();
      } else {
        _isFound = false;
        _showSnackBar("NID not found in the system!", Colors.red);
      }
    });
  }

  // --- LOGIC 2: Final Update ---
  void _handleUpdate() async {
    final String nid = _nidController.text.trim();
    final double? lat = double.tryParse(_latController.text);
    final double? long = double.tryParse(_longController.text);

    if (lat == null || long == null) {
      _showSnackBar("Error: Coordinates must be valid numbers!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success = await ApiService.updateLocation(nid, lat, long);
      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar("Foreign Location Saved Successfully!", Colors.green);
      } else {
        _showSnackBar("Update Failed. Please try again.", Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Connection Error: Check your server.", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Foreign Location Update"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Step 1: Verify Identity",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _nidController,
              decoration: const InputDecoration(
                labelText: "Enter NID to Start",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 15),
            _isLoading && !_isFound
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _checkIdentity,
                    icon: const Icon(Icons.person_search),
                    label: const Text("Search Identity"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
            if (_isFound) ...[
              const Divider(height: 50, thickness: 2),
              Text(
                "Citizen: $_citizenName",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    _isVerified ? Icons.verified : Icons.pending_actions,
                    color: _isVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isVerified
                        ? "Verified Official User"
                        : "Verification Pending",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              if (!_isVerified)
                const Card(
                  color: Colors.amberAccent,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "⚠️ Access Denied: You must be verified by a Bureau Officer before you can update your location.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else ...[
                const Text("Step 2: Update Coordinates",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),

                // --- NEW UI: GPS Detection Button ---
                OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Auto-Detect Current GPS"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.indigo),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _latController,
                  decoration: const InputDecoration(
                      labelText: "New Latitude", border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _longController,
                  decoration: const InputDecoration(
                      labelText: "New Longitude", border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("Submit Foreign Location"),
                      ),
              ],
            ]
          ],
        ),
      ),
    );
  }
}

//signup_2_choose_location

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'signup_3_describe_event.dart';

class SignupChooseLocation extends StatefulWidget {
  @override
  _SignupChooseLocationState createState() => _SignupChooseLocationState();
}

class _SignupChooseLocationState extends State<SignupChooseLocation> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLocating = false;
  double? _latitude;
  double? _longitude;
  String? _resolvedAddress;

  /// Use GPS to get current location and reverse-geocode it
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Location services are disabled. Please enable them.");
        setState(() => _isLocating = false);
        return;
      }

      // Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack("Location permission denied.");
          setState(() => _isLocating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack("Location permission permanently denied. Enable in settings.");
        setState(() => _isLocating = false);
        return;
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Reverse geocode to get a readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "Unknown Location";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        address = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(", ");
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _resolvedAddress = address;
        _addressController.text = address;
      });
    } catch (e) {
      print("Error getting location: $e");
      _showSnack("Failed to get location. Try entering manually.");
    }

    setState(() => _isLocating = false);
  }

  /// Forward geocode a manually entered address
  Future<void> _geocodeManualAddress() async {
    String address = _addressController.text.trim();
    if (address.isEmpty) {
      _showSnack("Please enter an address first.");
      return;
    }

    setState(() => _isLocating = true);

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
          _resolvedAddress = address;
        });
        _showSnack("Location verified ✓");
      } else {
        _showSnack("Could not find this address.");
      }
    } catch (e) {
      print("Geocoding error: $e");
      _showSnack("Could not geocode this address. Check spelling.");
    }

    setState(() => _isLocating = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateNext() {
    if (_addressController.text.trim().isEmpty) {
      _showSnack("Please enter or detect a location before continuing.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignupDescribeEvent(
          eventLocation: _resolvedAddress ?? _addressController.text.trim(),
          eventLatitude: _latitude,
          eventLongitude: _longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose Event Location")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Choose the Location for Your Event",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Enter the address manually and verify, or use GPS to auto-detect your current location.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),

            // Address input
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: "Event Address",
                hintText: "e.g., CVR College of Engineering, Hyderabad",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.indigo),
                  tooltip: "Verify Address",
                  onPressed: _geocodeManualAddress,
                ),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 16),

            // GPS Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _getCurrentLocation,
                icon: _isLocating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.my_location),
                label: Text(_isLocating ? "Detecting..." : "Use Current Location (GPS)"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Resolved location card
            if (_resolvedAddress != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Location Confirmed",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _resolvedAddress!,
                        style: TextStyle(fontSize: 15),
                      ),
                      if (_latitude != null && _longitude != null)
                        Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            "Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            Spacer(),

            // Next button
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _navigateNext,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Next", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

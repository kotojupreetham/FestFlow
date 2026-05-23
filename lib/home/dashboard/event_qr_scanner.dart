import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'about_event_details.dart';

class EventQRScanner extends StatefulWidget {
  @override
  _EventQRScannerState createState() => _EventQRScannerState();
}

class _EventQRScannerState extends State<EventQRScanner> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String code = barcodes.first.rawValue!;
      setState(() => isProcessing = true);
      cameraController.stop();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      try {
        DocumentSnapshot eventDoc = await FirebaseFirestore.instance
            .collection("events")
            .doc(code)
            .get();

        Navigator.pop(context); // pop loading dialog

        if (eventDoc.exists && eventDoc.data() != null) {
          Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
          
          Object? detailsObject = eventData["details"];
          Map<String, dynamic> finalData = {};
          
          if (detailsObject is Map<String, dynamic>) {
            finalData = Map<String, dynamic>.from(detailsObject);
          } else {
            finalData = Map<String, dynamic>.from(eventData);
          }
          
          // CRITICAL: AboutEventDetailsPage expects 'id' to be set
          finalData["id"] = eventDoc.id;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AboutEventDetailsPage(
                eventData: finalData,
              ),
            ),
          );
        } else {
          _showError("Event Not Found", "The scanned QR code is either invalid or the event no longer exists.");
        }
      } catch (e) {
        Navigator.pop(context); // pop loading dialog
        _showError("Error", "Failed to fetch event data. Please try again.");
      }
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isProcessing = false);
              cameraController.start();
            },
            child: Text("OK", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Event QR Code"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Viewfinder overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "Position the QR code inside the box",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

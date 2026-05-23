import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class QRViewerDialog extends StatelessWidget {
  final String eventCode;

  const QRViewerDialog({Key? key, required this.eventCode}) : super(key: key);

  Future<void> _shareQR(BuildContext context) async {
    try {
      // 1. Generate QR code image
      final qrValidationResult = QrValidator.validate(
        data: eventCode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        // 2. Save it to temp directory
        final tempDir = await getTemporaryDirectory();
        final ts = DateTime.now().millisecondsSinceEpoch.toString();
        final path = '${tempDir.path}/qr_$ts.png';
        
        final picData = await painter.toImageData(2048);
        if (picData != null) {
          final buffer = picData.buffer;
          await File(path).writeAsBytes(
              buffer.asUint8List(picData.offsetInBytes, picData.lengthInBytes));

          // 3. Share the file
          await Share.shareXFiles([XFile(path)], 
              text: 'Scan this QR to join my event ($eventCode) on FestFlow!');
        }
      }
    } catch (e) {
      print('Error sharing QR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share QR code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Event QR Code", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: eventCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                errorStateBuilder: (cxt, err) {
                  return const SizedBox.shrink(); // Hide image completely if generation fails
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Code: $eventCode",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: Colors.blueAccent),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: eventCode)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Event code copied to clipboard!')),
                    );
                  });
                },
                tooltip: 'Copy Code',
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Share this QR code with others so they can scan it to join the event.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
        ElevatedButton.icon(
          onPressed: () => _shareQR(context),
          icon: Icon(Icons.share),
          label: Text("Share"),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

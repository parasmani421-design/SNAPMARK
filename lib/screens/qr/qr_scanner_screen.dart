import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/services/campus_location_service.dart';
import '../face/face_verification_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late final MobileScannerController scannerController;

  double zoom = 0.0;
  bool isProcessing = false;
  bool _checkingLocation = true;
  bool _locationVerified = false;
  String? _locationError;

  String statusText = 'Scan the current classroom QR';

  @override
  void initState() {
    super.initState();

    scannerController = MobileScannerController(
      autoZoom: false,
      initialZoom: 0.0,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 300,
    );
    _verifyLocationBeforeOpening();
  }

  Future<void> _verifyLocationBeforeOpening() async {
    if (mounted) {
      setState(() {
        _checkingLocation = true;
        _locationError = null;
      });
    }
    final error = await const CampusLocationService().checkCampusLocation();
    if (!mounted) return;
    setState(() {
      _checkingLocation = false;
      _locationVerified = error == null;
      _locationError = error;
      statusText = error ?? 'Campus verified · scan the current classroom QR';
    });
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> setZoom(double value) async {
    final newZoom = value.clamp(0.0, 1.0).toDouble();

    setState(() {
      zoom = newZoom;
    });

    try {
      await scannerController.setZoomScale(newZoom);
    } catch (_) {}
  }

  void zoomIn() {
    setZoom(zoom + 0.10);
  }

  void zoomOut() {
    setZoom(zoom - 0.10);
  }

  Future<void> handleQR(String value) async {
    if (isProcessing) return;

    final qr = value.trim();

    if (qr.isEmpty) return;

    final parts = qr.split('|');

    // Expected:
    // SNAPMARK|TOKEN|SUBJECT|ROOM|EXPIRY
    if (parts.length != 5 ||
        parts[0] != 'SNAPMARK' ||
        parts[1].length < 8 ||
        parts[2].trim().isEmpty ||
        parts[3].trim().isEmpty) {
      _showMessage('Invalid SnapMark QR');
      return;
    }

    final expiry = int.tryParse(parts[4]);

    if (expiry == null) {
      _showMessage('Invalid QR expiry');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Expired QR
    if (now >= expiry) {
      _showMessage('QR expired. Scan the current QR.');
      return;
    }
    if (expiry - now > const Duration(seconds: 10).inMilliseconds) {
      _showMessage('QR expiry is invalid. Ask your teacher to refresh it.');
      return;
    }

    // The scanner route can be opened directly, so verify the live location
    // again at scan time instead of trusting the dashboard gate.
    setState(() {
      isProcessing = true;
      statusText = 'Rechecking campus location…';
    });
    await scannerController.stop();
    final locationError = await const CampusLocationService()
        .checkCampusLocation();
    if (!mounted) return;
    if (locationError != null) {
      setState(() {
        isProcessing = false;
        _locationVerified = false;
        _locationError = locationError;
        statusText = locationError;
      });
      return;
    }

    setState(() {
      _locationVerified = true;
      isProcessing = true;
      statusText = 'QR time checked · starting face verification…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    setState(() {
      isProcessing = false;
      statusText = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B14),

      appBar: AppBar(
        backgroundColor: const Color(0xff070B14),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Scan Classroom QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () {
              scannerController.toggleTorch();
            },
          ),
        ],
      ),

      body: _locationVerified
          ? Stack(
              children: [
                // CAMERA
                Positioned.fill(
                  child: MobileScanner(
                    controller: scannerController,

                    onDetect: (capture) {
                      if (capture.barcodes.isEmpty) {
                        return;
                      }

                      final value = capture.barcodes.first.rawValue;

                      if (value != null) {
                        handleQR(value);
                      }
                    },
                  ),
                ),

                // OVERLAY
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: Colors.black.withOpacity(.25)),
                  ),
                ),

                // TITLE
                Positioned(
                  top: 25,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: const [
                      Text(
                        'Scan Classroom QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Scan the current QR displayed by your teacher',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // QR FRAME
                Center(
                  child: Container(
                    width: 285,
                    height: 285,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.blueAccent, width: 3),
                    ),
                  ),
                ),

                Center(
                  child: SizedBox(
                    width: 285,
                    height: 285,
                    child: CustomPaint(painter: QRCornerPainter()),
                  ),
                ),

                // ZOOM
                Positioned(
                  right: 18,
                  bottom: 155,
                  child: Container(
                    width: 55,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xff101827).withOpacity(.95),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: zoomIn,
                          icon: const Icon(Icons.add, color: Colors.white),
                        ),

                        SizedBox(
                          height: 130,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: zoom,
                              min: 0,
                              max: 1,
                              divisions: 20,
                              onChanged: setZoom,
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.white24,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: zoomOut,
                          icon: const Icon(Icons.remove, color: Colors.white),
                        ),

                        Text(
                          '${(zoom * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // STATUS
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 25,
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xff101827).withOpacity(.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isProcessing
                            ? Colors.greenAccent
                            : Colors.blueAccent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isProcessing ? Icons.verified : Icons.qr_code_scanner,
                          color: isProcessing
                              ? Colors.greenAccent
                              : Colors.blueAccent,
                          size: 27,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _locationGate(),
    );
  }

  Widget _locationGate() {
    final message = _checkingLocation
        ? 'Checking that you are on campus…'
        : (_locationError ?? 'Campus location could not be verified.');
    return Container(
      color: const Color(0xff070B14),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _checkingLocation
                  ? Icons.location_searching_rounded
                  : Icons.location_off_rounded,
              color: const Color(0xff79A7FF),
              size: 52,
            ),
            const SizedBox(height: 18),
            const Text(
              'Campus check required',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            if (_checkingLocation) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ] else ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _verifyLocationBeforeOpening,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Check again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QRCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const length = 45.0;

    // Top left
    canvas.drawLine(const Offset(0, length), Offset.zero, paint);

    canvas.drawLine(Offset.zero, const Offset(length, 0), paint);

    // Top right
    canvas.drawLine(
      Offset(size.width - length, 0),
      Offset(size.width, 0),
      paint,
    );

    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom left
    canvas.drawLine(
      Offset(0, size.height - length),
      Offset(0, size.height),
      paint,
    );

    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);

    // Bottom right
    canvas.drawLine(
      Offset(size.width - length, size.height),
      Offset(size.width, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(size.width, size.height - length),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

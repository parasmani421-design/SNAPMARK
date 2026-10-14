import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeacherQRScreen extends StatefulWidget {
  const TeacherQRScreen({super.key});

  @override
  State<TeacherQRScreen> createState() => _TeacherQRScreenState();
}

class _TeacherQRScreenState extends State<TeacherQRScreen> {
  Timer? timer;

  static const int qrLifetimeSeconds = 7;
  int secondsLeft = qrLifetimeSeconds;
  int qrVersion = 0;

  String qrData = '';

  final String subject = 'Data Base Management System';
  final String room = 'Room 204';

  @override
  void initState() {
    super.initState();

    _generateNewQR();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (secondsLeft <= 1) {
        _generateNewQR();
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  void _generateNewQR() {
    final random = Random.secure();

    final now = DateTime.now().millisecondsSinceEpoch;

    final expiresAt =
        now + const Duration(seconds: qrLifetimeSeconds).inMilliseconds;

    final randomNumber = random.nextInt(1 << 32);

    final token = 'SM_${now}_$randomNumber';

    final data = [
      'SNAPMARK',
      token,
      subject,
      room,
      expiresAt.toString(),
    ].join('|');

    setState(() {
      qrData = data;
      secondsLeft = qrLifetimeSeconds;
      qrVersion++;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B14),

      appBar: AppBar(
        backgroundColor: const Color(0xff070B14),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Teacher Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2, color: Colors.blueAccent, size: 48),

              const SizedBox(height: 10),

              const Text(
                'Classroom QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Students must scan the current QR',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 25),

              // CLASS INFORMATION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xff101827),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xff172554),
                      child: Icon(Icons.school, color: Colors.blueAccent),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Data Base Management System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Room 204 • Attendance Session',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // QR CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(.20),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (qrData.isNotEmpty)
                      QrImageView(
                        key: ValueKey(qrVersion),
                        data: qrData,
                        version: QrVersions.auto,
                        size: 280,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // TIMER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff101827),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blueAccent.withOpacity(.30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.blueAccent,
                      size: 28,
                    ),

                    const SizedBox(width: 12),

                    Text(
                      'New QR in $secondsLeft seconds',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SECURITY INFO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xff0d1424),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(.20),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security, color: Colors.greenAccent, size: 25),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'This QR code automatically changes every 7 seconds. Students must scan the currently displayed QR.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Session #$qrVersion',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../qr/attendance_success_screen.dart';

class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B14),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'AI Verification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // SUCCESS ICON
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.greenAccent.withOpacity(.12),
                border: Border.all(
                  color: Colors.greenAccent,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.greenAccent,
                size: 60,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Verification Complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Attendance security checks completed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 35),

            _checkCard(
              icon: Icons.qr_code_scanner,
              title: 'QR Verification',
              subtitle: 'Classroom QR detected',
            ),

            _checkCard(
              icon: Icons.face,
              title: 'Face Detection',
              subtitle: 'Single face detected',
            ),

            _checkCard(
              icon: Icons.center_focus_strong,
              title: 'Face Position',
              subtitle: 'Face positioned correctly',
            ),

            _checkCard(
              icon: Icons.visibility,
              title: 'Liveness Check',
              subtitle: 'Head movement and eye blink completed',
            ),

            _checkCard(
              icon: Icons.people_outline,
              title: 'Multiple Face Check',
              subtitle: 'Only one face detected',
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff101827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'SnapMark uses multiple verification steps before attendance is recorded.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AttendanceSuccessScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue to Attendance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _checkCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff101827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.greenAccent,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle,
            color: Colors.greenAccent,
            size: 24,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class GlowingBackground extends StatelessWidget {
  const GlowingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff050816),
                Color(0xff091A35),
                Color(0xff132D63),
              ],
            ),
          ),
        ),

        // Top Glow
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            height: 260,
            width: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent.withOpacity(.18),
            ),
          ),
        ),

        // Right Glow
        Positioned(
          right: -90,
          top: 150,
          child: Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.lightBlue.withOpacity(.10),
            ),
          ),
        ),

        // Bottom Glow
        Positioned(
          bottom: -120,
          left: -50,
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(.15),
            ),
          ),
        ),
      ],
    );
  }
}
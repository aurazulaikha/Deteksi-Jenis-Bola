import 'package:ball_tect_app/capture_page.dart';
import 'package:flutter/material.dart';
import 'package:ball_tect_app/live_detection.dart';  // Pastikan import LiveDetectionPage

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Halaman Utama")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman deteksi bola live
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LiveDetectionPage()),
                );
              },
              child: const Text("Deteksi Jenis Bola Secara Langsung"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigasi ke halaman capture gambar dan deteksi bola
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CaptureImagePage()),
                );
              },
              child: const Text("Capture Gambar untuk Deteksi Bola"),
            ),
          ],
        ),
      ),
    );
  }
}

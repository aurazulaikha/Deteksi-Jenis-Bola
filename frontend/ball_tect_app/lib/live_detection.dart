import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiveDetectionPage extends StatefulWidget {
  const LiveDetectionPage({super.key});

  @override
  State<LiveDetectionPage> createState() => _LiveDetectionPageState();
}

class _LiveDetectionPageState extends State<LiveDetectionPage> {
  CameraController? _controller;
  bool _isDetecting = false;
  String? _hasilPrediksi;
  Timer? _timer;
  String _waktuDeteksi = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(camera, ResolutionPreset.medium);
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _ambilDanKirimFrame());
  }

  Future<void> _ambilDanKirimFrame() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDetecting) return;

    try {
      _isDetecting = true;
      final XFile file = await _controller!.takePicture();
      File imageFile = File(file.path);
      _waktuDeteksi = DateTime.now().toString();
      await _kirimKeAPI(imageFile);
    } catch (e) {
      print("Error saat ambil frame: $e");
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _kirimKeAPI(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.212.228:5000/predict'), // Ganti dengan IP backend kamu
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(await response.stream.bytesToString());
        setState(() {
          _hasilPrediksi = jsonData['jenis_bola'];
        });
      } else {
        setState(() {
          _hasilPrediksi = 'Deteksi gagal';
        });
      }
    } catch (e) {
      print("Gagal kirim ke API: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text("Deteksi Bola Realtime")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 300,
                child: Stack(
                  children: [
                    // Membuat frame kamera agar berada di tengah
                    Align(
                      alignment: Alignment.center,
                      child: CameraPreview(_controller!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_hasilPrediksi != null)
              Column(
                children: [
                  Text("Jenis Bola: $_hasilPrediksi", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Waktu Deteksi: $_waktuDeteksi", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

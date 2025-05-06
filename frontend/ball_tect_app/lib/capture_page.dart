import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CaptureImagePage extends StatefulWidget {
  const CaptureImagePage({super.key});

  @override
  _CaptureImagePageState createState() => _CaptureImagePageState();
}

class _CaptureImagePageState extends State<CaptureImagePage> {
  File? _imageFile;
  String? _hasilPrediksi;

  Future<void> _ambilGambar() async {
    final picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _sendToApi(_imageFile!);
      }
    } catch (e) {
      print("Gagal membuka kamera: $e");
    }
  }

  Future<void> _sendToApi(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.212.228:5000/predict'), // http://192.168.18.11:5000/predict
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Deteksi Bola dari Kamera")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _ambilGambar,
                child: const Text("Ambil Gambar dari Kamera"),
              ),
              const SizedBox(height: 20),
              if (_imageFile != null)
                Image.file(_imageFile!, height: 200),
              const SizedBox(height: 20),
              if (_hasilPrediksi != null)
                Text("Jenis Bola: $_hasilPrediksi", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

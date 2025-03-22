import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OCRScreen(camera: camera),
    );
  }
}

class OCRScreen extends StatefulWidget {
  final CameraDescription camera;
  const OCRScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String scannedText = "";
  bool isCameraActive = false;

  void toggleCamera() {
    if (isCameraActive) {
      _controller?.dispose();
      setState(() {
        isCameraActive = false;
      });
    } else {
      _controller = CameraController(widget.camera, ResolutionPreset.high);
      _initializeControllerFuture = _controller?.initialize();
      setState(() {
        isCameraActive = true;
      });
    }
  }

  Future<void> takePictureAndScanText() async {
    if (_controller == null) return;
    
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        scannedText = recognizedText.text;
        isCameraActive = false;
      });

      textRecognizer.close();
      _controller?.dispose();
    } catch (e) {
      print(e);
    }
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: scannedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texto copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR App')),
      body: Column(
        children: [
          if (isCameraActive) ...[
            Expanded(
              flex: 2,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller!);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: takePictureAndScanText,
              child: const Text('Tomar Foto y Escanear Texto'),
            ),
          ] else ...[
            Expanded(
              flex: 1,
              child: Center(
                child: ElevatedButton(
                  onPressed: toggleCamera,
                  child: const Text('Abrir Cámara'),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2)
                  ],
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    scannedText.isNotEmpty ? scannedText : "Aquí aparecerá el texto escaneado",
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ),
            ),
            if (scannedText.isNotEmpty)
              ElevatedButton(
                onPressed: copyToClipboard,
                child: const Text('Copiar Texto'),
              ),
          ],
        ],
      ),
    );
  }
}

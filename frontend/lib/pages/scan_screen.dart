import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/scan_result.dart';
import '../services/scan_result_service.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.onBackPressed});

  final VoidCallback? onBackPressed;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  static const String _defaultBackendUrl = 'http://10.0.0.77:8000';
  static const String _backendUrlOverride = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: _defaultBackendUrl,
  );

  CameraController? _cameraController;
  Future<void> _initializeControllerFuture = Future.value();
  late AnimationController _animationController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;
  Timer? _processingTimer;

  String get _backendBaseUrl {
    final configuredValue = _backendUrlOverride.trim();
    if (configuredValue.isNotEmpty) {
      return configuredValue;
    }

    return Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
  }

  Future<File> _cropImageToScanFrame(String imagePath) async {
    try {
      // Read the original image
      final imageBytes = File(imagePath).readAsBytesSync();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Scan frame is 280x280 and centered
      const frameSize = 280.0;
      
      // Calculate crop bounds based on screen dimensions
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // The scan frame is centered
      final frameLeft = (screenWidth - frameSize) / 2;
      final frameTop = (screenHeight - frameSize) / 2;
      
      // Calculate the ratio between image dimensions and screen dimensions
      final imageWidth = originalImage.width.toDouble();
      final imageHeight = originalImage.height.toDouble();
      
      // For camera capture, the image orientation might differ
      // Adjust crop coordinates based on actual image dimensions
      final widthRatio = imageWidth / screenWidth;
      final heightRatio = imageHeight / screenHeight;
      
      final cropX = (frameLeft * widthRatio).toInt();
      final cropY = (frameTop * heightRatio).toInt();
      final cropWidth = (frameSize * widthRatio).toInt();
      final cropHeight = (frameSize * heightRatio).toInt();
      
      // Ensure crop bounds are within image bounds
      final safeX = cropX.clamp(0, originalImage.width - 1);
      final safeY = cropY.clamp(0, originalImage.height - 1);
      final safeWidth = cropWidth.clamp(1, originalImage.width - safeX);
      final safeHeight = cropHeight.clamp(1, originalImage.height - safeY);
      
      // Crop the image
      final croppedImage = img.copyCrop(
        originalImage,
        x: safeX,
        y: safeY,
        width: safeWidth,
        height: safeHeight,
      );
      
      // Save cropped image to temporary file
      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
        '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      croppedFile.writeAsBytesSync(img.encodeJpg(croppedImage, quality: 95));
      
      return croppedFile;
    } catch (e) {
      print('Error cropping image: $e');
      // Return original if cropping fails
      return File(imagePath);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _isInitialized = true;
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _startProcessing() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      if (_cameraController!.value.flashMode != FlashMode.off) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      final image = await _cameraController!.takePicture();
      if (!mounted) return;

      // Crop image to scan frame bounds
      final croppedImage = await _cropImageToScanFrame(image.path);

      setState(() {
        _capturedImage = XFile(croppedImage.path);
      });

      final result = await _sendImageToBackend(croppedImage);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(scanResult: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: $e')),
      );
      print('Error capturing image: $e');
    }
  }

  Future<ScanResult> _sendImageToBackend(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_backendBaseUrl/api/predict/'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw http.ClientException('Request timed out while contacting backend');
        },
      );
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        throw Exception('Backend prediction failed: $responseBody');
      }

      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final safePrediction = decoded['prediction'] ?? 'unknown';
      final safeLabel = decoded['label'] ?? 'Unknown shell';
      final safeConfidence = (decoded['confidence'] is num)
          ? (decoded['confidence'] as num).toDouble()
          : 0.0;

      final result = ScanResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shellName: safeLabel,
        prediction: safePrediction,
        confidence: safeConfidence,
        label: safeLabel,
        filename: imageFile.path.split('/').last,
        imageUrl: imageFile.path,
        createdAt: DateTime.now(),
        rawResponse: decoded,
      );

      await ScanResultService().saveScanResult(result);
      return result;
    } on http.ClientException catch (e) {
      throw Exception('Unable to reach backend at $_backendBaseUrl: $e');
    } catch (e) {
      rethrow;
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            widget.onBackPressed?.call();
          },
        ),
        title: const Text(
          'Identify Seashell',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  // Camera Preview
                  if (_cameraController != null && _cameraController!.value.isInitialized)
                    CameraPreview(_cameraController!),

                  // Scan Frame Overlay
                  Center(
                    child: _isInitialized
                        ? AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                  left: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                  right: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topRight:
                                                      Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                  left: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                  right: BorderSide(
                                                    color: const Color(
                                                        0xFF4A9FB5),
                                                    width: 3,
                                                  ),
                                                ),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomRight:
                                                      Radius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Animated scanning line
                                    Positioned(
                                      top: _animationController.value * 240,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color(0xFF4A9FB5)
                                                  .withValues(alpha: 0),
                                              const Color(0xFF4A9FB5)
                                                  .withValues(alpha: 0.15),
                                              const Color(0xFF4A9FB5)
                                                  .withValues(alpha: 0.4),
                                              const Color(0xFF4A9FB5)
                                                  .withValues(alpha: 0.15),
                                              const Color(0xFF4A9FB5)
                                                  .withValues(alpha: 0),
                                            ],
                                            stops: const [0, 0.2, 0.5, 0.8, 1],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF4A9FB5)
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                  ),

                  if (_isProcessing)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),

                  if (_isProcessing)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4A9FB5),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _capturedImage != null
                                  ? Image.file(
                                      File(_capturedImage!.path),
                                      fit: BoxFit.cover,
                                      width: 190,
                                      height: 190,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    )
                                  : (_cameraController != null && _cameraController!.value.isInitialized
                                      ? CameraPreview(_cameraController!)
                                      : const SizedBox.shrink()),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Processing, Please wait...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isProcessing)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _startProcessing,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A9FB5),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.center_focus_strong,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF4A9FB5),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

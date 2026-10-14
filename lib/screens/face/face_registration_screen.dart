import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() =>
      _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState
    extends State<FaceRegistrationScreen> {
  CameraController? cameraController;
  late FaceDetector faceDetector;

  bool cameraReady = false;
  bool processing = false;

  String status = 'Initializing camera...';

  @override
  void initState() {
    super.initState();

    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: true,
        minFaceSize: 0.15,
      ),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          status = 'No camera found';
        });
        return;
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      cameraController = controller;

      setState(() {
        cameraReady = true;
        status = 'Position your face inside the frame';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'Camera initialization failed';
      });
    }
  }

  Future<void> _captureFace() async {
    if (processing ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      processing = true;
      status = 'Capturing face...';
    });

    try {
      final image =
          await cameraController!.takePicture();

      setState(() {
        status = 'AI is detecting your face...';
      });

      final inputImage =
          InputImage.fromFilePath(image.path);

      final faces =
          await faceDetector.processImage(inputImage);

      if (!mounted) return;

      if (faces.isEmpty) {
        setState(() {
          processing = false;
          status =
              'No face detected. Please try again.';
        });
        return;
      }

      if (faces.length > 1) {
        setState(() {
          processing = false;
          status =
              'Multiple faces detected. Only one person should be visible.';
        });
        return;
      }

      final face = faces.first;

      final imageSize =
          inputImage.metadata?.size;

      if (imageSize != null) {
        final centerX = imageSize.width / 2;
        final centerY = imageSize.height / 2;

        final faceCenterX =
            face.boundingBox.center.dx;
        final faceCenterY =
            face.boundingBox.center.dy;

        final xDifference =
            (faceCenterX - centerX).abs();

        final yDifference =
            (faceCenterY - centerY).abs();

        if (xDifference >
                imageSize.width * 0.30 ||
            yDifference >
                imageSize.height * 0.30) {
          setState(() {
            processing = false;
            status =
                'Please keep your face in the center.';
          });
          return;
        }
      }

      setState(() {
        status = 'Face detected successfully ✓';
      });

      await Future.delayed(
        const Duration(milliseconds: 1000),
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        processing = false;
        status =
            'Verification failed. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B14),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Face Registration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: !cameraReady
          ? _loadingView()
          : Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(
                    cameraController!,
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    color:
                        Colors.black.withOpacity(0.25),
                  ),
                ),

                // FACE FRAME
                Center(
                  child: Container(
                    width: 250,
                    height: 310,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(125),
                      border: Border.all(
                        color: processing
                            ? Colors.orangeAccent
                            : Colors.blueAccent,
                        width: 4,
                      ),
                    ),
                  ),
                ),

                // TOP TEXT
                Positioned(
                  top: 25,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: const [
                      Text(
                        'Register Your Face',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Keep your face inside the frame',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // BOTTOM PANEL
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 25,
                  child: Container(
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xff101827)
                              .withOpacity(0.95),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              processing
                                  ? Icons.face
                                  : Icons
                                      .face_retouching_natural,
                              color:
                                  processing
                                      ? Colors
                                          .orangeAccent
                                      : Colors
                                          .blueAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status,
                                style:
                                    const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                processing
                                    ? null
                                    : _captureFace,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.blueAccent,
                              disabledBackgroundColor:
                                  Colors.grey,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(15),
                              ),
                            ),
                            child: Text(
                              processing
                                  ? 'Processing...'
                                  : 'Capture & Register Face',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 20),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
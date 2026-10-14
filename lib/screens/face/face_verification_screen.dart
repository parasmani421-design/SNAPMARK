import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:vibration/vibration.dart';

import '../qr/attendance_success_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends State<FaceVerificationScreen> {
  CameraController? cameraController;
  late final FaceDetector faceDetector;

  bool cameraReady = false;
  bool processing = false;
  bool faceInsideGuide = false;
  bool verificationComplete = false;

  int step = 0;

  int leftStableFrames = 0;
  int rightStableFrames = 0;

  bool eyesOpenSeenForBlink = false;
  bool eyesClosedForBlink = false;
  int closedEyeFramesForBlink = 0;
  bool blinkDetected = false;

  DateTime? lastProcessedTime;

  String statusText = 'Place your face inside the guide';

  @override
  void initState() {
    super.initState();

    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,

        // Required for blink detection.
        enableClassification: true,

        enableLandmarks: false,
        enableContours: false,

        minFaceSize: 0.12,
      ),
    );

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          statusText = 'No camera found';
        });

        return;
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        cameraReady = true;
        statusText = 'Place your face inside the guide';
      });

      await cameraController!.startImageStream(
        _processCameraImage,
      );
    } catch (e) {
      debugPrint('Camera error: $e');

      if (!mounted) return;

      setState(() {
        statusText = 'Camera initialization failed';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (processing || verificationComplete) {
      return;
    }

    // Process approximately 6-7 frames per second.
    final now = DateTime.now();

    if (lastProcessedTime != null &&
        now.difference(lastProcessedTime!).inMilliseconds < 150) {
      return;
    }

    lastProcessedTime = now;
    processing = true;

    try {
      final inputImage = _convertCameraImage(image);

      if (inputImage == null) {
        processing = false;
        return;
      }

      final faces = await faceDetector.processImage(inputImage);

      if (!mounted || verificationComplete) {
        processing = false;
        return;
      }

      if (faces.isEmpty) {
        _updateStatus(
          inside: false,
          text: 'No face detected',
        );

        _resetMovement();

        processing = false;
        return;
      }

      if (faces.length > 1) {
        _updateStatus(
          inside: false,
          text: 'Only one face should be visible',
        );

        _resetMovement();

        processing = false;
        return;
      }

      final face = faces.first;

      final inside = _isFaceInsideGuide(
        face.boundingBox,
        inputImage.metadata?.size,
      );

      if (!inside) {
        _updateStatus(
          inside: false,
          text: 'Move your face inside the guide',
        );

        _resetMovement();

        processing = false;
        return;
      }

      setState(() {
        faceInsideGuide = true;
      });

      _processLiveness(face);
    } catch (e) {
      debugPrint('Face detection error: $e');
    }

    processing = false;
  }

  void _processLiveness(Face face) {
    final headAngle = face.headEulerAngleY;

    // STEP 0
    // Face is correctly positioned.
    if (step == 0) {
      setState(() {
        step = 1;
        statusText = 'Turn your head LEFT';
      });

      return;
    }

    // STEP 1
    // LEFT movement.
    if (step == 1) {
      if (headAngle != null && headAngle < -12) {
        leftStableFrames++;

        if (leftStableFrames >= 2) {
          leftStableFrames = 0;

          setState(() {
            step = 2;
            statusText = 'Left movement detected ✓';
          });

          Future.delayed(
            const Duration(milliseconds: 500),
            () {
              if (!mounted || verificationComplete || step != 3) return;

              setState(() {
                statusText = 'Now turn your head RIGHT';
              });
            },
          );
        }
      } else {
        leftStableFrames = 0;
      }

      return;
    }

    // STEP 2
    // RIGHT movement.
    if (step == 2) {
      if (headAngle != null && headAngle > 12) {
        rightStableFrames++;

        if (rightStableFrames >= 2) {
          rightStableFrames = 0;

          setState(() {
            step = 3;
            statusText = 'Right movement detected ✓';
          });

          Future.delayed(
            const Duration(milliseconds: 500),
            () {
              if (!mounted ||
                  verificationComplete ||
                  step != 3 ||
                  eyesClosedForBlink) {
                return;
              }

              setState(() {
                statusText =
                    'Open your eyes, then close both briefly and open them';
              });
            },
          );
        }
      } else {
        rightStableFrames = 0;
      }

      return;
    }

    // STEP 3
    // BLINK.
    if (step == 3) {
      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;

      if (leftEye == null || rightEye == null) {
        return;
      }

      final eyesClosed =
          leftEye < 0.35 &&
          rightEye < 0.35;
      final eyesOpen =
          leftEye > 0.65 &&
          rightEye > 0.65;

      // Arm the challenge only after observing open eyes in this step. This
      // prevents reopening eyes after the head turn from counting as a blink.
      if (!eyesOpenSeenForBlink) {
        if (eyesOpen) {
          eyesOpenSeenForBlink = true;
          setState(() {
            statusText = 'Eyes open ✓ Close both eyes briefly';
          });
        }
        return;
      }

      if (!eyesClosedForBlink) {
        if (eyesClosed) {
          closedEyeFramesForBlink++;
          if (closedEyeFramesForBlink >= 2) {
            eyesClosedForBlink = true;
            setState(() {
              statusText = 'Eyes closed ✓ Now open both eyes';
            });
          }
        } else {
          closedEyeFramesForBlink = 0;
        }
        return;
      }

      // Require the eyes to reopen after two consecutive closed-eye frames.
      if (eyesClosedForBlink && eyesOpen && !blinkDetected) {
        blinkDetected = true;
        setState(() {
          step = 4;
          statusText = 'Blink detected ✓';
        });

        Future.delayed(
          const Duration(milliseconds: 700),
          () {
            if (!mounted || verificationComplete) return;

            _completeVerification();
          },
        );
      }
    }
  }

  void _resetMovement() {
    leftStableFrames = 0;
    rightStableFrames = 0;
  }

  void _updateStatus({
    required bool inside,
    required String text,
  }) {
    if (!mounted) return;

    if (faceInsideGuide != inside || statusText != text) {
      setState(() {
        faceInsideGuide = inside;
        statusText = text;
      });
    }
  }

  Future<void> _completeVerification() async {
    if (verificationComplete) return;

    verificationComplete = true;

    setState(() {
      statusText = 'Liveness verification complete ✓';
    });

    try {
      await Vibration.vibrate(duration: 1000);
    } catch (e) {
      debugPrint('Success vibration failed: $e');
    }

    Future.delayed(
      const Duration(milliseconds: 800),
      () async {
        if (!mounted) return;

        await _stopCamera();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendanceSuccessScreen(),
          ),
        );
      },
    );
  }

  bool _isFaceInsideGuide(
    Rect face,
    Size? imageSize,
  ) {
    if (imageSize == null) {
      return false;
    }

    final centerX =
        face.center.dx / imageSize.width;

    final centerY =
        face.center.dy / imageSize.height;

    // Larger detection area.
    const guideCenterX = 0.50;
    const guideCenterY = 0.50;

    // Oval guide.
    const radiusX = 0.42;
    const radiusY = 0.46;

    final dx = centerX - guideCenterX;
    final dy = centerY - guideCenterY;

    final ellipseDistance =
        (dx * dx) / (radiusX * radiusX) +
        (dy * dy) / (radiusY * radiusY);

    final centerInside =
        ellipseDistance <= 1.0;

    final faceWidth =
        face.width / imageSize.width;

    final faceHeight =
        face.height / imageSize.height;

    final reasonableSize =
        faceWidth > 0.10 &&
        faceWidth < 0.80 &&
        faceHeight > 0.10 &&
        faceHeight < 0.90;

    return centerInside && reasonableSize;
  }

  InputImage? _convertCameraImage(
    CameraImage image,
  ) {
    try {
      final WriteBuffer bytes = WriteBuffer();

      for (final plane in image.planes) {
        bytes.putUint8List(plane.bytes);
      }

      final camera =
          cameraController?.description;

      if (camera == null) {
        return null;
      }

      final rotation =
          InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );

      if (rotation == null) {
        return null;
      }

      final format =
          InputImageFormatValue.fromRawValue(
        image.format.raw,
      );

      if (format == null) {
        return null;
      }

      final metadata = InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: rotation,
        format: format,
        bytesPerRow:
            image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes
            .done()
            .buffer
            .asUint8List(),
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Image conversion error: $e');
      return null;
    }
  }

  Future<void> _stopCamera() async {
    try {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopCamera();
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
          'Face Verification',
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

                // CAMERA
                Positioned.fill(
                  child: CameraPreview(
                    cameraController!,
                  ),
                ),

                // DARK OVERLAY
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                ),

                // TOP TITLE
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: const [
                      Text(
                        'AI Face Verification',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        'Keep your face inside the oval',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // LARGE FACE GUIDE
                Center(
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),

                    width: 320,
                    height: 400,

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(160),

                      border: Border.all(
                        color: faceInsideGuide
                            ? Colors.greenAccent
                            : Colors.blueAccent,
                        width: 5,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: faceInsideGuide
                              ? Colors.greenAccent
                                  .withOpacity(.25)
                              : Colors.blueAccent
                                  .withOpacity(.20),
                          blurRadius: 25,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP INDICATOR
                Positioned(
                  top: 105,
                  left: 35,
                  right: 35,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      _stepCircle(
                        '1',
                        done: step >= 2,
                        current: step == 1,
                      ),
                      _stepLine(step >= 2),
                      _stepCircle(
                        '2',
                        done: step >= 3,
                        current: step == 2,
                      ),
                      _stepLine(step >= 3),
                      _stepCircle(
                        '3',
                        done: blinkDetected,
                        current: step == 3,
                      ),
                    ],
                  ),
                ),

                // STATUS CARD
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 25,
                  child: Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: const Color(0xff101827)
                          .withOpacity(.96),

                      borderRadius:
                          BorderRadius.circular(20),

                      border: Border.all(
                        color: faceInsideGuide
                            ? Colors.greenAccent
                                .withOpacity(.40)
                            : Colors.blueAccent
                                .withOpacity(.35),
                      ),
                    ),

                    child: Row(
                      children: [

                        Icon(
                          step >= 4
                              ? Icons.verified_user
                              : Icons.face,
                          color: step >= 4
                              ? Colors.greenAccent
                              : Colors.blueAccent,
                          size: 30,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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

  Widget _stepCircle(
    String number,
    {
    required bool done,
    required bool current,
  }) {
    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 200),

      width: 38,
      height: 38,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: done
            ? Colors.greenAccent
            : current
                ? Colors.blueAccent
                : Colors.white12,
      ),

      child: Center(
        child: Text(
          done ? '✓' : number,
          style: TextStyle(
            color: done
                ? Colors.black
                : current
                    ? Colors.white
                    : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 200),

      width: 45,
      height: 3,

      color: active
          ? Colors.greenAccent
          : Colors.white12,
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

          const SizedBox(height: 22),

          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

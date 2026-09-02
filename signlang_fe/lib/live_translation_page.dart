import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class LiveTranslationPage extends StatefulWidget {
  const LiveTranslationPage({super.key});

  @override
  State<LiveTranslationPage> createState() => _LiveTranslationPageState();
}

class _LiveTranslationPageState extends State<LiveTranslationPage> {
  static bool _viewRegistered = false;
  static web.HTMLVideoElement? _videoElement;

  web.MediaStream? _stream;

  Timer? _predictionTimer;

  bool _cameraStarted = false;
  bool _loading = false;
  bool _isSendingFrame = false;

  String? _error;

  String _prediction = 'Waiting for translation...';
  double _confidence = 0.0;
  bool _handDetected = false;

  static const String backendUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    // Create the video element immediately.
    _videoElement ??= web.HTMLVideoElement();

    _videoElement!.autoplay = true;
    _videoElement!.muted = true;
    _videoElement!.playsInline = true;

    _videoElement!.style.width = '100%';
    _videoElement!.style.height = '100%';
    _videoElement!.style.objectFit = 'cover';
    _videoElement!.style.display = 'block';
    _videoElement!.style.backgroundColor = '#111827';

    _registerVideoView();
  }

  void _registerVideoView() {
    if (_viewRegistered) return;

    ui_web.platformViewRegistry.registerViewFactory(
      'mutemate-camera',
      (int viewId) {
        return _videoElement!;
      },
    );

    _viewRegistered = true;
  }

  // ============================================================
  // START CAMERA
  // ============================================================

  Future<void> _startCamera() async {
    setState(() {
      _loading = true;
      _error = null;
      _prediction = 'Starting camera...';
      _confidence = 0.0;
      _handDetected = false;
    });

    try {
      final video = _videoElement;

      if (video == null) {
        throw Exception(
          'Camera video element could not be created.',
        );
      }

      debugPrint('📷 Requesting camera access...');

      final constraints = web.MediaStreamConstraints(
        video: true.toJS,
        audio: false.toJS,
      );

      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      debugPrint('✅ Camera permission granted.');
      debugPrint('✅ Camera stream received.');

      _stream = stream;

      video.srcObject = stream;

      debugPrint('✅ Camera stream attached.');

      await video.play().toDart;

      debugPrint('✅ Camera video playing.');

      if (!mounted) return;

      setState(() {
        _cameraStarted = true;
        _loading = false;
        _error = null;
        _prediction = 'Show your hand to the camera';
      });

      // Start AI prediction.
      _startPredictionLoop();

    } catch (e) {
      debugPrint('❌ CAMERA ERROR: $e');

      _stopStreamOnly();

      if (!mounted) return;

      setState(() {
        _cameraStarted = false;
        _loading = false;
        _error = 'Camera error: $e';
      });
    }
  }

  // ============================================================
  // PREDICTION LOOP
  // ============================================================

  void _startPredictionLoop() {
    _predictionTimer?.cancel();

    debugPrint('🤖 Starting prediction loop...');

    _predictionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        _sendFrameForPrediction();
      },
    );
  }

  void _stopPredictionLoop() {
    _predictionTimer?.cancel();
    _predictionTimer = null;

    debugPrint('🛑 Prediction loop stopped.');
  }

  // ============================================================
  // CAPTURE + SEND FRAME
  // ============================================================

  Future<void> _sendFrameForPrediction() async {
    if (!_cameraStarted) {
      return;
    }

    if (_isSendingFrame) {
      return;
    }

    final video = _videoElement;

    if (video == null) {
      debugPrint('❌ Video element is null.');

      if (mounted) {
        setState(() {
          _error = 'Video element is not available.';
        });
      }

      return;
    }

    final videoWidth = video.videoWidth;
    final videoHeight = video.videoHeight;

    debugPrint(
      '📸 Capturing frame: ${videoWidth}x$videoHeight',
    );

    if (videoWidth == 0 || videoHeight == 0) {
      debugPrint('❌ Video dimensions are 0.');

      if (mounted) {
        setState(() {
          _error =
              'Camera is running, but video is not ready.';
        });
      }

      return;
    }

    _isSendingFrame = true;

    try {
      // --------------------------------------------------------
      // CREATE CANVAS
      // --------------------------------------------------------

      final canvas = web.HTMLCanvasElement();

      canvas.width = 640;
      canvas.height = 480;

      final context =
          canvas.getContext('2d')
              as web.CanvasRenderingContext2D;

      debugPrint('🎨 Canvas created.');

      // --------------------------------------------------------
      // COPY CAMERA FRAME TO CANVAS
      // --------------------------------------------------------

      context.drawImage(
        video,
        0,
        0,
        640,
        480,
      );

      debugPrint(
        '🖼️ Camera frame copied to canvas.',
      );

      // --------------------------------------------------------
      // CONVERT TO JPEG
      // --------------------------------------------------------

      final dataUrl = canvas.toDataURL(
        'image/jpeg',
        0.7.toJS,
      );

      debugPrint(
        '📦 Frame converted to JPEG.',
      );

      final base64Data = dataUrl.split(',').last;

      final imageBytes = base64Decode(base64Data);

      debugPrint(
        '📏 Frame size: ${imageBytes.length} bytes',
      );

      // --------------------------------------------------------
      // SEND TO FLASK
      // --------------------------------------------------------

      final url = Uri.parse(
        '$backendUrl/predict_frame',
      );

      debugPrint(
        '📤 Sending frame to Flask...',
      );

      final request = http.MultipartRequest(
        'POST',
        url,
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'frame',
          imageBytes,
          filename: 'frame.jpg',
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        '📥 Flask response: ${response.statusCode}',
      );

      debugPrint(
        '📥 Flask body: ${response.body}',
      );

      // --------------------------------------------------------
      // HANDLE ERROR
      // --------------------------------------------------------

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error =
                'Flask returned ${response.statusCode}';
          });
        }

        return;
      }

      // --------------------------------------------------------
      // DECODE RESPONSE
      // --------------------------------------------------------

      final data = jsonDecode(response.body);

      final prediction =
          data['prediction']?.toString();

      final confidence =
          (data['confidence'] as num?)
              ?.toDouble() ??
          0.0;

      final handDetected =
          data['hand_detected'] == true;

      debugPrint(
        '🤖 Prediction: $prediction',
      );

      debugPrint(
        '✋ Hand detected: $handDetected',
      );

      debugPrint(
        '🎯 Confidence: '
        '${(confidence * 100).toStringAsFixed(1)}%',
      );

      if (!mounted) return;

      setState(() {
        _prediction = prediction ??
            (handDetected
                ? 'Unknown'
                : 'Show your hand to the camera');

        _confidence = confidence;
        _handDetected = handDetected;

        _error = null;
      });

    } catch (e) {
      debugPrint(
        '❌ FRAME PREDICTION ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _error = 'Prediction error: $e';
        });
      }

    } finally {
      _isSendingFrame = false;
    }
  }

  // ============================================================
  // STOP CAMERA
  // ============================================================

  void _stopStreamOnly() {
    _stopPredictionLoop();

    final stream = _stream;

    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
    }

    _stream = null;

    final video = _videoElement;

    if (video != null) {
      video.srcObject = null;
    }
  }

  void _stopCamera() {
    _stopStreamOnly();

    if (!mounted) return;

    setState(() {
      _cameraStarted = false;
      _loading = false;
      _error = null;

      _prediction = 'Waiting for translation...';
      _confidence = 0.0;
      _handDetected = false;
    });
  }

  @override
  void dispose() {
    _stopStreamOnly();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF151922),
        elevation: 0,

        title: const Text(
          'Live Translation',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 950,
            ),

            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24,
              ),

              child: Column(
                children: [
                  _buildHeader(),

                  const SizedBox(height: 24),

                  Expanded(
                    child: _buildCameraCard(),
                  ),

                  const SizedBox(height: 20),

                  _buildTranslationCard(),

                  const SizedBox(height: 18),

                  _buildCameraButton(),

                  if (_error != null) ...[
                    const SizedBox(height: 12),

                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFDC3545),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Live Sign Translation',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF151922),
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Show your sign to the camera and MuteMate '
          'will translate it in real time.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CAMERA CARD
  // ============================================================

  Widget _buildCameraCard() {
    return Container(
      width: double.infinity,

      constraints: const BoxConstraints(
        minHeight: 280,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(26),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Stack(
        children: [
          if (_cameraStarted)
            const Positioned.fill(
              child: HtmlElementView(
                viewType: 'mutemate-camera',
              ),
            )
          else
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.videocam_outlined,
                  color: Colors.white38,
                  size: 72,
                ),
              ),
            ),

          if (!_cameraStarted && !_loading)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 30,

              child: Column(
                children: [
                  Text(
                    'Camera is off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Open the camera to start translating',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          if (_cameraStarted)
            Positioned(
              top: 18,
              left: 18,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),

                child: const Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.red,
                      size: 9,
                    ),

                    SizedBox(width: 7),

                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66111827),

                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // TRANSLATION CARD
  // ============================================================

  Widget _buildTranslationCard() {
    final hasPrediction =
        _handDetected &&
        _prediction.isNotEmpty &&
        _prediction != 'Unknown';

    String statusText;

    if (!_cameraStarted) {
      statusText = 'Waiting for translation...';
    } else if (!_handDetected) {
      statusText = 'Show your hand to the camera';
    } else {
      statusText = _prediction;
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 18,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED)
                  .withValues(alpha: 0.1),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.translate_rounded,
              color: Color(0xFF7C3AED),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Detected Sign',

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  statusText,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF151922),
                  ),
                ),

                if (hasPrediction) ...[
                  const SizedBox(height: 4),

                  Text(
                    'Confidence: '
                    '${(_confidence * 100).toStringAsFixed(1)}%',

                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (_cameraStarted)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color: hasPrediction
                    ? const Color(0xFF00A86B)
                        .withValues(alpha: 0.1)
                    : const Color(0xFF7C3AED)
                        .withValues(alpha: 0.1),

                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                hasPrediction
                    ? 'DETECTED'
                    : 'SCANNING',

                style: TextStyle(
                  color: hasPrediction
                      ? const Color(0xFF008A58)
                      : const Color(0xFF7C3AED),

                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMERA BUTTON
  // ============================================================

  Widget _buildCameraButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,

      child: ElevatedButton.icon(
        onPressed: _loading
            ? null
            : (_cameraStarted
                ? _stopCamera
                : _startCamera),

        icon: Icon(
          _cameraStarted
              ? Icons.stop_circle_outlined
              : Icons.videocam_outlined,
        ),

        label: Text(
          _cameraStarted
              ? 'Stop Camera'
              : 'Open Camera',
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: _cameraStarted
              ? const Color(0xFFDC3545)
              : const Color(0xFF7C3AED),

          foregroundColor: Colors.white,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
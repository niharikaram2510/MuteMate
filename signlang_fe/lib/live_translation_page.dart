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
  bool _isSpeaking = false;

  String? _error;

  String _prediction = 'Waiting for translation...';
  double _confidence = 0.0;
  bool _handDetected = false;

  static const String backendUrl = 'http://127.0.0.1:5000';

  @override
  void initState() {
    super.initState();

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

    ui_web.platformViewRegistry.registerViewFactory('mutemate-camera', (
      int viewId,
    ) {
      return _videoElement!;
    });

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
        throw Exception('Camera video element could not be created.');
      }

      final constraints = web.MediaStreamConstraints(
        video: true.toJS,
        audio: false.toJS,
      );

      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      _stream = stream;

      video.srcObject = stream;

      await video.play().toDart;

      if (!mounted) return;

      setState(() {
        _cameraStarted = true;
        _loading = false;
        _error = null;
        _prediction = 'Show your hand';
      });

      _startPredictionLoop();
    } catch (e) {
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

    _predictionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _sendFrameForPrediction();
    });
  }

  void _stopPredictionLoop() {
    _predictionTimer?.cancel();
    _predictionTimer = null;
  }

  // ============================================================
  // CAPTURE + SEND FRAME
  // ============================================================

  Future<void> _sendFrameForPrediction() async {
    if (!_cameraStarted) return;
    if (_isSendingFrame) return;

    final video = _videoElement;

    if (video == null) {
      if (mounted) {
        setState(() {
          _error = 'Video element is not available.';
        });
      }
      return;
    }

    final videoWidth = video.videoWidth;
    final videoHeight = video.videoHeight;

    if (videoWidth == 0 || videoHeight == 0) {
      if (mounted) {
        setState(() {
          _error = 'Camera is not ready yet.';
        });
      }
      return;
    }

    _isSendingFrame = true;

    try {
      final canvas = web.HTMLCanvasElement();

      canvas.width = 640;
      canvas.height = 480;

      final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;

      context.drawImage(video, 0, 0, 640, 480);

      final dataUrl = canvas.toDataURL('image/jpeg', 0.7.toJS);

      final base64Data = dataUrl.split(',').last;

      final imageBytes = base64Decode(base64Data);

      final url = Uri.parse('$backendUrl/predict_frame');

      final request = http.MultipartRequest('POST', url);

      request.files.add(
        http.MultipartFile.fromBytes(
          'frame',
          imageBytes,
          filename: 'frame.jpg',
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _error = 'Flask returned ${response.statusCode}';
          });
        }
        return;
      }

      final data = jsonDecode(response.body);

      final prediction = data['prediction']?.toString();

      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

      final handDetected = data['hand_detected'] == true;

      if (!mounted) return;

      setState(() {
        _prediction =
            prediction ?? (handDetected ? 'Unknown' : 'Show your hand');

        _confidence = confidence;
        _handDetected = handDetected;

        _error = null;
      });
    } catch (e) {
      if (mounted && _cameraStarted) {
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
    _stopSpeech();
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

  // ============================================================
  // VOICE OUTPUT
  // ============================================================

  void _speakPrediction() {
    if (!_handDetected) return;

    final detected = _prediction.trim();

    if (detected.isEmpty || detected == 'Unknown') return;

    final speechText = _speechTextForSign(detected);

    // Stop any previous speech first.
    web.window.speechSynthesis.cancel();

    final utterance = web.SpeechSynthesisUtterance(speechText);

    utterance.lang = 'en-US';

    // Slightly slower so short signs/letters are clearer.
    utterance.rate = 0.72;
    utterance.pitch = 1.0;

    utterance.onend = ((web.Event event) {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    }).toJS;

    utterance.onerror = ((web.Event event) {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    }).toJS;

    setState(() {
      _isSpeaking = true;
    });

    web.window.speechSynthesis.speak(utterance);
  }

  String _speechTextForSign(String sign) {
    const letters = {
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    };

    if (letters.contains(sign.toUpperCase())) {
      return 'Letter ${sign.toUpperCase()}';
    }

    if (sign == 'I LOVE YOU') {
      return 'I love you';
    }

    if (sign == 'HOW ARE YOU') {
      return 'How are you';
    }

    if (sign == 'THANK YOU') {
      return 'Thank you';
    }

    if (sign == 'WELCOME') {
      return 'Welcome';
    }

    if (sign == 'SORRY') {
      return 'Sorry';
    }

    return sign;
  }

  void _stopSpeech() {
    web.window.speechSynthesis.cancel();

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
    });
  }

  void _toggleSpeech() {
    if (_isSpeaking) {
      _stopSpeech();
    } else {
      _speakPrediction();
    }
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
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),

            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,

                  decoration: BoxDecoration(
                    color: _cameraStarted
                        ? const Color(0xFF00A86B)
                        : const Color(0xFF9CA3AF),

                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 7),

                Text(
                  _cameraStarted ? 'Camera Ready' : 'Camera Off',

                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    // ==================================================
                    // CAMERA - 50%
                    // ==================================================
                    Expanded(flex: 1, child: _buildCameraPanel()),

                    const SizedBox(width: 24),

                    // ==================================================
                    // TRANSLATION - 50%
                    // ==================================================
                    Expanded(flex: 1, child: _buildTranslationPanel()),
                  ],
                ),
              ),

              if (_error != null && _cameraStarted) ...[
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
    );
  }

  // ============================================================
  // CAMERA PANEL
  // ============================================================

  Widget _buildCameraPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),

        borderRadius: BorderRadius.circular(24),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Stack(
        children: [
          if (_cameraStarted)
            const Positioned.fill(
              child: HtmlElementView(viewType: 'mutemate-camera'),
            )
          else
            Positioned.fill(child: _buildCameraOffState()),

          // LIVE indicator
          if (_cameraStarted)
            Positioned(
              top: 16,
              left: 16,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFFFF4D4D), size: 8),

                    SizedBox(width: 7),

                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // STOP CAMERA button
          if (_cameraStarted)
            Positioned(
              right: 16,
              bottom: 16,

              child: SizedBox(
                width: 48,
                height: 48,

                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(14),

                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),

                    onTap: _stopCamera,

                    child: const Icon(
                      Icons.stop_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66111827),

                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMERA OFF STATE
  // ============================================================

  Widget _buildCameraOffState() {
    return Container(
      color: const Color(0xFF111827),

      child: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            top: -80,
            right: -80,

            child: Container(
              width: 220,
              height: 220,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -80,

            child: Container(
              width: 240,
              height: 240,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.04),
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  // Camera icon
                  Container(
                    width: 78,
                    height: 78,

                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.14),

                      shape: BoxShape.circle,

                      border: Border.all(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.35),

                        width: 1.5,
                      ),
                    ),

                    child: const Icon(
                      Icons.videocam_outlined,
                      color: Color(0xFFB794F4),
                      size: 34,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Camera is Off',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Start the camera to begin\nlive sign translation.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // MAIN OPEN CAMERA BUTTON
                  SizedBox(
                    width: 220,
                    height: 52,

                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _startCamera,

                      icon: const Icon(Icons.videocam_outlined, size: 21),

                      label: const Text('Open Camera'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),

                        foregroundColor: Colors.white,

                        disabledBackgroundColor: const Color(0xFF4B5563),

                        elevation: 4,

                        shadowColor: const Color(
                          0xFF7C3AED,
                        ).withValues(alpha: 0.4),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),

                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // FEATURES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      _buildCameraFeature(Icons.radar_outlined, 'Real-time'),

                      _buildFeatureDivider(),

                      _buildCameraFeature(
                        Icons.auto_awesome_outlined,
                        'AI Detection',
                      ),

                      _buildFeatureDivider(),

                      _buildCameraFeature(Icons.volume_up_outlined, 'Voice'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeature(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9B6BFF), size: 22),

          const SizedBox(height: 7),

          Text(
            text,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDivider() {
    return Container(width: 1, height: 34, color: Colors.white12);
  }

  // ============================================================
  // TRANSLATION PANEL
  // ============================================================

  Widget _buildTranslationPanel() {
    final percentage = (_confidence * 100).clamp(0.0, 100.0);

    final hasPrediction =
        _cameraStarted &&
        _handDetected &&
        _prediction.isNotEmpty &&
        _prediction != 'Unknown';

    return Container(
      padding: const EdgeInsets.all(34),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: const Color(0xFFE5E7EB)),

        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ========================================================
          // TITLE
          // ========================================================
          const Text(
            'DETECTED SIGN',

            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C3AED),
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 18),

          // ========================================================
          // MAIN SIGN
          // ========================================================
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    hasPrediction
                        ? _prediction
                        : _cameraStarted
                        ? 'Show your hand'
                        : '—',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: hasPrediction ? 56 : 30,

                      fontWeight: FontWeight.w800,

                      color: hasPrediction
                          ? const Color(0xFF151922)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),

                  if (hasPrediction) ...[
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFF00A86B).withValues(alpha: 0.1),

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: const Text(
                        'SIGN DETECTED',

                        style: TextStyle(
                          color: Color(0xFF008A58),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ========================================================
          // CONFIDENCE
          // ========================================================
          _buildConfidenceSection(percentage, hasPrediction),

          const SizedBox(height: 26),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          const SizedBox(height: 22),

          // ========================================================
          // RECOGNITION DETAILS
          // ========================================================
          const Text(
            'RECOGNITION DETAILS',

            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 16),

          _buildDetailRow(
            Icons.pan_tool_outlined,
            'Hand detected',
            _handDetected ? 'Yes' : 'No',
            _handDetected,
          ),

          const SizedBox(height: 12),

          _buildDetailRow(
            Icons.memory_outlined,
            'Model status',
            hasPrediction ? 'Stable' : 'Waiting',
            hasPrediction,
          ),

          const SizedBox(height: 12),

          _buildDetailRow(
            Icons.speed_outlined,
            'Confidence',
            hasPrediction ? '${percentage.toStringAsFixed(1)}%' : '—',
            hasPrediction,
          ),

          const SizedBox(height: 28),

          // ========================================================
          // ACTIONS
          // ========================================================
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,

                  child: ElevatedButton.icon(
                    onPressed: hasPrediction ? _toggleSpeech : null,

                    icon: Icon(
                      _isSpeaking
                          ? Icons.stop_rounded
                          : Icons.volume_up_outlined,
                      size: 21,
                    ),

                    label: Text(
                      _isSpeaking ? 'Speaking...  Stop' : 'Speak Sign',
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSpeaking
                          ? const Color(0xFF5B21B6)
                          : const Color(0xFF7C3AED),

                      foregroundColor: Colors.white,

                      disabledBackgroundColor: const Color(0xFFE5E7EB),

                      disabledForegroundColor: const Color(0xFF9CA3AF),

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),

                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 56,
                height: 56,

                child: OutlinedButton(
                  onPressed: _cameraStarted ? _stopCamera : _startCamera,

                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF151922),

                    side: const BorderSide(color: Color(0xFFD1D5DB)),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),

                    padding: EdgeInsets.zero,
                  ),

                  child: Icon(
                    _cameraStarted
                        ? Icons.stop_rounded
                        : Icons.videocam_outlined,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIDENCE SECTION
  // ============================================================

  Widget _buildConfidenceSection(double percentage, bool hasPrediction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            const Text(
              'CONFIDENCE',

              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
                letterSpacing: 1,
              ),
            ),

            Text(
              hasPrediction ? '${percentage.toStringAsFixed(1)}%' : '—',

              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF151922),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),

          child: LinearProgressIndicator(
            value: hasPrediction ? percentage / 100 : 0,

            minHeight: 8,

            backgroundColor: const Color(0xFFEDEEF2),

            valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value,
    bool active,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: active ? const Color(0xFF7C3AED) : const Color(0xFF9CA3AF),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,

            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),

        Text(
          value,

          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF151922) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    web.window.speechSynthesis.cancel();
    _stopStreamOnly();
    super.dispose();
  }
}

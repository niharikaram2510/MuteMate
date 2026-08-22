import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'loginpage.dart';
import 'splash_screen.dart';
import 'settings.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign Language Translator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  String? _translatedText;
  html.File? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;

  bool get _isImage {
    final name = _selectedFile?.name.toLowerCase() ?? '';
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif');
  }

  void pickFile() {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*,video/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _selectedFile = files.first;
          _translatedText = null;
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> uploadAndTranslate() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _translatedText = null;
    });

    try {
      final uri = Uri.parse('http://127.0.0.1:5000/translate');
      final request = http.MultipartRequest('POST', uri);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(_selectedFile!);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: _selectedFile!.name,
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(respStr);
        setState(() {
          _translatedText = decoded['translation'] ?? 'No text found';
        });
      } else {
        setState(() {
          _errorMessage = 'Server error (${response.statusCode}). Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach the translation server.';
      });
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sign Language Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildUploadCard(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_selectedFile == null || _isUploading) ? null : uploadAndTranslate,
                  icon: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.translate_rounded),
                  label: Text(_isUploading ? 'Translating...' : 'Translate'),
                ),
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) _buildErrorCard(),
              if (_translatedText != null) _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppTheme.softShadow()],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _selectedFile == null
                  ? Icons.cloud_upload_outlined
                  : (_isImage ? Icons.image_outlined : Icons.videocam_outlined),
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _selectedFile?.name ?? 'No file selected',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedFile == null
                ? 'Upload a short video or image of a sign'
                : '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Choose Video or Image'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow()],
        border: Border.all(color: AppTheme.success.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Translation',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _translatedText ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
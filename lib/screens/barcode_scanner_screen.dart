import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/api_constants.dart';
import '../models/biblio.dart';
import '../services/biblio_service.dart';
import '../services/mock_biblio_service.dart';

/// Scans a book's ISBN barcode with the camera and looks it up in the
/// catalog — a mobile-native shortcut the real OPAC website has no
/// equivalent for. Pops with the matching [Biblio] on success, or
/// nothing if the user backs out.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final BiblioSource _biblioService =
      ApiConstants.useMockKohaBackend ? MockBiblioService() : BiblioService();

  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Looking up $code...';
    });
    unawaited(_controller.stop());

    try {
      final results = await _biblioService.search(code.trim(), searchField: 'nb');
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _statusMessage = 'No book found for "$code" — try again.';
          _isProcessing = false;
        });
        unawaited(_controller.start());
      } else {
        Navigator.of(context).pop(results.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = e.toString();
        _isProcessing = false;
      });
      unawaited(_controller.start());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan a Book Barcode'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing) const CircularProgressIndicator(color: Colors.white),
          if (_statusMessage != null)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

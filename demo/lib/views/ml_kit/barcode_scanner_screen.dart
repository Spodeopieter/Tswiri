import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/views/ml_kit/camera_views/barcode_scanner_camera_view.dart';
import 'package:tswiri/views/ml_kit/painters/barcode_scanner_painter.dart';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  final List<BarcodeFormat> formats;

  const BarcodeScannerScreen({
    super.key,
    this.formats = const [BarcodeFormat.all],
  });

  @override
  AbstractScreen<BarcodeScannerScreen> createState() =>
      _BarcodeSelectorScreenState();
}

class _BarcodeSelectorScreenState extends AbstractScreen<BarcodeScannerScreen> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.all],
  );

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.back;

  final Set<String> _scannedBarcodes = {};

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerCamera(
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      numberOfScannedBarcodes: _scannedBarcodes.length,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _scannedBarcodes);
        },
        label: const Text('Done'),
        icon: const Icon(Icons.qr_code_scanner_rounded),
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final barcodes = await _barcodeScanner.processImage(inputImage);

    final validImage = inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null;

    if (validImage) {
      final painter = BarcodeScannerPainter(
        barcodes: barcodes,
        imageSize: inputImage.metadata!.size,
        rotation: inputImage.metadata!.rotation,
        cameraLensDirection: _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);

      for (var barcode in barcodes) {
        final displayValue = barcode.displayValue;
        if (displayValue == null) continue;
        _scannedBarcodes.add(displayValue);
      }
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/views/ml_kit/camera_views/barcode_selector_camera_view.dart';
import 'package:tswiri/views/ml_kit/painters/barcode_selector_painter.dart';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeSelectorScreen extends ConsumerStatefulWidget {
  final List<BarcodeFormat> formats;

  const BarcodeSelectorScreen({
    super.key,
    this.formats = const [BarcodeFormat.all],
  });

  @override
  AbstractScreen<BarcodeSelectorScreen> createState() =>
      _BarcodeSelectorScreenState();
}

class _BarcodeSelectorScreenState
    extends AbstractScreen<BarcodeSelectorScreen> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.all],
  );

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.back;

  String? _barcodeUUID;
  int? _timestamp;
  bool _isAutoSelecting = false;

  final int _timeToAutoSelect = 2000;

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionButton = _barcodeUUID == null
        ? null
        : FloatingActionButton.extended(
            onPressed: () {
              Navigator.pop(context, _barcodeUUID);
            },
            label: const Text('Select'),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          );

    return BarcodeSelectorCamera(
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      floatingActionButton: actionButton,
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
      final painter = BarcodeSelectorPainter(
        barcodes: barcodes,
        imageSize: inputImage.metadata!.size,
        rotation: inputImage.metadata!.rotation,
        cameraLensDirection: _cameraLensDirection,
        callback: autoSelect,
      );
      _customPaint = CustomPaint(painter: painter);
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void autoSelect(String? barcodeUUID) async {
    if (_isAutoSelecting) return;
    _isAutoSelecting = true;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (barcodeUUID == null) {
      _timestamp = null;
      _barcodeUUID = null;
      _isAutoSelecting = false;
      return;
    }

    if (!mounted) return;

    if (_timestamp == null || _barcodeUUID == null) {
      _timestamp = now;
      _barcodeUUID = barcodeUUID;
    } else if (_barcodeUUID != barcodeUUID) {
      _barcodeUUID = barcodeUUID;
      _timestamp = now;
    } else if ((_timestamp! + _timeToAutoSelect) <= now &&
        _barcodeUUID == barcodeUUID) {
      HapticFeedback.lightImpact();

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 10)).then(
          (value) => Navigator.pop(context, _barcodeUUID),
        );
        return;
      }
    }

    _isAutoSelecting = false;
  }
}

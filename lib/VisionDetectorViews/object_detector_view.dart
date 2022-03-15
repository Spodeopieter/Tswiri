import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import 'camera_view.dart';
import 'painters/object_detector_painter.dart';

class ObjectDetectorViewML extends StatefulWidget {
  const ObjectDetectorViewML({Key? key}) : super(key: key);

  @override
  _ObjectDetectorViewML createState() => _ObjectDetectorViewML();
}

class _ObjectDetectorViewML extends State<ObjectDetectorViewML> {
  LocalModel model = LocalModel("object_labeler.tflite");
  RemoteModel model1 = RemoteModel('object_labeler.tflite');

  late ObjectDetector objectDetector;

  @override
  void initState() {
    objectDetector = GoogleMlKit.vision.objectDetector(
        CustomObjectDetectorOptions(model,
            trackMutipleObjects: true, classifyObjects: false));

    super.initState();
  }

  bool isBusy = false;
  CustomPaint? customPaint;

  @override
  void dispose() {
    objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Object Detector',
      customPaint: customPaint,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.back,
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final result = await objectDetector.processImage(inputImage);
    //print(result);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null &&
        result.isNotEmpty) {
      final painter = ObjectDetectorPainterML(
          result,
          inputImage.inputImageData!.imageRotation,
          inputImage.inputImageData!.size);
      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}

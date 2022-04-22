import 'package:flutter_google_ml_kit/functions/math_functionts/round_to_double.dart';
import 'package:flutter_google_ml_kit/objects/reworked/on_image_data.dart';
import 'package:flutter_google_ml_kit/objects/reworked/on_image_inter_barcode_data.dart';
import 'package:flutter_google_ml_kit/objects/reworked/real_inter_barcode_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_ml_kit/global_values/global_colours.dart';
import 'package:flutter_google_ml_kit/functions/isar_functions/isar_functions.dart';
import 'package:flutter_google_ml_kit/isar_database/real_interbarcode_vector_entry/real_interbarcode_vector_entry.dart';
import 'package:isar/isar.dart';

class BarcodePositionScannerProcessingView extends StatefulWidget {
  const BarcodePositionScannerProcessingView({
    Key? key,
    required this.barcodeDataBatches,
    required this.parentContainerUID,
    required this.barcodesToScan,
    required this.gridMarkers,
  }) : super(key: key);

  final List barcodeDataBatches;

  final String parentContainerUID;
  final List<String> barcodesToScan;
  final List<String> gridMarkers;
  @override
  _BarcodePositionScannerProcessingViewState createState() =>
      _BarcodePositionScannerProcessingViewState();
}

class _BarcodePositionScannerProcessingViewState
    extends State<BarcodePositionScannerProcessingView> {
  late Future<List<RealInterBarcodeData>> _future;

  @override
  void initState() {
    _future = processData(barcodeDataBatches: widget.barcodeDataBatches);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _continueToVisualizer(),
          ],
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Processing Data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: FutureBuilder<List<RealInterBarcodeData>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return listView(snapshot.data!);
            } else if (snapshot.hasError) {
              return Text(
                "${snapshot.error}",
                style: const TextStyle(fontSize: 20, color: deeperOrange),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  Widget listView(List<RealInterBarcodeData> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return interBarcodeDataWidget(data[index]);
      },
    );
  }

  Widget interBarcodeDataWidget(RealInterBarcodeData data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      color: Colors.white12,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: sunbirdOrange, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.startBarcodeUID + ' => ' + data.endBarcodeUID,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Divider(),
            Text(
              'X: ${roundDouble(data.vector3.x, 2)}mm,  Y: ${roundDouble(data.vector3.y, 2)}mm,  Z: ${roundDouble(data.vector3.z, 2)}mm',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          ],
        ),
      ),
    );
  }

  Widget _continueToVisualizer() {
    return FloatingActionButton(
      heroTag: null,
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Icon(Icons.check_circle_outline_rounded),
    );
  }

  ///1. Generate a list of OnImageInterBarcodeData from barcodeDataBatches.
  ///   i. Iterate through barcodeDataBatches.
  ///   ii. Iterate through the barcodeDataBatch and generate IsolateRawOnImageBarcodeData.
  ///   iii.Iterate through onImageBarcodeDataBatch.
  ///   iv. Create BarcodeDataPairs.
  ///
  ///2. Generate list of RealInterBarcodeData.
  ///   i. Iterate through onImageInterBarcodeData and generate IsolateRealInterBarcodeData.
  ///
  ///3. Remove outliers and calculate the average.
  ///   i. Generate list of unique RealInterBarcodeData.
  ///   ii. find similar RealInterbarcodeData.
  ///   iii. Sort similarInterBarcodeOffsets by the length of the vector.
  ///   iv. Remove any outliers.
  ///   v. Caluclate the average.
  ///   vi. Add to finalRealInterBarcodeData.
  ///
  ///4. Write to Isar.
  ///   i. Create RealInterBarcodeVectorEntrys.

  Future<List<RealInterBarcodeData>> processData({
    required List barcodeDataBatches,
  }) async {
    ///1. Generate a list of OnImageInterBarcodeData from barcodeDataBatches.
    List<OnImageInterBarcodeData> onImageInterBarcodeData = [];
    for (int i = 0; i < barcodeDataBatches.length; i++) {
      //i. Iterate through barcodeDataBatches.
      List barcodeDataBatch = barcodeDataBatches[i];
      List<OnImageBarcodeData> onImageBarcodeDataBatch = [];
      for (int x = 0; x < barcodeDataBatch.length; x++) {
        //ii. Iterate through the barcodeDataBatch and generate IsolateRawOnImageBarcodeData.
        onImageBarcodeDataBatch
            .add(OnImageBarcodeData.fromMessage(barcodeDataBatch[x]));
      }

      for (OnImageBarcodeData onImageBarcodeData in onImageBarcodeDataBatch) {
        //iii.Iterate through onImageBarcodeDataBatch.

        for (int z = 1; z < onImageBarcodeDataBatch.length; z++) {
          //iv. Create BarcodeDataPairs.
          if (onImageBarcodeData.barcodeUID !=
              onImageBarcodeDataBatch[z].barcodeUID) {
            onImageInterBarcodeData.add(
                OnImageInterBarcodeData.fromBarcodeDataPair(
                    onImageBarcodeData, onImageBarcodeDataBatch[z]));
          }
        }
      }
    }

    ///2. Generate list of RealInterBarcodeData.
    List<RealInterBarcodeData> realInterBarcodeData = [];
    for (OnImageInterBarcodeData interBarcodeData in onImageInterBarcodeData) {
      //i. Iterate through onImageInterBarcodeData and generate IsolateRealInterBarcodeData.
      realInterBarcodeData
          .add(RealInterBarcodeData.fromRawInterBarcodeData(interBarcodeData));
    }

    ///3. Remove outliers and calculate the average.
    //i. Generate list of unique RealInterBarcodeData.
    List<RealInterBarcodeData> uniqueRealInterBarcodeData =
        realInterBarcodeData.toSet().toList();

    List<RealInterBarcodeData> finalRealInterBarcodeData = [];
    for (RealInterBarcodeData uniqueRealInterBarcodeData
        in uniqueRealInterBarcodeData) {
      //ii. find similar realInterBarcodeData.
      List<RealInterBarcodeData> similarRealInterBarcodeData =
          realInterBarcodeData
              .where((element) => (element.startBarcodeUID ==
                      uniqueRealInterBarcodeData.startBarcodeUID &&
                  element.endBarcodeUID ==
                      uniqueRealInterBarcodeData.endBarcodeUID))
              .toList();

      //iii. Sort similarInterBarcodeOffsets by the length of the vector.
      similarRealInterBarcodeData
          .sort((a, b) => a.vector3.length.compareTo(b.vector3.length));

      //iv. Remove any outliers.
      //Indexes (Stats).
      int medianIndex = (similarRealInterBarcodeData.length ~/ 2);
      int quartile1Index = ((similarRealInterBarcodeData.length / 2) ~/ 2);
      int quartile3Index = medianIndex + quartile1Index;

      //Values of indexes.
      double median = similarRealInterBarcodeData[medianIndex].vector3.length;
      double quartile1 = calculateQuartileValue(
          similarRealInterBarcodeData, quartile1Index, median);
      double quartile3 = calculateQuartileValue(
          similarRealInterBarcodeData, quartile3Index, median);

      //Boundry calculations.
      double interQuartileRange = quartile3 - quartile1;
      double q1Boundry = quartile1 - interQuartileRange * 1.5; //Lower boundry
      double q3Boundry = quartile3 + interQuartileRange * 1.5; //Upper boundry

      //Remove data outside the boundries.
      similarRealInterBarcodeData.removeWhere((element) =>
          element.vector3.length <= q1Boundry &&
          element.vector3.length >= q3Boundry);

      //v. Caluclate the average.
      for (RealInterBarcodeData similarInterBarcodeOffset
          in similarRealInterBarcodeData) {
        //Average the similar interBarcodeData.
        uniqueRealInterBarcodeData.vector3.x =
            (uniqueRealInterBarcodeData.vector3.x +
                    similarInterBarcodeOffset.vector3.x) /
                2;
        uniqueRealInterBarcodeData.vector3.y =
            (uniqueRealInterBarcodeData.vector3.y +
                    similarInterBarcodeOffset.vector3.y) /
                2;
        uniqueRealInterBarcodeData.vector3.z =
            (uniqueRealInterBarcodeData.vector3.z +
                    similarInterBarcodeOffset.vector3.z) /
                2;
      }
      //vi. Add to finalRealInterBarcodeData.
      finalRealInterBarcodeData.add(uniqueRealInterBarcodeData);
    }

    ///4. Write to Isar.
    //i. Create RealInterBarcodeVectorEntrys.
    List<RealInterBarcodeVectorEntry> interbarcodeOffsetEntries = [];
    List<String> scannedBarcodes = [];
    int creation = DateTime.now().millisecondsSinceEpoch;
    for (RealInterBarcodeData realInterBarcodeData
        in finalRealInterBarcodeData) {
      RealInterBarcodeVectorEntry vectorEntry = RealInterBarcodeVectorEntry()
          .fromRealInterBarcodeData(realInterBarcodeData, creation);

      scannedBarcodes.add(realInterBarcodeData.startBarcodeUID);
      scannedBarcodes.add(realInterBarcodeData.endBarcodeUID);
      interbarcodeOffsetEntries.add(vectorEntry);
    }
    scannedBarcodes = scannedBarcodes.toSet().toList();

    for (String barcode in scannedBarcodes) {
      isarDatabase!.writeTxnSync((isar) => isar.realInterBarcodeVectorEntrys
          .filter()
          .startBarcodeUIDMatches(barcode)
          .or()
          .endBarcodeUIDMatches(barcode)
          .deleteAllSync());
    }

    isarDatabase!.writeTxnSync((isar) {
      isar.realInterBarcodeVectorEntrys.putAllSync(interbarcodeOffsetEntries);
    });

    return finalRealInterBarcodeData;
  }
}

//Calculates the quartile value.
double calculateQuartileValue(
    List<RealInterBarcodeData> similarInterBarcodeOffsets,
    int quartile1Index,
    double median) {
  return (similarInterBarcodeOffsets[quartile1Index].vector3.length + median) /
      2;
}

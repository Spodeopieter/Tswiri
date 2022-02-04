import 'package:flutter/material.dart';
import 'package:flutter_google_ml_kit/databaseAdapters/scanningAdapters/consolidated_data_adapter.dart';
import 'package:flutter_google_ml_kit/functions/mathfunctions/round_to_double.dart';
import 'package:flutter_google_ml_kit/globalValues/global_colours.dart';
import 'package:flutter_google_ml_kit/globalValues/global_hive_databases.dart';
import 'package:hive/hive.dart';

import 'barcode_navigator_view.dart';

class BarcodeSelectionView extends StatefulWidget {
  const BarcodeSelectionView({Key? key}) : super(key: key);

  @override
  _BarcodeSelectionViewState createState() => _BarcodeSelectionViewState();
}

class _BarcodeSelectionViewState extends State<BarcodeSelectionView> {
  List validQrcodeIDs = [];
  String selectedValue = '';
  final _formKey = GlobalKey<FormState>();
  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Qr Code Selector',
            style: TextStyle(fontSize: 25),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: null,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Valid'),
                        duration: Duration(milliseconds: 50),
                      ),
                    );

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BarcodeNavigatorView(
                                qrcodeID: myController.text)));
                  }
                },
                child: const Icon(
                  Icons.check_rounded,
                ),
              )
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: myController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                        color: Colors.white,
                      )),
                      contentPadding: EdgeInsets.all(5),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                        color: Colors.deepOrange,
                      )),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                        color: Colors.deepOrange,
                      )),
                      labelText: 'Enter Qrcode ID',
                      labelStyle: TextStyle(color: Colors.deepOrangeAccent)),
                  cursorColor: Colors.orangeAccent,
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  textAlign: TextAlign.center,
                  validator: (value) {
                    if (isNumeric(value.toString()) != true) {
                      return 'Please enter a valid ID';
                    } else if (validQrcodeIDs.contains(value) != true) {
                      return 'No Such ID';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List>(
                future: consolidateData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    List myList = snapshot.data ?? [];
                    return ListView.builder(
                        itemCount: myList.length,
                        itemBuilder: (context, index) {
                          var myText = myList[index]
                              .toString()
                              .replaceAll(RegExp(r'\[|\]'), '')
                              .replaceAll(' ', '')
                              .split(',')
                              .toList();
                          if (index == 0) {
                            return Column(
                              children: <Widget>[
                                displayDataPoint(['UID', 'X', 'Y', 'Fixed']),
                                const SizedBox(
                                  height: 5,
                                ),
                                displayDataPoint(myText),
                              ],
                            );
                          } else {
                            return displayDataPoint(myText);
                          }
                        });
                  }
                },
              ),
            ),
          ],
        ));
  }

  Future<List> consolidateData() async {
    var consolidatedDataBox = await Hive.openBox(realPositionDataBoxName);
    Map consolidatedDataMap = consolidatedDataBox.toMap();
    List displayList = [];
    consolidatedDataMap.forEach((key, value) {
      RealBarcodePostionEntry data = value;
      displayList.add([
        data.uid,
        roundDouble(data.offset.x, 10),
        roundDouble(data.offset.y, 10),
        data.fixed
      ]);
      validQrcodeIDs.add(key);
    });
    return displayList;
  }
}

bool isNumeric(String s) {
  // ignore: unnecessary_null_comparison
  if (s == null) {
    return false;
  }
  return int.tryParse(s) != null;
}

displayDataPoint(var myText) {
  return Container(
    decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: deepSpaceSparkle),
            top: BorderSide(color: deepSpaceSparkle),
            left: BorderSide(color: deepSpaceSparkle),
            right: BorderSide(color: deepSpaceSparkle))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.ltr,
      children: [
        Container(
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: deepSpaceSparkle))),
          child: SizedBox(
            child: Text(myText[0], textAlign: TextAlign.center),
            width: 50,
          ),
        ),
        Container(
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: deepSpaceSparkle))),
          child: SizedBox(
            child: Text(myText[1], textAlign: TextAlign.center),
            width: 140,
          ),
        ),
        Container(
          decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: deepSpaceSparkle))),
          child: SizedBox(
            child: Text(myText[2], textAlign: TextAlign.center),
            width: 140,
          ),
        ),
        SizedBox(
          child: Text(myText[3], textAlign: TextAlign.center),
          width: 50,
        ),
      ],
    ),
  );
}

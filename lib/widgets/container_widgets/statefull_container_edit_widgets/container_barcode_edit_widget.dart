import 'package:flutter/material.dart';
import 'package:flutter_google_ml_kit/isar/container_isar/container_isar.dart';
import 'package:flutter_google_ml_kit/sunbirdViews/barcode_scanning/barcode_value_scanning/single_barcode_scan_view.dart';
import 'package:flutter_google_ml_kit/widgets/basic_outline_containers/custom_outline_container.dart';
import 'package:flutter_google_ml_kit/widgets/basic_outline_containers/orange_outline_container.dart';
import 'package:isar/isar.dart';

import '../../basic_outline_containers/light_container.dart';

class ContainerBarcodeEiditWidget extends StatefulWidget {
  const ContainerBarcodeEiditWidget({
    Key? key,
    required this.containerUID,
    required this.database,
  }) : super(key: key);

  final String containerUID;
  final Isar database;

  @override
  State<ContainerBarcodeEiditWidget> createState() =>
      _ContainerBarcodeEiditWidgetState();
}

class _ContainerBarcodeEiditWidgetState
    extends State<ContainerBarcodeEiditWidget> {
  String? barcodeUID;
  ContainerEntry? containerEntry;
  Color outlineColor = Colors.white54;

  @override
  void initState() {
    containerEntry = widget.database.containerEntrys
        .filter()
        .containerUIDMatches(widget.containerUID)
        .findFirstSync();
    barcodeUID = containerEntry?.barcodeUID;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LightContainer(
      child: Builder(builder: (context) {
        if (containerEntry!.barcodeUID == null) {
          outlineColor = Colors.white54;
        } else {
          outlineColor = Colors.deepOrange;
        }
        return CustomOutlineContainer(
          outlineColor: outlineColor,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, right: 10, bottom: 5, top: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'barcodeUID',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      barcodeUID ?? "'",
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                    InkWell(
                      onTap: () async {
                        barcodeUID = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SingleBarcodeScanView(),
                          ),
                        );

                        if (barcodeUID == 'clear') {
                          //if user did not scan a barcode.

                          barcodeUID = "'";
                          containerEntry!.barcodeUID = null;
                          widget.database.writeTxnSync((isar) {
                            isar.containerEntrys.putSync(containerEntry!);
                          });
                          setState(() {});
                        } else if (barcodeUID == null) {
                          //if user pressed back do nothing.

                        } else if (barcodeUID != null) {
                          //If the user scanned a new barcode.
                          setState(() {});
                          containerEntry!.barcodeUID = barcodeUID;
                          widget.database.writeTxnSync((isar) {
                            isar.containerEntrys.putSync(containerEntry!);
                          });
                        }
                      },
                      child: OrangeOutlineContainer(
                          child: Text(
                        'scan',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      }),
    );
  }
}

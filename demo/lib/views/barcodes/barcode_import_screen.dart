import 'package:flutter/material.dart';
import 'package:tswiri/enumerations.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/widgets/barcode_batch_setup_widget.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';
import 'package:uuid/uuid.dart';

class BarcodeImportScreen extends ConsumerStatefulWidget {
  const BarcodeImportScreen({super.key});

  @override
  AbstractScreen<BarcodeImportScreen> createState() =>
      _BarcodeImportScreenState();
}

class _BarcodeImportScreenState extends AbstractScreen<BarcodeImportScreen> {
  bool _isBusy = false;

  final initialBarcodeSize = BarcodeSize.medium;
  late Size size = initialBarcodeSize.size;

  final Set<String> _validUUIDs = {};
  final Set<CatalogedBarcode> _invalidBarcodes = {};

  bool get _hasValidBarcodes => _validUUIDs.isNotEmpty;
  bool get _hasInvalidBarcodes => _invalidBarcodes.isNotEmpty;
  bool get _hasScannedBarcodes => _hasValidBarcodes || _hasInvalidBarcodes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Barcodes'),
        automaticallyImplyLeading: !_isBusy,
        actions: [
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ListTile(
                title: Text(
                  _hasScannedBarcodes ? 'Scan More' : 'Scan Barcodes',
                ),
                trailing: _isBusy
                    ? const CircularProgressIndicator.adaptive()
                    : FilledButton.tonalIcon(
                        onPressed: _scanBarcodes,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('scan'),
                      ),
              ),
              const Divider(),
              const ListTile(
                title: Text('Barcode Size'),
              ),
              BarcodeBatchSetupWidget(
                initialBarcodeSize: initialBarcodeSize,
                onBarcodeSizeChanged: (value) {
                  setState(() {
                    size = value;
                  });
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Valid Barcodes'),
                subtitle: Text('${_validUUIDs.length}'),
              ),
              if (_hasInvalidBarcodes)
                ListTile(
                  title: const Text('Invalid Barcodes'),
                  subtitle: Text('Remove: ${_invalidBarcodes.length} barcodes'),
                  trailing: _hasInvalidBarcodes
                      ? IconButton.filledTonal(
                          onPressed: () {
                            setState(() {
                              _invalidBarcodes.clear();
                            });
                          },
                          icon: const Icon(Icons.delete),
                        )
                      : null,
                ),
              const Divider(),
              FilledButton.tonalIcon(
                onPressed: _hasValidBarcodes && !_hasInvalidBarcodes
                    ? _importBarcodes
                    : null,
                icon: const Icon(Icons.add),
                label: const Text("Import"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _importBarcodes() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final batchUuid = const Uuid().v1();
    final width = size.width;
    final height = size.height;
    final amount = _validUUIDs.length;

    final barcodeBatch = BarcodeBatch()
      ..uuid = batchUuid
      ..amount = amount
      ..timestamp = timestamp
      ..width = width
      ..height = height
      ..imported = true;

    final importedBarcodes = _validUUIDs.map((e) {
      return CatalogedBarcode()
        ..barcodeUUID = e
        ..batchUUID = batchUuid
        ..height = size.height
        ..width = size.width;
    }).toList();

    db.writeTxnSync(() {
      db.barcodeBatchs.putSync(barcodeBatch);
      db.catalogedBarcodes.putAllSync(importedBarcodes);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imported'), showCloseIcon: true),
    );

    Navigator.of(context).pop();
  }

  void _scanBarcodes() async {
    final barcodeUUIDs = await Navigator.of(context).pushNamed(
      Routes.barcodeScanner,
    );

    if (barcodeUUIDs != null && barcodeUUIDs is Set<String>) {
      setState(() {
        _isBusy = true;
      });

      for (var uuid in barcodeUUIDs) {
        final barcode = space.getCatalogedBarcode(uuid);

        if (barcode == null) {
          _validUUIDs.add(uuid);
        } else {
          _invalidBarcodes.add(barcode);
        }
      }

      setState(() {
        _isBusy = false;
      });
    }
  }

  void _showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importing Barcodes'),
          content: const Text(
            'Scan barcodes by clicking the "Scan" button. \n\n'
            '- It is recommended that you scan barcodes with the same size',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }
}

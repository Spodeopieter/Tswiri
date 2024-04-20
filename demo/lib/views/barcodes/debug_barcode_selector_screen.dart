import 'package:flutter/material.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class DebugBarcodeSelectorScreen extends ConsumerStatefulWidget {
  const DebugBarcodeSelectorScreen({super.key});

  @override
  AbstractScreen<DebugBarcodeSelectorScreen> createState() =>
      _DebugBarcodeSelectorScreenState();
}

class _DebugBarcodeSelectorScreenState
    extends AbstractScreen<DebugBarcodeSelectorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Barcode Selector'),
      ),
      body: FutureBuilder(
        future: db.catalogedBarcodes.where().findAll(),
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              final linkedContainer = space.getCatalogedContainerSync(
                barcodeUUID: item.barcodeUUID,
              );

              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListBody(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.qr_code),
                      title: Text(item.barcodeUUID),
                    ),
                    ListTile(
                      leading: const Icon(Icons.account_tree_sharp),
                      title: Text(linkedContainer?.name.toString() ?? 'None'),
                      trailing: FilledButton.tonal(
                        onPressed: () {
                          Navigator.of(context).pop(item.barcodeUUID);
                        },
                        child: const Text('Select'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

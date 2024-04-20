import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri/settings/settings.dart';
import 'package:tswiri_database/collections/collections_export.dart';

import 'package:tswiri_database/space/space.dart';
export 'package:isar/isar.dart';

abstract class AbstractScreen<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  Settings get settings => ref.read(settingsProvider);

  /// The current space.
  Space get space => ref.read(spaceProvider);

  /// The Isar instance for the current space.
  Isar get db {
    assert(
      space.isLoaded,
      'Space is not loaded',
    );
    return space.db!;
  }

  /// Returns a list of all [CatalogedContainer]s.
  Future<List<CatalogedContainer>> get catalogedContainers {
    return db.catalogedContainers.where().findAll();
  }

  /// Returns a list of all [ContainerType]s.
  Future<List<ContainerType>> get containerTypes {
    return db.containerTypes.where().findAll();
  }

  Future<bool> showConfirmDialog({
    required String title,
    required String content,
    String negative = 'OK',
    String positive = 'Cancel',
  }) async {
    final value = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(negative),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(positive),
            ),
          ],
        );
      },
    );

    return value ?? false;
  }

  Future<void> showInfoDialog({
    required String title,
    required String content,
    String okText = 'Ok',
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(okText),
            ),
          ],
        );
      },
    );
  }

  void showSnackbar(String message, {bool showCloseIcon = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        showCloseIcon: showCloseIcon,
      ),
    );
  }

  /// Launch the barcode scanner.
  /// returns the barcodeUUID as [String].
  Future<String?> scanBarcode() async {
    // Check if the device has a camera.
    final hasCamera = ref.read(settingsProvider).deviceHasCameras;

    // Launch the scanner or debug selector.
    final barcodeUUID = await Navigator.pushNamed(
      context,
      hasCamera ? Routes.barcodeSelector : Routes.debugBarcodeSelector,
    );

    if (barcodeUUID == null) {
      showSnackbar('No barcode scanned');
      return null;
    }

    if (barcodeUUID is! String) {
      showSnackbar('Unknown error');
      return null;
    }

    return barcodeUUID;
  }
}

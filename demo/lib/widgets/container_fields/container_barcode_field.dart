import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/widgets/form_fields/barcode_form_field.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class ContainerBarcodeField extends ConsumerStatefulWidget {
  const ContainerBarcodeField({
    super.key,
    this.initialValue,
    this.currentBarcodeUUID,
    this.onSaved,
    this.canReset = false,
  });

  final CatalogedBarcode? initialValue;
  final String? currentBarcodeUUID;
  final Function(CatalogedBarcode?)? onSaved;
  final bool canReset;

  @override
  AbstractScreen<ContainerBarcodeField> createState() =>
      _ContainerBarcodeFieldState();
}

class _ContainerBarcodeFieldState
    extends AbstractScreen<ContainerBarcodeField> {
  @override
  Widget build(BuildContext context) {
    return BarcodeFormField(
      validator: (barcode) => barcodeValidator(
        barcode,
      ),
      decoration: const InputDecoration(
        labelText: 'Barcode',
        border: OutlineInputBorder(),
      ),
      onSaved: (barcode) {
        if (barcode == null) return;
        widget.onSaved?.call(barcode);
      },
      initialValue: widget.initialValue,
      canReset: widget.canReset,
    );
  }

  String? barcodeValidator(CatalogedBarcode? barcode) {
    if (barcode == null) {
      return 'Please scan a barcode';
    }

    final container = space.getCatalogedContainerSync(
      barcodeUUID: barcode.barcodeUUID,
    );

    final hasContainer = container != null;
    final sameBarcodeAsInitial =
        widget.currentBarcodeUUID == barcode.barcodeUUID;
    if (hasContainer && !sameBarcodeAsInitial) {
      return 'Barcode already in use';
    }

    return null;
  }
}

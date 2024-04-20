import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/widgets/form_fields/container_form_field.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class ContainerParentField extends ConsumerStatefulWidget {
  const ContainerParentField({
    super.key,
    required this.barcodeUUID,
    required this.containerType,
    required this.initialValue,
    this.onSaved,
    this.canReset = false,
    this.canClear = false,
  });

  final String? barcodeUUID;
  final ContainerType containerType;
  final CatalogedContainer? initialValue;
  final Function(CatalogedContainer?)? onSaved;
  final bool canReset;
  final bool canClear;

  @override
  AbstractScreen<ContainerParentField> createState() =>
      _ContainerParentFieldState();
}

class _ContainerParentFieldState extends AbstractScreen<ContainerParentField> {
  @override
  Widget build(BuildContext context) {
    return ContainerFormField(
      validator: (value) => parentValidator(
        value: value,
        currentBarcodeUUID: widget.barcodeUUID,
        containerType: widget.containerType,
      ),
      initialValue: widget.initialValue,
      decoration: const InputDecoration(
        labelText: 'Parent',
        border: OutlineInputBorder(),
      ),
      onSaved: (value) {
        if (value == null) return;
        widget.onSaved?.call(value);
      },
      canReset: widget.canReset,
      canClear: widget.canClear,
    );
  }

  String? parentValidator({
    required CatalogedContainer? value,
    String? currentBarcodeUUID,
    CatalogedContainer? currentContainer,
    required ContainerType containerType,
  }) {
    final moveable = containerType.moveable;
    if (value == null && moveable) {
      return 'Please scan a parent container';
    }

    final parentBarcodeUUID = value?.barcodeUUID;
    final barcodeUUID = currentContainer?.barcodeUUID ?? currentBarcodeUUID;

    if (barcodeUUID == parentBarcodeUUID && parentBarcodeUUID != null) {
      return 'Parent cannot be this container';
    }

    // Check if the parent container is a descendant of the current container.
    if (value != null && currentContainer != null) {
      final isDescendant = space.isDescendantOf(
        containerUUID: currentContainer.containerUUID,
        parentUUID: value.containerUUID,
      );

      if (isDescendant) {
        return 'Parent cannot be a descendant of this container';
      }
    }

    return null;
  }
}

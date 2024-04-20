import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/widgets/container_fields/container_barcode_field.dart';
import 'package:tswiri/widgets/container_fields/container_description_field.dart';
import 'package:tswiri/widgets/container_fields/container_name_field.dart';
import 'package:tswiri/widgets/container_fields/container_parent_field.dart';
import 'package:tswiri/widgets/container_fields/container_type_field.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

import 'package:uuid/uuid.dart';

class CreateContainerScreen extends ConsumerStatefulWidget {
  final CatalogedContainer? _parentContainer;

  const CreateContainerScreen({
    required CatalogedContainer? parentContainer,
    super.key,
  }) : _parentContainer = parentContainer;

  @override
  AbstractScreen<CreateContainerScreen> createState() =>
      _CreateContainerScreenState();
}

class _CreateContainerScreenState
    extends AbstractScreen<CreateContainerScreen> {
  late CatalogedContainer? _parentContainer;
  late ContainerType _containerType;
  late List<ContainerType> _validContainerTypes;
  CatalogedBarcode? _barcode;

  final _formKey = GlobalKey<FormState>();
  late final Map<String, dynamic> _initialState;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  ContainerType? get parentContainerType {
    return space.getContainerType(_parentContainer?.typeUUID);
  }

  ContainerType get preferredContainerType {
    return space.getContainerType(parentContainerType?.preferredChild) ??
        space.containerTypesSync.first;
  }

  bool get hasChanged {
    return _containerType != _initialState['containerType'] ||
        _nameController.text != _initialState['name'] ||
        _descriptionController.text != _initialState['description'] ||
        _barcode != _initialState['barcode'] ||
        _parentContainer != _initialState['parentContainer'];
  }

  @override
  void initState() {
    super.initState();
    _parentContainer = widget._parentContainer;
    _containerType = preferredContainerType;
    _validContainerTypes = space.containerTypesSync.where((type) {
      return parentContainerType?.canContain.contains(type.uuid) ?? true;
    }).toList();

    _initialState = {
      'containerType': _containerType,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'barcode': _barcode,
      'parentContainer': _parentContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('Create Container'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          if (hasChanged) {
            await _showDiscardChangesDialog();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );

    final floatingActionButton = FloatingActionButton.extended(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          await _createContainer();

          if (mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        }
      },
      label: const Text('Create'),
      icon: const Icon(Icons.save),
    );

    final containerType = ContainerTypeField(
      containerTypes: _validContainerTypes,
      initialValue: _containerType,
      onSaved: (newValue) {
        if (newValue == null) return;
        setState(() {
          _containerType = newValue;
        });
      },
      onChanged: (newValue) {
        setState(() {
          _containerType = newValue;
        });
      },
    );

    final generateName = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: IconButton.outlined(
        tooltip: 'Generate a name',
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(
          () => _nameController.text = _generateName(),
        ),
        icon: const Icon(Icons.generating_tokens_outlined),
      ),
    );

    final containerName = ContainerNameField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      onFieldSubmitted: (value) {
        _descriptionFocusNode.requestFocus();
      },
      suffixIcon: generateName,
    );

    final descriptionField = ContainerDescriptionField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
    );

    final barcodeField = ContainerBarcodeField(
      onSaved: (barcode) {
        if (barcode == null) return;
        setState(() {
          _barcode = barcode;
        });
      },
    );

    final parentField = ContainerParentField(
      barcodeUUID: _barcode?.barcodeUUID,
      containerType: _containerType,
      initialValue: _parentContainer,
      onSaved: (value) {
        setState(() {
          _parentContainer = value;
        });
      },
      canClear: true,
    );

    const spacer = SizedBox(height: 12);

    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: true,
      body: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.always,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  containerType,
                  spacer,
                  containerName,
                  spacer,
                  descriptionField,
                  spacer,
                  barcodeField,
                  spacer,
                  parentField,
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  String _generateName() {
    final count = db.catalogedContainers
        .filter()
        .typeUUIDEqualTo(_containerType.uuid)
        .countSync();
    final name = '${_containerType.name} ${count + 1}';
    return name;
  }

  Future<void> _createContainer() async {
    assert(_barcode != null, 'Barcode is required');
    assert(_nameController.text.isNotEmpty, 'Name is required');

    final barcodeUUID = _barcode!.barcodeUUID;
    final containerUUID = const Uuid().v1();
    final name = _nameController.text;
    final description = _descriptionController.text;
    final typeUUID = _containerType.uuid;

    final newContainer = CatalogedContainer()
      ..barcodeUUID = barcodeUUID
      ..containerUUID = containerUUID
      ..name = name
      ..description = description
      ..typeUUID = typeUUID
      ..containerUUID;

    final parentContainerUUID = _parentContainer?.containerUUID;

    ContainerRelationship? relationship;
    if (parentContainerUUID != null) {
      relationship = ContainerRelationship()
        ..parentContainerUUID = parentContainerUUID
        ..containerUUID = containerUUID;
    }

    final createMarker = !_containerType.enclosing && !_containerType.moveable;
    Marker? marker;
    if (createMarker) {
      marker = Marker()
        ..barcodeUUID = barcodeUUID
        ..containerUUID = containerUUID;
    }

    await db.writeTxn(() async {
      db.catalogedContainers.put(newContainer);
      if (relationship != null) {
        db.containerRelationships.put(relationship);
      }
      if (marker != null) {
        db.markers.put(marker);
      }
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Created'), showCloseIcon: true),
    );
  }

  Future<void> _showDiscardChangesDialog() async {
    final discard = await showConfirmDialog(
      title: 'Discard changes?',
      content: 'Are you sure you want to discard your changes?',
      positive: 'Yes',
      negative: 'No',
    );

    if (discard) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }
}

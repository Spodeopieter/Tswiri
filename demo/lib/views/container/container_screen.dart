import 'package:flutter/material.dart';

import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri/views/abstract_screen.dart';
import 'package:tswiri/widgets/container_fields/_export.dart';
import 'package:tswiri/widgets/container_fields/container_type_field.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class ContainerScreen extends ConsumerStatefulWidget {
  final CatalogedContainer _container;

  const ContainerScreen({
    required CatalogedContainer container,
    super.key,
  }) : _container = container;

  @override
  AbstractScreen<ContainerScreen> createState() => _ContainerScreenState();
}

class _ContainerScreenState extends AbstractScreen<ContainerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  late CatalogedContainer _originalContainer;
  late CatalogedBarcode? _barcode;
  late ContainerType _type;

  late ContainerRelationship? _relationship;
  late ContainerRelationship? _originalRelationship;

  CatalogedContainer get _container => widget._container;
  CatalogedContainer? get _parentContainer {
    if (_relationship == null) return null;
    return space.getCatalogedContainerSync(
      containerUUID: _relationship?.parentContainerUUID,
    );
  }

  bool get hasModified {
    return _container != _originalContainer ||
        _relationship != _originalRelationship;
  }

  bool get isValid => _formKey.currentState?.validate() ?? false;

  bool _childrenExpanded = false;

  @override
  void initState() {
    super.initState();
    _originalContainer = widget._container.clone();
    _barcode = space.getCatalogedBarcode(_container.barcodeUUID);
    _type = space.getContainerType(widget._container.typeUUID)!;

    _relationship = space.getParent(
      widget._container.containerUUID,
    );
    _originalRelationship = _relationship?.clone();

    _nameController.text = widget._container.name.toString();
    _descriptionController.text = widget._container.description.toString();
  }

  @override
  Widget build(BuildContext context) {
    final saveButton = Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilledButton.tonalIcon(
        onPressed: () async => _save(),
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );

    final deleteButton = Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        onPressed: () async => _delete(),
        icon: const Icon(Icons.delete),
      ),
    );

    final closeButton = IconButton(
      onPressed: () async => _close(),
      icon: const Icon(Icons.arrow_back),
    );

    late final nameUndo = IconButton(
      onPressed: () {
        setState(() {
          _container.name = _originalContainer.name;
          _nameController.text = _originalContainer.name.toString();
        });
      },
      icon: const Icon(Icons.undo),
    );

    final containerTypeField = ContainerTypeField(
      containerTypes: space.containerTypesSync,
      initialValue: _type,
      onChanged: (value) {
        setState(() {
          _container.typeUUID = value.uuid;
        });
      },
    );

    final nameField = ContainerNameField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      suffixIcon: _container.name != _originalContainer.name ? nameUndo : null,
      onChanged: (value) {
        setState(() {
          _container.name = value;
        });
      },
    );

    final descriptionUndo = IconButton(
      onPressed: () {
        setState(() {
          _container.description = _originalContainer.description;
          _descriptionController.text =
              _originalContainer.description.toString();
        });
      },
      icon: const Icon(Icons.undo),
    );

    final descriptionField = ContainerDescriptionField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      suffixIcon: _container.description != _originalContainer.description
          ? descriptionUndo
          : null,
      onChanged: (value) {
        setState(() {
          _container.description = value;
        });
      },
    );

    final barcodeField = ContainerBarcodeField(
      initialValue: _barcode,
      currentBarcodeUUID: _container.barcodeUUID,
      onSaved: (barcode) {
        if (barcode == null) return;
        setState(() {
          _container.barcodeUUID = barcode.barcodeUUID;
        });
      },
      canReset: true,
    );

    final parentField = ContainerParentField(
      barcodeUUID: _barcode?.barcodeUUID,
      containerType: _type,
      initialValue: _parentContainer,
      canReset: true,
      canClear: true,
      onSaved: (parent) {
        if (parent == null) return;
        setState(() {
          _relationship = ContainerRelationship()
            ..containerUUID = _container.containerUUID
            ..parentContainerUUID = parent.containerUUID;
        });
      },
    );

    final children = ContainerChildrenField(
      containerUUID: _originalContainer.containerUUID,
      onAddChild: () => _addChild(),
      expanded: _childrenExpanded,
      onExpansionChanged: (expanded) {
        _childrenExpanded = expanded;
      },
    );

    const spacer = SizedBox(height: 12.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_type.name.toString()),
        leading: closeButton,
        actions: [
          hasModified && isValid ? saveButton : const SizedBox(),
          deleteButton,
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.always,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  containerTypeField,
                  spacer,
                  nameField,
                  spacer,
                  descriptionField,
                  spacer,
                  barcodeField,
                  spacer,
                  parentField,
                  spacer,
                  children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    await db.writeTxn(() async {
      if (_container != _originalContainer) {
        // If the container has changed update the container.
        await db.catalogedContainers.put(_container);
      }

      if (_relationship != _originalRelationship) {
        // If the relationship has changed:

        if (_originalRelationship != null) {
          // Remove the original relationship.
          await db.containerRelationships.delete(_originalRelationship!.id);
        }

        if (_relationship != null) {
          // Put the new one in the db.
          await db.containerRelationships.put(_relationship!);
        }
      }
    });

    _nameFocusNode.unfocus();
    _descriptionFocusNode.unfocus();

    setState(() {
      _originalContainer = _container.clone();
      _originalRelationship = _relationship?.clone();
    });

    showSnackbar('Saved');
  }

  Future<void> _close() async {
    final close = hasModified
        ? await showConfirmDialog(
            title: 'Discard Changes?',
            content:
                'You have made changes to the container without saving them.'
                'Are you sure you want to discard these changes?',
            negative: 'No',
            positive: 'Yes',
          )
        : true;

    if (close && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final canDelete = space.canDeleteContainer(_container.containerUUID);

    if (canDelete == false) {
      return await showInfoDialog(
        title: 'Cannot Delete',
        content: 'This container cannot be deleted. It may have children or '
            'other relationships that prevent it from being deleted.',
      );
    }

    final delete = await showConfirmDialog(
      title: 'Delete Container?',
      content: 'Are you sure you want to delete this container?',
      negative: 'No',
      positive: 'Yes',
    );

    if (delete) {
      await space
          .deleteCatalogedContainer(_container.containerUUID)
          .then((deleted) {
        if (deleted) {
          showSnackbar('Deleted');
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        } else {
          showSnackbar('Failed to delete');
        }
      });
    }
  }

  void _addChild() {
    Navigator.of(context)
        .pushNamed(
          Routes.createContainer,
          arguments: _container,
        )
        .then((value) => setState(() {}));
  }
}

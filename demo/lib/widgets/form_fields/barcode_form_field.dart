import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class BarcodeFormField extends FormField<CatalogedBarcode> {
  BarcodeFormField({
    super.key,
    super.validator,
    super.autovalidateMode,
    super.initialValue,
    super.onSaved,
    void Function(CatalogedBarcode?)? onChanged,
    InputDecoration decoration = const InputDecoration(),
    bool canReset = false,
  }) : super(
          builder: (state) {
            final theme = Theme.of(state.context).inputDecorationTheme;
            const contentPadding = EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            );

            final inputDecoration = decoration
                .copyWith(
                  errorText: state.errorText,
                  contentPadding: contentPadding,
                )
                .applyDefaults(theme);

            final hasValue = state.value != null;
            final isInitialValue = state.value == initialValue;

            final title = Text(state.value?.barcodeUUID ?? '');
            final scanButton = Consumer(
              builder: (context, ref, child) {
                final space = ref.read(spaceProvider);

                return FilledButton.tonalIcon(
                  onPressed: () {
                    final hasCamera =
                        ref.read(settingsProvider).deviceHasCameras;

                    final route = hasCamera
                        ? Routes.barcodeSelector
                        : Routes.debugBarcodeSelector;

                    Navigator.of(context).pushNamed(route).then(
                      (barcodeUUID) {
                        if (barcodeUUID == null) return;
                        if (barcodeUUID is! String) return;

                        final barcode = space.getCatalogedBarcode(
                          barcodeUUID,
                        );

                        if (barcode == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Barcode not found'),
                              showCloseIcon: true,
                            ),
                          );
                        }

                        state.didChange(barcode);
                        onSaved?.call(barcode);
                        onChanged?.call(barcode);
                      },
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(hasValue ? 'Change' : 'Scan'),
                );
              },
            );

            final resetButton = IconButton.filledTonal(
              tooltip: 'Reset to initial value',
              onPressed: () {
                state.didChange(initialValue);
              },
              icon: const Icon(Icons.restore),
            );

            return InputDecorator(
              decoration: inputDecoration,
              isEmpty: !hasValue,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: title,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    scanButton,
                    if (canReset && !isInitialValue) resetButton,
                  ],
                ),
              ),
            );
          },
        );
}

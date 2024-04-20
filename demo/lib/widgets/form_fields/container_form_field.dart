import 'package:flutter/material.dart';
import 'package:tswiri/providers.dart';
import 'package:tswiri/routes.dart';
import 'package:tswiri_database/collections/collections_export.dart';
import 'package:tswiri_database/space/space.dart';

class ContainerFormField extends FormField<CatalogedContainer> {
  ContainerFormField({
    super.key,
    super.validator,
    super.autovalidateMode,
    super.initialValue,
    super.onSaved,
    void Function(CatalogedContainer?)? onChanged,
    InputDecoration decoration = const InputDecoration(),
    bool canClear = false,
    bool canReset = false,
  }) : super(
          builder: (state) {
            final inputTheme = Theme.of(state.context).inputDecorationTheme;
            const contentPadding = EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            );

            final inputDecoration = decoration
                .copyWith(
                  errorText: state.errorText,
                  contentPadding: contentPadding,
                )
                .applyDefaults(inputTheme);

            final hasValue = state.value != null;
            final isInitialValue = state.value == initialValue;

            final title = Text(state.value?.name ?? '');
            final subTitle = state.value != null
                ? Text(
                    state.value!.barcodeUUID!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null;

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

                        final container = space.getCatalogedContainerSync(
                          barcodeUUID: barcodeUUID,
                        );

                        if (container == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Container not found'),
                              showCloseIcon: true,
                            ),
                          );
                        }

                        state.didChange(container);
                        onSaved?.call(container);
                        onChanged?.call(container);
                      },
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(hasValue ? 'Change' : 'Scan'),
                );
              },
            );

            final clearButton = IconButton.filledTonal(
              tooltip: 'Clear',
              onPressed: () {
                state.didChange(null);
                onSaved?.call(null);
                onChanged?.call(null);
              },
              icon: const Icon(Icons.clear),
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
              isEmpty: state.value == null,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: title,
                subtitle: subTitle,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    scanButton,
                    if (canClear && hasValue) clearButton,
                    if (canReset && !isInitialValue && initialValue != null)
                      resetButton,
                  ],
                ),
              ),
            );
          },
        );
}

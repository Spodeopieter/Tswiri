import 'package:flutter/material.dart';
import 'package:tswiri_database/collections/container_type/container_type.dart';

class ContainerTypeFormField extends FormField<ContainerType> {
  ContainerTypeFormField({
    super.key,
    super.validator,
    super.autovalidateMode,
    super.initialValue,
    super.onSaved,
    void Function(ContainerType)? onChanged,
    required List<ContainerType> containerTypes,
    InputDecoration decoration = const InputDecoration(),
  })  : assert(containerTypes.isNotEmpty),
        super(
          builder: (state) {
            return Builder(builder: (context) {
              final theme = Theme.of(context);

              final inputDecoration = decoration
                  .copyWith(
                    errorText: state.errorText,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 8.0,
                    ),
                  )
                  .applyDefaults(theme.inputDecorationTheme);

              return InputDecorator(
                decoration: inputDecoration,
                isEmpty: state.value == null,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: containerTypes.map((type) {
                    return ChoiceChip(
                      avatar: Icon(
                        type.iconData.iconData,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      label: Text(type.name),
                      selected: state.value?.uuid == type.uuid,
                      onSelected: (selected) {
                        if (selected) {
                          state.didChange(type);
                          onChanged?.call(type);
                        }
                      },
                      tooltip: type.description,
                    );
                  }).toList(),
                ),
              );
            });
          },
        );
}

// class ContainerTypeChoiceWidget extends StatelessWidget {
//   final ContainerType containerType;
//   final List<ContainerType> validContainerTypes;
//   final void Function(ContainerType) onSelected;

//   const ContainerTypeChoiceWidget({
//     super.key,
//     required this.containerType,
//     required this.validContainerTypes,
//     required this.onSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Wrap(
//         alignment: WrapAlignment.center,
//         runAlignment: WrapAlignment.center,
//         spacing: 4.0,
//         children: validContainerTypes.map((type) {
//           return ChoiceChip(
//             avatar: Icon(
//               type.iconData.iconData,
//               color: Theme.of(context).colorScheme.onSurface,
//             ),
//             label: Text(type.name),
//             selected: containerType == type,
//             onSelected: (selected) {
//               if (selected) {
//                 onSelected(type);
//               }
//             },
//             tooltip: type.description,
//           );
//         }).toList(),
//       ),
//     );
//   }
// }

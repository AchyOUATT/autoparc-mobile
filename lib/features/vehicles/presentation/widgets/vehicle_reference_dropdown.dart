import 'package:flutter/material.dart';

/// Shared reference selector extracted from the vehicle registration form.
class VehicleReferenceDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabel;
  final Widget? Function(T)? itemLeading;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const VehicleReferenceDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
    this.itemLeading,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    hint: Text(
      enabled ? 'Sélectionner…' : 'Choisir d\'abord la valeur précédente',
    ),
    isExpanded: true,
    items: items.map((item) {
      final leading = itemLeading?.call(item);
      return DropdownMenuItem<T>(
        value: item,
        child: leading != null
            ? Row(
                children: [
                  leading,
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      itemLabel(item),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Text(itemLabel(item), overflow: TextOverflow.ellipsis),
      );
    }).toList(),
    onChanged: enabled ? onChanged : null,
    validator: validator,
  );
}

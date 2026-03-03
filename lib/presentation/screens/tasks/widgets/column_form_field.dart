import 'package:flutter/material.dart';

class ColumnFormField extends StatelessWidget {
  static const List<Color> presetColors = [
    Color(0xFF9E9E9E),
    Color(0xFF4A6FA5),
    Color(0xFF5865F2),
    Color(0xFF0088CC),
    Color(0xFF0366D6),
    Color(0xFF25D366),
    Color(0xFF2EB886),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];

  static String colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static Color hexToColor(String hex) {
    if (hex.isEmpty) {
      return presetColors[0];
    }

    var h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) {
      h = 'FF$h';
    }

    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : presetColors[0];
  }

  final TextEditingController controller;
  final Color pickedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback? onSave;
  final VoidCallback onCancel;
  final String saveLabel;

  const ColumnFormField({
    super.key,
    required this.controller,
    required this.pickedColor,
    required this.onColorChanged,
    required this.onSave,
    required this.onCancel,
    required this.saveLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Text(
            'Цвет',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ColumnFormField.presetColors.map((c) {
              final selected = c.toARGB32() == pickedColor.toARGB32();
              return GestureDetector(
                onTap: () => onColorChanged(c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel, 
                child: const Text('Отмена'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSave,
                child: Text(saveLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

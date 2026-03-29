import 'package:flutter/material.dart';

typedef CodeComposeResult = ({String lang, String code});
typedef LocationComposeResult = ({String lat, String lon, String desc});

abstract final class SendSpecialMessageDialogs {
  static Future<CodeComposeResult?> pickCode(BuildContext context) {
    return showDialog<CodeComposeResult>(
      context: context,
      builder: (context) => const _CodeDialog(),
    );
  }

  static Future<LocationComposeResult?> pickLocation(BuildContext context) {
    return showDialog<LocationComposeResult>(
      context: context,
      builder: (context) => const _LocationDialog(),
    );
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _lang = TextEditingController(text: 'plaintext');
  final _code = TextEditingController();

  @override
  void dispose() {
    _lang.dispose();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _code.text.trim();
    if (code.isEmpty) {
      return;
    }
    final lang = _lang.text.trim().isEmpty ? 'plaintext' : _lang.text.trim();
    Navigator.of(context).pop((lang: lang, code: code));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Отправить код'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _lang,
              decoration: const InputDecoration(
                labelText: 'Язык подсветки',
                hintText: 'dart, plaintext, …',
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              maxLines: 10,
              minLines: 4,
              decoration: const InputDecoration(
                labelText: 'Код',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Отправить')),
      ],
    );
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog();

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _submit() {
    final lat = _lat.text.trim();
    final lon = _lon.text.trim();
    if (lat.isEmpty || lon.isEmpty) {
      return;
    }
    Navigator.of(context).pop((
      lat: lat,
      lon: lon,
      desc: _desc.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Местоположение'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _lat,
              decoration: const InputDecoration(
                labelText: 'Широта',
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lon,
              decoration: const InputDecoration(
                labelText: 'Долгота',
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Отправить')),
      ],
    );
  }
}

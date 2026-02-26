import 'package:flutter/material.dart';

class CreatePollDialog extends StatefulWidget {
  const CreatePollDialog({super.key});

  static Future<({String question, List<String> options, bool anonymous})?>
  show(BuildContext context) {
    return showModalBottomSheet<({
      String question,
      List<String> options,
      bool anonymous
    })>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const CreatePollDialog(),
    );
  }

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _questionController = TextEditingController();
  final _optionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  bool _anonymous = true;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      return;
    }
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _submit() {
    final question = _questionController.text.trim();
    final options = _optionControllers
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите вопрос')));
      return;
    }

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Добавьте минимум 2 варианта ответа')));
      return;
    }

    final seen = <String>{};
    final unique = options.where((o) => seen.add(o)).toList();
    if (unique.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Варианты должны отличаться')));
      return;
    }

    Navigator.of(context).pop((question: question, options: unique, anonymous: _anonymous));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Новый опрос',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Вопрос',
                  hintText: 'Текст вопроса',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Варианты ответа', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 6),
            ...List.generate(_optionControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          hintText: 'Вариант ${i + 1}',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeOption(i),
                      ),
                  ],
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Добавить вариант'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CheckboxListTile(
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v ?? true),
                title: const Text('Анонимный опрос'),
                subtitle: const Text('Участники не увидят, кто как голосовал'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Создать опрос'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

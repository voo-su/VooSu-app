import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/usecases/account/update_profile_personal_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';

String _formatIsoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? _tryParseIsoDate(String s) {
  final t = s.trim();
  if (t.length < 10) return null;
  final parts = t.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

String _birthdayDisplayLabel(String iso) {
  final dt = _tryParseIsoDate(iso);
  if (dt == null) return iso.isEmpty ? 'Не выбрана' : iso;
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

class EditProfilePersonalScreen extends StatefulWidget {
  const EditProfilePersonalScreen({super.key});

  @override
  State<EditProfilePersonalScreen> createState() =>
      _EditProfilePersonalScreenState();
}

class _EditProfilePersonalScreenState extends State<EditProfilePersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _aboutController;
  int _gender = 0;
  String _birthday = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthBloc>().state.user;
    _nameController = TextEditingController(text: u?.name ?? '');
    _surnameController = TextEditingController(text: u?.surname ?? '');
    _aboutController = TextEditingController(text: u?.about ?? '');
    _gender = u?.gender ?? 0;
    _birthday = u?.birthday ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  String? _nonEmptyMax30(String? v, String label) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Укажите $label';
    if (s.length > 30) return 'Не более 30 символов';
    return null;
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _tryParseIsoDate(_birthday) ??
        DateTime(now.year - 25, now.month, now.day);
    final first = DateTime(1900);
    final last = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      locale: const Locale('ru'),
    );
    if (picked != null) {
      setState(() => _birthday = _formatIsoDate(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await di.sl<UpdateProfilePersonalUseCase>()(
        name: _nameController.text,
        surname: _surnameController.text,
        gender: _gender,
        birthday: _birthday,
        about: _aboutController.text,
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthProfilePersonalUpdated(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          gender: _gender,
          birthday: _birthday.trim(),
          about: _aboutController.text.trim(),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Данные сохранены'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e is Failure
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Личные данные')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Имя'),
              validator: (v) => _nonEmptyMax30(v, 'имя'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _surnameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Фамилия'),
              validator: (v) => _nonEmptyMax30(v, 'фамилию'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Пол'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Не указан')),
                DropdownMenuItem(value: 1, child: Text('Мужской')),
                DropdownMenuItem(value: 2, child: Text('Женский')),
              ],
              onChanged: _loading
                  ? null
                  : (v) {
                      if (v != null) setState(() => _gender = v);
                    },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Дата рождения'),
              subtitle: Text(
                _birthdayDisplayLabel(_birthday),
                style: TextStyle(color: variant),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_birthday.isNotEmpty)
                    IconButton(
                      tooltip: 'Очистить',
                      onPressed:
                          _loading ? null : () => setState(() => _birthday = ''),
                      icon: const Icon(Icons.clear),
                    ),
                  IconButton(
                    tooltip: 'Выбрать',
                    onPressed: _loading ? null : _pickBirthday,
                    icon: const Icon(Icons.calendar_today_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _aboutController,
              minLines: 3,
              maxLines: 5,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'О себе',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

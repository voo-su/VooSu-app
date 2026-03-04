import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/usecases/account/change_username_usecase.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';

final _usernameRe = RegExp(r'^[a-zA-Z0-9_-]+$');

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3 || v.length > 20) {
      return 'От 3 до 20 символов';
    }
    if (!_usernameRe.hasMatch(v)) {
      return 'Только латиница, цифры, _ и -';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await di.sl<ChangeUsernameUseCase>()(_controller.text);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthUsernameUpdated(_controller.text.trim()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Логин обновлён'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Смена логина')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Латиница, цифры, _ и —, 3–20 символов',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Новый логин',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: _validateUsername,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
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
      ),
    );
  }
}

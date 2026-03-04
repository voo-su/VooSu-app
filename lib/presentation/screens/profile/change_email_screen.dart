import 'package:flutter/material.dart';
import 'package:voosu/core/failures.dart';
import 'package:voosu/core/injector.dart' as di;
import 'package:voosu/domain/usecases/account/request_email_change_usecase.dart';
import 'package:voosu/domain/usecases/account/verify_email_change_usecase.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  String? _verificationToken;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите email';
    if (!v.contains('@') || v.length < 5) return 'Некорректный email';
    return null;
  }

  String? _validateCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите код из письма';
    return null;
  }

  Future<void> _requestCode() async {
    if (!_emailKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = await di.sl<RequestEmailChangeUseCase>()(
        _emailController.text,
      );
      if (!mounted) return;
      setState(() => _verificationToken = token);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Код отправлен на новую почту'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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

  Future<void> _verify() async {
    final token = _verificationToken;
    if (token == null || token.isEmpty) return;
    if (!_codeKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await di.sl<VerifyEmailChangeUseCase>()(token, _codeController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Адрес почты обновлён'),
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
    final codeStep = _verificationToken != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Смена почты')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!codeStep) ...[
              Text(
                'Код подтверждения на новый адрес',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Form(
              key: _emailKey,
              child: TextFormField(
                controller: _emailController,
                enabled: !codeStep && !_loading,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Новый email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: _validateEmail,
              ),
            ),
            if (!codeStep) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _requestCode,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Отправить код'),
              ),
            ],
            if (codeStep) ...[
              const SizedBox(height: 32),
              Text(
                'Введите код из письма',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Form(
                key: _codeKey,
                child: TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Код',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  validator: _validateCode,
                  onFieldSubmitted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Подтвердить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

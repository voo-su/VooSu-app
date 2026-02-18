import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voosu/core/layout/responsive.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_bloc.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_event.dart';
import 'package:voosu/presentation/screens/auth/bloc/auth_state.dart';

const _kResendCooldownSec = 200;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  Timer? _resendTimer;
  int _resendSecondsLeft = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _cancelResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
    if (mounted) {
      setState(() => _resendSecondsLeft = 0);
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    if (!mounted) return;
    setState(() => _resendSecondsLeft = _kResendCooldownSec);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_resendSecondsLeft <= 1) {
          _resendTimer?.cancel();
          _resendTimer = null;
          _resendSecondsLeft = 0;
        } else {
          _resendSecondsLeft--;
        }
      });
    });
  }

  void _sendCode() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginCodeRequested(_emailController.text.trim()),
      );
    }
  }

  void _resendCode() {
    if (_resendSecondsLeft > 0 || context.read<AuthBloc>().state.isLoading) {
      return;
    }
    context.read<AuthBloc>().add(const AuthResendLoginCodeRequested());
  }

  void _verifyCode() {
    context.read<AuthBloc>().add(
      AuthLoginVerifyRequested(_codeController.text.trim()),
    );
  }

  void _backToEmail() {
    _codeController.clear();
    _cancelResendTimer();
    context.read<AuthBloc>().add(const AuthBackToEmailLogin());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              !prev.awaitingLoginCode && curr.awaitingLoginCode,
          listener: (context, state) => _startResendTimer(),
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.isLoading &&
              !curr.isLoading &&
              curr.awaitingLoginCode &&
              curr.error == null &&
              prev.awaitingLoginCode,
          listener: (context, state) => _startResendTimer(),
        ),
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.awaitingLoginCode && !curr.awaitingLoginCode,
          listener: (context, state) => _cancelResendTimer(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Breakpoints.isMobile(context) ? 20 : 32,
                  vertical: Breakpoints.isMobile(context) ? 16 : 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Breakpoints.isDesktop(context) ? 420 : 400,
                  ),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return Form(
                        key: _formKey,
                        child: state.awaitingLoginCode
                            ? _buildCodeStep(context, state)
                            : _buildEmailStep(context, state),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context, AuthState state) {
    final termsStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'voosu',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Мы так рады видеть вас',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Вход или регистрация',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendCode(),
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'you@example.com',
            prefixIcon: const Icon(Icons.mail_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return 'Введите email';
            }
            if (!v.contains('@') || v.length < 5) {
              return 'Введите корректный email';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isLoading ? null : _sendCode,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Войти',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          'Нажимая «Войти» вы соглашаетесь с условиями использования',
          style: termsStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context, AuthState state) {
    final variantColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Код из письма',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Пожалуйста, введите в форму ниже код, который мы отправили вам.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: variantColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (_resendSecondsLeft > 0)
          Text(
            'Вы сможете отправить код повторно через $_resendSecondsLeft сек.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: variantColor,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _verifyCode(),
          decoration: InputDecoration(
            labelText: 'Код',
            hintText: 'Например, 123456',
            prefixIcon: const Icon(Icons.pin_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_resendSecondsLeft == 0)
          TextButton(
            onPressed: state.isLoading ? null : _resendCode,
            child: const Text('Отправить код снова'),
          ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: state.isLoading ? null : _verifyCode,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Войти',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: state.isLoading ? null : _backToEmail,
          child: const Text('Отменить'),
        ),
      ],
    );
  }
}

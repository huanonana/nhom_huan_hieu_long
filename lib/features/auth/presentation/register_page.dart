import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/app_user.dart';
import 'auth_error_message.dart';
import 'auth_layout.dart';
import 'auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AppUserRole _role = AppUserRole.guest;
  bool _loading = false;
  String? _error;
  bool _initialRoleApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialRoleApplied) return;
    _initialRoleApplied = true;
    if (GoRouterState.of(context).uri.queryParameters['role'] == 'host') {
      _role = AppUserRole.host;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _email.text,
            password: _password.text,
            role: _role,
            displayName: _name.text,
          );
      if (mounted) {
        final requested = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(
          requested ?? (_role == AppUserRole.host ? '/host' : '/explore'),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Tạo tài khoản HHL Stay',
    description:
        'Tham gia để khám phá nơi nghỉ yêu thích hoặc quản lý homestay của bạn.',
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.holiday_village_rounded, color: brand, size: 54),
          const SizedBox(height: 12),
          Text(
            'Tạo tài khoản',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nhập tên hiển thị.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) => value == null || !value.contains('@')
                ? 'Nhập email hợp lệ.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mật khẩu',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) => value == null || value.length < 6
                ? 'Mật khẩu tối thiểu 6 ký tự.'
                : null,
          ),
          const SizedBox(height: 18),
          const Text('Bạn đăng ký với vai trò'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Khách'),
                selected: _role == AppUserRole.guest,
                onSelected: (_) => setState(() => _role = AppUserRole.guest),
              ),
              ChoiceChip(
                label: const Text('Chủ nhà'),
                selected: _role == AppUserRole.host,
                onSelected: (_) => setState(() => _role = AppUserRole.host),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đăng ký'),
          ),
          TextButton(
            onPressed: () {
              final from = GoRouterState.of(
                context,
              ).uri.queryParameters['from'];
              context.go(
                from == null
                    ? '/login'
                    : '/login?from=${Uri.encodeComponent(from)}',
              );
            },
            child: const Text('Đã có tài khoản? Đăng nhập'),
          ),
          TextButton.icon(
            onPressed: () => context.go('/explore'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Tiếp tục xem homestay'),
          ),
        ],
      ),
    ),
  );
}

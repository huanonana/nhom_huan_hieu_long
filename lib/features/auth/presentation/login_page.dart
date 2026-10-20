import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/app_user.dart';
import 'auth_error_message.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.adminMode = false});
  final bool adminMode;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
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
      final user = await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      if (widget.adminMode && user.role != AppUserRole.host) {
        if (mounted) {
          setState(
            () => _error =
                'Tài khoản này chưa có quyền Chủ nhà/Admin. Hãy dùng tài khoản chủ nhà hoặc đăng ký vai trò Chủ nhà.',
          );
        }
        return;
      }
      if (mounted) {
        final requested = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(requested ?? (widget.adminMode ? '/host' : '/'));
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAF8F4),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Về trang khám phá'),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.adminMode
                          ? const [Color(0xFFEEF2FF), Color(0xFFFFF8F1)]
                          : const [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
                    ),
                    border: Border.all(color: const Color(0xFFF0E3D8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(
                          widget.adminMode
                              ? Icons.admin_panel_settings_rounded
                              : Icons.holiday_village_rounded,
                          color: brand,
                          size: 29,
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        widget.adminMode
                            ? 'Không gian quản lý HHL Stay'
                            : 'Chào mừng bạn trở lại.',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.adminMode
                            ? 'Đăng nhập tài khoản Chủ nhà/Admin để quản lý homestay, phòng và đơn đặt.'
                            : 'Đăng nhập để lưu nơi yêu thích và theo dõi chuyến đi của bạn.',
                        style: const TextStyle(
                          color: muted,
                          height: 1.45,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) =>
                            value == null || !value.contains('@')
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
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 17),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.adminMode
                                    ? 'Đăng nhập quản lý'
                                    : 'Đăng nhập',
                              ),
                      ),
                      if (widget.adminMode) ...[
                        TextButton(
                          onPressed: () =>
                              context.go('/register?from=%2Fhost&role=host'),
                          child: const Text(
                            'Chưa có tài khoản chủ nhà? Đăng ký',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Đăng nhập khách hàng'),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: () {
                            final from = GoRouterState.of(
                              context,
                            ).uri.queryParameters['from'];
                            context.go(
                              from == null
                                  ? '/register'
                                  : '/register?from=${Uri.encodeComponent(from)}',
                            );
                          },
                          child: const Text('Chưa có tài khoản? Đăng ký'),
                        ),
                        const Divider(height: 26),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/admin/login?from=%2Fhost'),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Đăng nhập Chủ nhà / Admin'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (!widget.adminMode)
                        Center(
                          child: Text(
                            'HHL STAY  ·  HOMESTAY VIỆT NAM',
                            style: TextStyle(
                              color: muted.withValues(alpha: .85),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

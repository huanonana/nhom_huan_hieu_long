import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/state/app_state.dart';
import '../../../core/widgets/common.dart';
import '../domain/app_user.dart';
import 'auth_error_message.dart';
import 'auth_layout.dart';
import 'auth_provider.dart';
import 'social_auth_buttons.dart';

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
  final _emailFocus = FocusNode();
  bool _loading = false;
  bool _emailBlurred = false;
  String? _error;

  bool get _emailLooksValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && mounted) {
        setState(() => _emailBlurred = true);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
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
        ref.read(roleProvider.notifier).state = user.role == AppUserRole.host
            ? DemoRole.host
            : DemoRole.guest;
        final requested = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(requested ?? (widget.adminMode ? '/host' : '/explore'));
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goBack() {
    final state = GoRouterState.of(context);
    final back = state.uri.queryParameters['back'];
    if (back != null && back.startsWith('/') && !back.startsWith('//')) {
      context.go(back);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/explore');
    }
  }

  OutlineInputBorder _emailBorder(Color? color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color ?? const Color(0xFFD9DEE8)),
  );

  @override
  Widget build(BuildContext context) => AuthLayout(
    adminMode: widget.adminMode,
    title: widget.adminMode
        ? 'Quản lý kỳ nghỉ của bạn'
        : 'Chuyến đi bắt đầu từ một nơi ở thật hợp gu.',
    description: widget.adminMode
        ? 'Quản lý homestay, phòng và đặt phòng trong cùng một không gian.'
        : 'Khám phá những nơi nghỉ có cá tính riêng, giá rõ ràng và đặt phòng dễ dàng.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Quay lại'),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.adminMode ? 'Đăng nhập quản lý' : 'Chào mừng bạn trở lại',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          widget.adminMode
              ? 'Dành riêng cho Chủ nhà / Admin'
              : 'Đăng nhập để tiếp tục chuyến đi của bạn.',
          style: const TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 15),
        const GuidanceTile(
          steps:
              'Nhập email và mật khẩu đã đăng ký. Tài khoản, đơn đặt và yêu thích được lưu trên thiết bị này; không đồng bộ sang thiết bị khác.',
        ),
        const SizedBox(height: 22),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HoverMotion(
                scale: 1.012,
                lift: 2,
                child: TextFormField(
                  controller: _email,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    enabledBorder: _emailBorder(
                      _emailBlurred
                          ? _emailLooksValid
                                ? const Color(0xFF22A06B)
                                : const Color(0xFFE36B6B)
                          : null,
                    ),
                    focusedBorder: _emailBorder(brand),
                  ),
                  validator: (value) =>
                      value == null ||
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value.trim())
                      ? 'Nhập email hợp lệ.'
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              HoverMotion(
                scale: 1.012,
                lift: 2,
                child: TextFormField(
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
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 22),
              HoverMotion(
                scale: 1.025,
                lift: 3,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.adminMode ? 'Đăng nhập quản lý' : 'Đăng nhập',
                        ),
                ),
              ),
              if (widget.adminMode) ...[
                TextButton(
                  onPressed: () =>
                      context.go('/register?from=%2Fhost&role=host'),
                  child: const Text('Chưa có tài khoản chủ nhà? Đăng ký'),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Đăng nhập khách hàng'),
                ),
              ] else ...[
                const SizedBox(height: 18),
                const SocialAuthButtons(),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    final uri = GoRouterState.of(context).uri;
                    final params = <String, String>{
                      if (uri.queryParameters['from'] case final from?)
                        'from': from,
                      if (uri.queryParameters['back'] case final back?)
                        'back': back,
                    };
                    context.go(
                      params.isEmpty
                          ? '/register'
                          : '/register?${Uri(queryParameters: params).query}',
                    );
                  },
                  child: const Text('Chưa có tài khoản? Đăng ký'),
                ),
                const Divider(height: 26),
                HoverMotion(
                  scale: 1.02,
                  lift: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/admin/login?from=%2Fhost'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Đăng nhập Chủ nhà / Admin'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
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
  );
}

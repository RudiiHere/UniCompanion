import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../config/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref.read(authServiceProvider).signInWithEmail(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (result.success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Login failed'), backgroundColor: AppTheme.rose),
        );
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    await ref.read(authServiceProvider).signInWithGoogle();
    if (mounted) setState(() => _loading = false);
  }

  void _openForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(
        ref: ref,

        initialEmail: _emailCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),


                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'UniCompanion',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onBackground, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text('Your smart campus assistant', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),

                const SizedBox(height: 40),


                Text('Welcome back', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onBackground, letterSpacing: -0.4)),
                const SizedBox(height: 4),
                Text('Sign in to continue', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _openForgotPassword,
                    child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),


                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 20),

                Row(children: [
                  Expanded(child: Divider(color: cs.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
                  Expanded(child: Divider(color: cs.outline)),
                ]),
                const SizedBox(height: 20),

                OutlinedButton(
                  onPressed: _loading ? null : _googleLogin,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEA4335)),
                        child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 10),
                      const Text('Continue with Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text('Register', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String initialEmail;
  const _ForgotPasswordSheet({required this.ref, required this.initialEmail});

  @override
  ConsumerState<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    setState(() => _error = null);
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() => _sending = true);
    final result = await ref.read(authServiceProvider).resetPassword(email);
    if (!mounted) return;

    if (result.success) {
      setState(() { _sending = false; _sent = true; });
    } else {
      setState(() { _sending = false; _error = result.message ?? 'Could not send reset email'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),

          if (_sent) ..._buildSentState(cs) else ..._buildFormState(cs),
        ],
      ),
    );
  }

  List<Widget> _buildFormState(ColorScheme cs) {
    return [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: AppTheme.indigoSoft, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.lock_reset_rounded, size: 26, color: AppTheme.indigo),
      ),
      const SizedBox(height: 16),
      Text('Reset password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      Text(
        'Enter the email linked to your account and we\'ll send you a link to reset your password.',
        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
      ),
      const SizedBox(height: 20),

      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autofocus: widget.initialEmail.isEmpty,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
        ),
        onSubmitted: (_) => _send(),
      ),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: AppTheme.rose),
          const SizedBox(width: 6),
          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.rose, fontSize: 12, fontWeight: FontWeight.w500))),
        ]),
      ],

      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _sending ? null : _send,
        child: _sending
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Send reset link'),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ),
      ),
    ];
  }

  List<Widget> _buildSentState(ColorScheme cs) {
    return [
      Center(
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.emeraldSoft, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.mark_email_read_rounded, size: 32, color: AppTheme.emerald),
            ),
            const SizedBox(height: 18),
            Text('Check your inbox', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(
              'We\'ve sent a password reset link to:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 4),
            Text(
              _emailCtrl.text.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the link in the email to set a new password. Don\'t forget to check your spam folder.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ];
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/civiclens_logo.dart';

// Reuse shared widgets defined in login_screen.dart via part files is not
// practical here, so we inline the same small widgets.

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ────────────────────────────────────────────────

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _firebaseAuthMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _errorMessage = 'Unable to create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Your password is too weak. Please try a stronger one.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Unable to create your account.';
    }
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Use at least 8 characters.';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Add at least 1 uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Add at least 1 lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Add at least 1 number.';
    }
    if (!value.contains(RegExp(r'[^a-zA-Z0-9\s]'))) {
      return 'Add at least 1 special character.';
    }
    return null;
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.38),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.tertiaryContainer.withValues(alpha: 0.30),
                    cs.surface,
                    cs.surface,
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
          ),

          // ── Back button ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: 'Back to login',
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    mq.size.height * 0.06,
                    24,
                    mq.viewInsets.bottom + 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // ── Logo ───────────────────────────────────
                          Center(
                            child: CivicLensLogo(
                              size: 80,
                              isDark: Theme.of(context).brightness == Brightness.dark,
                            ),
                          ),
                          const SizedBox(height: 24),


                          // ── Heading ────────────────────────────────
                          Center(
                            child: Text(
                              'Join CivicLens',
                              textAlign: TextAlign.center,
                              style: tt.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Report civic issues and improve your community.',
                              textAlign: TextAlign.center,
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Email ──────────────────────────────────
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[AutofillHints.email],
                            decoration: _fieldDecoration(
                              label: 'Email address',
                              hint: 'you@example.com',
                              icon: Icons.email_outlined,
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),

                          // ── Password ───────────────────────────────
                          TextFormField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[
                              AutofillHints.newPassword
                            ],
                            decoration: _fieldDecoration(
                              label: 'Password',
                              hint: 'At least 8 characters',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),

                          // ── Confirm password ───────────────────────
                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !_isLoading,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.newPassword
                            ],
                            decoration: _fieldDecoration(
                              label: 'Confirm password',
                              hint: 'Re-enter your password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (String? value) {
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) =>
                                _isLoading ? null : _submit(),
                          ),

                          // ── Password strength hints ────────────────
                          const SizedBox(height: 10),
                          _PasswordHints(
                              password: _passwordController.text),

                          // ── Error banner ───────────────────────────
                          if (_errorMessage != null) ...<Widget>[
                            const SizedBox(height: 14),
                            _SignupErrorBanner(message: _errorMessage!),
                          ],

                          const SizedBox(height: 24),

                          // ── Create account button ──────────────────
                          _SignupButton(
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 24),

                          // ── Login link ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Already have an account? ',
                                style: tt.bodyMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Text(
                                  'Sign in',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password strength hints ───────────────────────────────────────────────────

class _PasswordHints extends StatelessWidget {
  final String password;

  const _PasswordHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final checks = <String, bool>{
      '8+ characters': password.length >= 8,
      'Uppercase letter': password.contains(RegExp(r'[A-Z]')),
      'Lowercase letter': password.contains(RegExp(r'[a-z]')),
      'Number': password.contains(RegExp(r'[0-9]')),
      'Special character': password.contains(RegExp(r'[^a-zA-Z0-9\s]')),
    };
    final metCount = checks.values.where((v) => v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: metCount / 5,
            minHeight: 4,
            backgroundColor: cs.surfaceContainerHighest,
            color: metCount <= 1
                ? cs.error
                : (metCount <= 3 ? Colors.orange : Colors.green),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: checks.entries.map((entry) {
            final met = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: met ? Colors.green : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: met ? Colors.green : cs.onSurfaceVariant,
                        fontWeight: met ? FontWeight.w700 : FontWeight.normal,
                      ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _SignupErrorBanner extends StatelessWidget {
  final String message;

  const _SignupErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.error_outline_rounded,
              color: cs.onErrorContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────

class _SignupButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignupButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shadowColor: cs.primary.withValues(alpha: 0.4),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? SizedBox.square(
                key: const ValueKey('loader'),
                dimension: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: cs.onPrimary),
              )
            : const Text(
                key: ValueKey('label'),
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

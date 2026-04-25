import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/errors.dart';
import '../../core/haptics.dart';
import '../../core/responsive.dart';
import '../../services/supabase_service.dart';
import '../../widgets/widgets.dart';
import '../../widgets/ts_scaffold.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isSignUp  = false;
  bool _loading   = false;
  String? _error;
  bool _hasError   = false;
  late final StreamSubscription<AuthState> _authSub;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _navigateAfterAuth() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      // Ensure profile exists
      await Supabase.instance.client.from('profiles').upsert(
        {'id': uid},
        onConflict: 'id',
      );
      // Check if profile setup is complete
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('profile_complete')
          .eq('id', uid)
          .maybeSingle();
      final complete = profile?['profile_complete'] == true;
      if (!mounted) return;
      if (!complete) {
        context.go('/profile-setup');
      } else {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen for OAuth callback (deep link returns session)
    // Skip the initial event that fires on subscription
    var isFirst = true;
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (isFirst) { isFirst = false; return; }
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        _navigateAfterAuth();
      }
    });
  }

  String? _validate() {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.isEmpty) return 'email and password are required';
    if (!_emailRegex.hasMatch(email)) return 'enter a valid email address';
    if (pass.length < 8) return 'password must be at least 8 characters';
    return null;
  }

  Future<void> _showForgotSheet() async {
    final email = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TSColors.s1,
      constraints: TSResponsive.modalConstraints,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ForgotPasswordSheet(prefill: _email.text.trim()),
    );
    if (email == null || !mounted) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://gettripsquad.com/auth/reset',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("check $email — we sent a reset link",
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.lime,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("couldn't send — ${humanizeError(e)}",
              style: TSTextStyles.body(color: TSColors.bg, size: 13)),
          backgroundColor: TSColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _signInWithApple() async {
    TSHaptics.medium();
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithApple();
      // Native flow returns a signed-in session synchronously; navigate now.
      if (mounted) await _navigateAfterAuth();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = humanizeError(e);
          _hasError = true;
        });
        TSHaptics.error();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    TSHaptics.medium();
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = humanizeError(e);
          _hasError = true;
        });
        TSHaptics.error();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    TSHaptics.medium();
    final validationError = _validate();
    if (validationError != null) {
      setState(() { _error = validationError; _hasError = true; });
      TSHaptics.error();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _hasError = false);
      });
      return;
    }
    setState(() { _loading = true; _error = null; _hasError = false; });

    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(_email.text.trim(), _password.text);
        if (mounted) {
          setState(() => _loading = false);
          // Deliberately ambiguous between "new signup, confirm your
          // email" and "this email is already registered, just sign
          // in." Supabase does not tell us which case it is — this is
          // a security feature (user-enumeration resistance, so
          // attackers can't probe the db for valid emails). We cover
          // both paths in the copy so legitimate users in either
          // case know exactly what to do.
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: TSColors.s2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('check your inbox ✉️',
                  style: TSTextStyles.heading(size: 20)),
              content: Text(
                "if ${_email.text.trim()} is new to tripsquad, we sent a confirmation link — tap it to activate, then sign in.\n\nif you already have an account with this email, just sign in below.",
                style: TSTextStyles.body(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isSignUp = false);
                  },
                  child: Text('sign in  →',
                      style: TSTextStyles.title(color: TSColors.lime)),
                ),
              ],
            ),
          );
          return;
        }
      } else {
        await auth.signInWithEmail(_email.text.trim(), _password.text);
      }
      // Signal iOS to prompt "Save Password?" for this AutofillGroup.
      TextInput.finishAutofillContext();
      if (mounted) await _navigateAfterAuth();
    } catch (e) {
      setState(() { _error = humanizeError(e); _hasError = true; });
      TSHaptics.error();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _hasError = false);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TSScaffold(
      style: TSBackgroundStyle.ambient,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: TSSpacing.lg),
          child: TSResponsive.page(Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 52),

              // Logo
              Column(children: [
                Text('✈️', style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Trip', style: TSTextStyles.heading(size: 26)),
                    Text(
                      'squad',
                      style: TSTextStyles.heading(size: 26, color: TSColors.lime)
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isSignUp ? 'join the squad ✈️' : 'welcome back 👋',
                  style: TSTextStyles.caption(),
                ),
              ]).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 40),

              // Email + password (primary) — wrapped in AutofillGroup
              // so iOS offers to save/fill credentials from Keychain.
              AutofillGroup(
                child: Column(children: [
                  ListenableBuilder(
                    listenable: _emailFocus,
                    builder: (context, child) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: TSRadius.md,
                        boxShadow: _emailFocus.hasFocus
                            ? [BoxShadow(color: TSColors.lime.withOpacity(0.25), blurRadius: 16, spreadRadius: 1)]
                            : [],
                      ),
                      child: child,
                    ),
                    child: TSTextField(
                      hint: 'email address',
                      controller: _email,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 10),

                  ListenableBuilder(
                    listenable: _passwordFocus,
                    builder: (context, child) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: TSRadius.md,
                        boxShadow: _passwordFocus.hasFocus
                            ? [BoxShadow(color: TSColors.lime.withOpacity(0.25), blurRadius: 16, spreadRadius: 1)]
                            : [],
                      ),
                      child: child,
                    ),
                    child: TSTextField(
                      hint: 'password',
                      controller: _password,
                      focusNode: _passwordFocus,
                      obscure: true,
                      autofillHints: [
                        _isSignUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                ]),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(TSSpacing.sm),
                  decoration: BoxDecoration(
                    color: TSColors.coralDim(0.12),
                    borderRadius: TSRadius.sm,
                    border: Border.all(color: TSColors.coralDim(0.28)),
                  ),
                  child: Text(_error!, style: TSTextStyles.caption(color: TSColors.coral)),
                ).animate(target: _hasError ? 1 : 0).shake(hz: 4, offset: const Offset(6, 0)),
              ],

              const SizedBox(height: 20),

              TSButton(
                label: _isSignUp ? 'create account ✦' : 'sign in →',
                onTap: _submit,
                loading: _loading,
              ).animate().fadeIn(delay: 450.ms),

              if (!_isSignUp) ...[
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showForgotSheet,
                    child: Text('forgot password?',
                        style: TSTextStyles.caption(color: TSColors.lime)),
                  ),
                ).animate().fadeIn(delay: 475.ms),
              ],

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => setState(() => _isSignUp = !_isSignUp),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: _isSignUp
                          ? 'already have an account? '
                          : "don't have an account? ",
                      style: TSTextStyles.caption(),
                    ),
                    TextSpan(
                      text: _isSignUp ? 'sign in' : 'sign up',
                      style: TSTextStyles.caption(color: TSColors.lime),
                    ),
                  ]),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              // Divider
              Row(children: [
                const Expanded(child: Divider(color: TSColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSSpacing.sm),
                  child: Text('or', style: TSTextStyles.caption()),
                ),
                const Expanded(child: Divider(color: TSColors.border)),
              ]).animate().fadeIn(delay: 550.ms),

              const SizedBox(height: 16),

              // Native Apple button on iOS (required by App Store Review 4.8),
              // fallback OAuth button elsewhere.
              if (Platform.isIOS)
                SizedBox(
                  height: 52,
                  child: SignInWithAppleButton(
                    onPressed: _loading ? () {} : _signInWithApple,
                    style: SignInWithAppleButtonStyle.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).animate().fadeIn(delay: 600.ms)
              else
                _OAuthButton(
                  label: 'continue with apple',
                  emoji: '',
                  bgColor: Colors.white,
                  textColor: Colors.black,
                  onTap: _loading ? null : _signInWithApple,
                ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 10),
              _OAuthButton(
                label: 'continue with google',
                emoji: 'G',
                bgColor: TSColors.s2,
                textColor: TSColors.text,
                onTap: _loading ? null : _signInWithGoogle,
              ).animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 24),

              _LegalFooter().animate().fadeIn(delay: 650.ms),

              const SizedBox(height: 32),
            ],
          )),
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'by continuing you agree to our ',
              style: TSTextStyles.caption(color: TSColors.muted),
            ),
            TextSpan(
              text: 'terms',
              style: TSTextStyles.caption(color: TSColors.lime),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _open('https://gettripsquad.com/terms'),
            ),
            TextSpan(
              text: ' & ',
              style: TSTextStyles.caption(color: TSColors.muted),
            ),
            TextSpan(
              text: 'privacy policy',
              style: TSTextStyles.caption(color: TSColors.lime),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _open('https://gettripsquad.com/privacy'),
            ),
          ]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.emoji,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });
  final String label;
  final String emoji;
  final Color bgColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: TSRadius.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TSTextStyles.title(color: textColor, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Forgot password bottom sheet — collects an email and triggers
//  Supabase's password recovery email. The reset link lands on
//  gettripsquad.com/auth/reset which sets the new password and
//  deep-links back to the app.
// ─────────────────────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.prefill});
  final String prefill;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _ctrl;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.prefill);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _ctrl.text.trim();
    if (!_emailRegex.hasMatch(v)) {
      setState(() => _error = 'enter a valid email');
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: TSColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('forgot password', style: TSTextStyles.heading(size: 20)),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "type the email on your account — we'll send a reset link.",
            style: TSTextStyles.caption(color: TSColors.muted),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          style: TSTextStyles.body(),
          decoration: InputDecoration(
            hintText: 'you@example.com',
            hintStyle: TSTextStyles.body(color: TSColors.muted),
            filled: true,
            fillColor: TSColors.s2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TSTextStyles.caption(color: TSColors.coral)),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.s2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('cancel',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.text)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TSColors.lime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('send reset link',
                    style: TSTextStyles.title(
                        size: 13, color: TSColors.bg)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

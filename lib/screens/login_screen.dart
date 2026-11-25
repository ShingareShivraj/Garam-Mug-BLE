import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_endpoints.dart';
import '../services/auth_service.dart';
import 'login_viewmodel.dart';
import 'my_mugs_screen.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) => const LoginScreen();
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _amber = Color(0xFFFFA21A);
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final LoginViewModel _vm;
  bool _remember = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _vm = LoginViewModel(context.read<AuthService>());
  }

  @override
  void dispose() {
    _vm.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_vm.busy) return;
    FocusScope.of(context).unfocus();
    final ok = await _vm.signIn(_email.text, _password.text, _remember);
    if (!mounted || !ok) return;
    _password.clear();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(builder: (_) => const MyMugsScreen()),
          (_) => false,
    );
  }

  Future<void> _open(Uri url) async {
    FocusScope.of(context).unfocus();
    try {
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show the same message if no external browser can handle the link.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open your browser. Please try again.')),
    );
  }

  static const _espresso = Color(0xFF100C0A);
  static const _cream = Color(0xFFFFF3E7);
  static const _muted = Color(0xFFE0CCBC);
  static const _background = 'assets/images/login_background.png';
  static const _logo = 'assets/images/ic_mug_amber.png';

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF88756C)),
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _amber,
        brightness: Brightness.dark,
      ).copyWith(primary: _amber, onPrimary: _espresso, onSurface: _cream),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xB52A2320),
        hintStyle: const TextStyle(color: _muted),
        prefixIconColor: _cream,
        suffixIconColor: _cream,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: _amber, width: 2),
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: _espresso,
        body: LayoutBuilder(
          builder: (context, viewport) {
            final width = viewport.maxWidth.clamp(0.0, 580.0).toDouble();
            final padding = width < 360 ? 20.0 : 28.0;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Center(
                child: SizedBox(
                  width: width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: viewport.maxHeight),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: ExcludeSemantics(
                              child: ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (rect) => const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black, Colors.black, Colors.transparent],
                                  stops: [0, 0.52, 1],
                                ).createShader(rect),
                                child: Image.asset(
                                  _background,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: _espresso,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SafeArea(
                          minimum: EdgeInsets.fromLTRB(padding, 14, padding, 28),
                          child: ListenableBuilder(
                            listenable: _vm,
                            builder: (context, _) => AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _brand(),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: width * 0.61),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: (width - 2 * padding) * 0.53,
                                        child: _welcome(width),
                                      ),
                                    ),
                                  ),
                                  _form(theme),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brand() => Column(
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Image.asset(
            _logo, width: 36, height: 36, excludeFromSemantics: true,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.coffee_rounded, color: _amber, size: 30),
          ),
          const Text.rich(
            TextSpan(
              text: 'Garam ',
              children: [
                TextSpan(text: 'Mug', style: TextStyle(color: _amber)),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: _cream, fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'SMART HEATING MUG',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, letterSpacing: 3, fontSize: 10,
            fontWeight: FontWeight.w700),
      ),
    ],
  );

  Widget _welcome(double width) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: TextStyle(
            color: _cream,
            fontSize: (width * 0.071).clamp(20.0, 36.0).toDouble(),
            fontWeight: FontWeight.w800,
            height: 1.1,
            shadows: const [Shadow(blurRadius: 16, color: Colors.black)],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 42, height: 3,
          decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sign in to manage your mugs.',
          style: TextStyle(color: _muted, height: 1.35, fontSize: 14,
              shadows: [Shadow(blurRadius: 12, color: Colors.black)]),
        ),
      ],
    ),
  );

  Widget _form(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _label('Email address'),
      const SizedBox(height: 8),
      TextField(
        controller: _email,
        enabled: !_vm.busy,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autocorrect: false,
        autofillHints: const [AutofillHints.username, AutofillHints.email],
        decoration: const InputDecoration(
          hintText: 'Enter your email address',
          prefixIcon: Icon(Icons.mail_outline_rounded),
        ),
      ),
      const SizedBox(height: 18),
      _label('Password'),
      const SizedBox(height: 8),
      TextField(
        controller: _password,
        enabled: !_vm.busy,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _signIn(),
        decoration: InputDecoration(
          hintText: 'Enter your password',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            onPressed: _vm.busy ? null : () => setState(() => _obscure = !_obscure),
            tooltip: _obscure ? 'Show password' : 'Hide password',
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: _cream,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.only(right: 8),
            ),
            onPressed: _vm.busy ? null : () => setState(() => _remember = !_remember),
            icon: Icon(
              _remember ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: _amber,
            ),
            label: Semantics(checked: _remember, child: const Text('Keep me signed in')),
          ),
          TextButton(
            onPressed: _vm.busy ? null : () => _open(ApiEndpoints.forgotPasswordUrl),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
      if (_vm.error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            liveRegion: true,
            child: Text(_vm.error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ),
      const SizedBox(height: 14),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _amber,
          foregroundColor: _espresso,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        onPressed: _vm.busy ? null : _signIn,
        child: _vm.busy
            ? const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Logging in…'),
          ],
        )
            : const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log in'),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const ExcludeSemantics(
        child: Row(
          children: [
            Expanded(child: Divider(color: Color(0xFF68492E))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.coffee_outlined, color: _muted, size: 19),
            ),
            Expanded(child: Divider(color: Color(0xFF68492E))),
          ],
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('New to Garam Mug?', style: TextStyle(color: _cream)),
          TextButton(
            onPressed: _vm.busy ? null : () => _open(ApiEndpoints.signupUrl),
            child: const Text('Register', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    ],
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: _cream, fontWeight: FontWeight.w700, fontSize: 15),
  );
}

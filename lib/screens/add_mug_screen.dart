import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/registered_mug.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/mug_registration_service.dart';

class AddMugScreen extends StatefulWidget {
  const AddMugScreen({super.key});

  @override
  State<AddMugScreen> createState() => _AddMugScreenState();
}

class _AddMugScreenState extends State<AddMugScreen> {
  final _serial = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final service = MugRegistrationService(context.read<AuthService>());
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final mug = await service.registerMug(_serial.text);
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).pop<RegisteredMug>(mug);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not register your mug. Please try again.');
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Register Mug')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                          child: const Icon(Icons.coffee_rounded, size: 30),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Add your Garam Mug', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      const Text('Enter the serial number printed on your mug or its packaging.'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _serial,
                        enabled: !_busy,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your mug serial number.'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Mug serial number',
                          hintText: 'e.g. GM000101',
                          prefixIcon: Icon(Icons.numbers_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(_error!, style: TextStyle(color: colors.error)),
                          ),
                        ),
                      const SizedBox(height: 22),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        onPressed: _busy ? null : _register,
                        child: Text(_busy ? 'Registering…' : 'Register Mug'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

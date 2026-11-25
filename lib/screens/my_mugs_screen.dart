import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/registered_mug.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/mug_registration_service.dart';
import 'add_mug_screen.dart';
import 'login_screen.dart';
import 'scan_screen.dart';

class MyMugsScreen extends StatefulWidget {
  const MyMugsScreen({super.key});

  @override
  State<MyMugsScreen> createState() => _MyMugsScreenState();
}

class _MyMugsScreenState extends State<MyMugsScreen> {
  late final AuthService _auth;
  late final MugRegistrationService _service;
  late Future<List<RegisteredMug>> _mugs;
  bool _opening = false;
  bool _offeredFirstMug = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _service = MugRegistrationService(_auth);
    _mugs = _service.getMyRegisteredMugs();
  }

  void _reload() {
    final pending = _service.getMyRegisteredMugs();
    setState(() {
      _mugs = pending;
    });
  }

  void _openFirstMugForm() {
    if (_offeredFirstMug) return;
    _offeredFirstMug = true;
    final checkedList = _mugs;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(checkedList, _mugs) ||
          ModalRoute.of(context)?.isCurrent != true) {
        _offeredFirstMug = false;
        return;
      }
      _add();
    });
  }

  Future<void> _add() async {
    if (_opening) return;
    _opening = true;
    try {
      final mug = await Navigator.of(context).push<RegisteredMug>(
        MaterialPageRoute(builder: (_) => const AddMugScreen()),
      );
      if (!mounted || mug == null) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mug ${mug.serialNo} is registered to your account.')),
      );
    } finally {
      _opening = false;
    }
  }

  Future<void> _signInAgain() async {
    if (_opening) return;
    _opening = true;
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not clear the saved login. Please try again.')),
      );
    } finally {
      _opening = false;
    }
  }

  Future<void> _connect() async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
      if (mounted) _reload();
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My Mugs')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: FutureBuilder<List<RegisteredMug>>(
              future: _mugs,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(semanticsLabel: 'Loading your mugs'),
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final expired = error is ApiException && error.isSessionExpired;
                  final wrongAccount = error is ApiException &&
                      error.errorCode == 'CUSTOMER_ACCOUNT_REQUIRED';
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(Icons.info_outline, size: 46),
                      const SizedBox(height: 14),
                      Text(expired ? 'Please sign in again' : 'Could not load your mugs',
                          textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(error is ApiException ? error.message : 'Please try again.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: expired ? _signInAgain : _reload,
                        child: Text(expired ? 'Log in' : 'Retry'),
                      ),
                      if (wrongAccount)
                        TextButton(
                          onPressed: _signInAgain,
                          child: const Text('Switch account'),
                        ),
                    ],
                  );
                }
                final mugs = snapshot.requireData;
                if (mugs.isEmpty) {
                  _openFirstMugForm();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
                    children: [
                      Icon(Icons.coffee_rounded, size: 66, color: theme.colorScheme.primary),
                      const SizedBox(height: 20),
                      Text('Add your first mug', textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      const Text('Register your mug using its serial number to get started.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your Garam Mug'),
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    try {
                      await _mugs;
                    } catch (_) {
                      // The FutureBuilder displays the error and Retry button.
                    }
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text('Your registered mugs', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      const Text('Connect to a nearby mug to control it.'),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _connect,
                        icon: const Icon(Icons.bluetooth),
                        label: const Text('Connect via Bluetooth'),
                      ),
                      const SizedBox(height: 18),
                      for (final mug in mugs)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.coffee_outlined)),
                            title: Text(mug.serialNo),
                            subtitle: Text(mug.registrationDate == null
                                ? 'Registered'
                                : 'Registered • ${MaterialLocalizations.of(context).formatMediumDate(mug.registrationDate!)}'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Another Mug'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

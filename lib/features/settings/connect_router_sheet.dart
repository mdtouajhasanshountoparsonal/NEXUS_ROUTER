import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../data/providers.dart';
import '../../data/tplink/router_credentials.dart';
import '../../data/tplink/tplink_adapter.dart';
import '../../data/tplink/tplink_client.dart';

Future<bool?> showConnectRouterSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ConnectRouterSheet(),
  );
}

class _ConnectRouterSheet extends ConsumerStatefulWidget {
  const _ConnectRouterSheet();

  @override
  ConsumerState<_ConnectRouterSheet> createState() =>
      _ConnectRouterSheetState();
}

class _ConnectRouterSheetState extends ConsumerState<_ConnectRouterSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address;
  late final TextEditingController _username;
  final TextEditingController _password = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(routerCredentialsProvider);
    _address = TextEditingController(text: existing?.host ?? '192.168.0.1');
    _username = TextEditingController(text: existing?.username ?? 'admin');
  }

  @override
  void dispose() {
    _address.dispose();
    _username.dispose();
    _password.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    TplinkV6Adapter? probe;
    try {
      final host = normalizeRouterHost(_address.text);
      final username = _username.text.trim();
      final password = _password.text;
      probe = TplinkV6Adapter(
        host: host,
        username: username,
        password: password,
      );
      await probe.fetchStatus().timeout(const Duration(seconds: 12));

      await ref
          .read(routerCredentialsProvider.notifier)
          .connect(
            RouterCredentials(
              host: host,
              username: username,
              password: password,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      _fail(error.message.toString());
    } on RouterException catch (error) {
      _fail(error.message);
    } on TimeoutException {
      _fail(
        'The router did not answer in time. Move closer to the Wi-Fi '
        'and try again.',
      );
    } catch (_) {
      _fail('Could not connect. Check the address and credentials.');
    } finally {
      probe?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final maxHeight = (size.height - bottomInset - 24)
        .clamp(320.0, size.height * 0.94)
        .toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.router_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect your router',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'TL-WR840N · local admin API',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _address,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Admin address',
                          hintText: '192.168.0.1',
                          prefixIcon: Icon(Icons.lan_rounded, size: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the router admin address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the admin username.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        enabled: !_busy,
                        decoration: InputDecoration(
                          labelText: 'Admin password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter the router admin password.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 17,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Credentials stay in Android secure storage and are '
                                'sent only to the local admin panel. The panel is '
                                'HTTP-only, so use this on your home network.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.link_rounded, size: 18),
                        label: Text(
                          _busy ? 'Testing connection…' : 'Test & connect',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'After 10 failed logins the router locks admin access for '
                      'about 2 hours. Check the password before retrying.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

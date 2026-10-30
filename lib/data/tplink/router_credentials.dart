import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RouterCredentials {
  const RouterCredentials({
    required this.host,
    required this.username,
    required this.password,
  });

  final String host;
  final String username;
  final String password;

  bool get isConfigured =>
      host.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  RouterCredentials copyWith({
    String? host,
    String? username,
    String? password,
  }) {
    return RouterCredentials(
      host: host ?? this.host,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

class RouterCredentialsStore {
  const RouterCredentialsStore(this._storage);

  static const _hostKey = 'router.host';
  static const _usernameKey = 'router.username';
  static const _passwordKey = 'router.password';

  final FlutterSecureStorage _storage;

  Future<RouterCredentials?> read() async {
    final host = await _storage.read(key: _hostKey);
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    if (host == null ||
        username == null ||
        password == null ||
        host.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      return null;
    }
    return RouterCredentials(
      host: host,
      username: username,
      password: password,
    );
  }

  Future<void> write(RouterCredentials credentials) async {
    await _storage.write(key: _hostKey, value: credentials.host);
    await _storage.write(key: _usernameKey, value: credentials.username);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _hostKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }
}

/// Normalises an admin address and refuses anything that is not on the local
/// network. This keeps the router password from being sent off-LAN by mistake.
String normalizeRouterHost(String raw) {
  var value = raw.trim();
  if (value.isEmpty) {
    throw const FormatException('Enter the router admin address.');
  }

  final lower = value.toLowerCase();
  if (lower.startsWith('https://')) {
    throw const FormatException(
      'This firmware only serves the admin panel over HTTP.',
    );
  }
  if (lower.startsWith('http://')) {
    value = value.substring(7);
  }
  value = value.split('/').first.trim();
  if (value.isEmpty) {
    throw const FormatException('Enter the router admin address.');
  }

  final uri = Uri.tryParse('http://$value');
  if (uri == null || uri.host.isEmpty) {
    throw const FormatException('That admin address is not valid.');
  }
  if (uri.userInfo.isNotEmpty) {
    throw const FormatException('Do not include a username in the address.');
  }

  final host = uri.host.toLowerCase();
  final isPrivateIpv4 = _privateIpv4.hasMatch(host);
  final isKnownName = _allowedNames.contains(host);
  if (!isPrivateIpv4 && !isKnownName) {
    throw const FormatException('Use a local address such as 192.168.0.1.');
  }

  final port = uri.hasPort ? uri.port : 80;
  return port == 80 ? host : '$host:$port';
}

final RegExp _privateIpv4 = RegExp(
  r'^(10\.\d{1,3}\.\d{1,3}\.\d{1,3}'
  r'|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}'
  r'|192\.168\.\d{1,3}\.\d{1,3})$',
);

final Set<String> _allowedNames = {
  'tplinkwifi.net',
  'www.tplinkwifi.net',
  'tplinklogin.net',
  'www.tplinklogin.net',
};

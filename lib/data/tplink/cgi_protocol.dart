/// Encoder/decoder for the TL-WR840N (v6) `POST /cgi` data model.
///
/// Request shape:
/// ```
/// [OBJECT#instanceStack#parentStack]blockIndex,paramCount\r\n
/// key=value\r\n
/// ```
/// The URL holds the action codes, e.g. `/cgi?1&1&5` for two reads and a list
/// read. Response headers are `[instanceStack]blockIndex` followed by
/// `key=value` lines and a final `[error]code`.
library;

const String kZeroStack = '0,0,0,0,0,0';

enum CgiVerb {
  read(1),
  write(2),
  add(3),
  remove(4),
  list(5),
  selection(6),
  operation(7),
  cgi(8);

  const CgiVerb(this.code);

  final int code;
}

class CgiRequest {
  CgiRequest();

  final List<_CgiAction> _actions = [];

  bool get isEmpty => _actions.isEmpty;

  String get query => _actions.map((action) => action.verb.code).join('&');

  String get summary => _actions
      .map((action) => '${action.verb.name}:${action.object}')
      .join(', ');

  String get body {
    final buffer = StringBuffer();
    for (var i = 0; i < _actions.length; i++) {
      final action = _actions[i];
      buffer.write(
        '[${action.object}#${action.stack}#${action.parentStack}]'
        '$i,${action.params.length}\r\n',
      );
      for (final param in action.params) {
        buffer
          ..write(param)
          ..write('\r\n');
      }
    }
    return buffer.toString();
  }

  CgiRequest read(
    String object,
    List<String> fields, {
    String stack = kZeroStack,
  }) {
    return _add(CgiVerb.read, object, stack, kZeroStack, fields);
  }

  CgiRequest list(
    String object,
    List<String> fields, {
    String stack = kZeroStack,
    String parentStack = kZeroStack,
  }) {
    return _add(CgiVerb.list, object, stack, parentStack, fields);
  }

  CgiRequest selection(
    String object,
    List<String> fields, {
    String stack = kZeroStack,
    String parentStack = kZeroStack,
  }) {
    return _add(CgiVerb.selection, object, stack, parentStack, fields);
  }

  CgiRequest write(
    String object,
    Map<String, String> values, {
    String stack = kZeroStack,
  }) {
    return _add(
      CgiVerb.write,
      object,
      stack,
      kZeroStack,
      values.entries.map((entry) => '${entry.key}=${entry.value}').toList(),
    );
  }

  CgiRequest add(
    String object,
    Map<String, String> values, {
    String stack = kZeroStack,
    String parentStack = kZeroStack,
  }) {
    return _add(
      CgiVerb.add,
      object,
      stack,
      parentStack,
      values.entries.map((entry) => '${entry.key}=${entry.value}').toList(),
    );
  }

  CgiRequest remove(String object, {String stack = kZeroStack}) {
    return _add(CgiVerb.remove, object, stack, kZeroStack, const []);
  }

  CgiRequest operation(String object, {String stack = kZeroStack}) {
    return _add(CgiVerb.operation, object, stack, kZeroStack, const []);
  }

  CgiRequest _add(
    CgiVerb verb,
    String object,
    String stack,
    String parentStack,
    List<String> params,
  ) {
    _actions.add(
      _CgiAction(
        verb: verb,
        object: object,
        stack: stack,
        parentStack: parentStack,
        params: List.unmodifiable(params),
      ),
    );
    return this;
  }
}

class _CgiAction {
  const _CgiAction({
    required this.verb,
    required this.object,
    required this.stack,
    required this.parentStack,
    required this.params,
  });

  final CgiVerb verb;
  final String object;
  final String stack;
  final String parentStack;
  final List<String> params;
}

const Set<String> _credentialAttributes = {
  'username',
  'password',
  'x_tp_bpausername',
  'x_tp_bpapassword',
  'presharedkey',
  'x_tp_presharedkey',
  'wepkey',
  'radiusserverpassword',
  'x_tp_radiusserverpassword',
};

class CgiObject {
  CgiObject(this.stack);

  final String stack;
  final Map<String, String> attributes = {};

  /// Attribute names are normalised to lower case because this firmware mixes
  /// `SSID`/`status`/`Enabled`/`enabled` between requests and responses.
  String? operator [](String key) => attributes[key.toLowerCase()];

  bool flag(String key) {
    final value = this[key]?.toLowerCase();
    return value == '1' || value == 'true';
  }

  int number(String key) => int.tryParse(this[key] ?? '') ?? 0;
}

class CgiResponse {
  CgiResponse._();

  final Map<int, List<CgiObject>> _blocks = {};
  final List<String> cgiScripts = [];
  int errorCode = 0;

  List<CgiObject> objects(int block) => _blocks[block] ?? const [];

  CgiObject? first(int block) {
    final list = objects(block);
    return list.isEmpty ? null : list.first;
  }

  static CgiResponse parse(String text) {
    final response = CgiResponse._();
    CgiObject? current;

    for (final raw in text.split('\n')) {
      final line = raw.endsWith('\r') ? raw.substring(0, raw.length - 1) : raw;
      if (line.isEmpty) continue;

      if (line.startsWith('[')) {
        final close = line.indexOf(']');
        if (close < 0) continue;
        final header = line.substring(1, close);
        final rest = line.substring(close + 1).trim();

        if (header == 'error') {
          response.errorCode = int.tryParse(rest) ?? -1;
          current = null;
          continue;
        }
        if (header == 'cgi') {
          response.cgiScripts.add(rest);
          current = null;
          continue;
        }

        final block = int.tryParse(rest);
        if (block == null) continue;
        current = CgiObject(header);
        response._blocks.putIfAbsent(block, () => []).add(current);
        continue;
      }

      if (current == null) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).toLowerCase();
      // Unfiltered WAN/WLAN reads contain PPPoE and Wi-Fi credentials. Drop
      // them at the parser boundary so they never live in app state or logs.
      if (_credentialAttributes.contains(key)) continue;
      current.attributes[key] = line.substring(separator + 1);
    }

    return response;
  }
}

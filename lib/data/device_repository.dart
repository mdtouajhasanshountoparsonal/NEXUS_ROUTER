import 'package:sqflite/sqflite.dart';

import '../core/db/app_database.dart';
import '../core/models/device.dart';
import '../core/models/network_event.dart';
import 'router_adapter.dart';

class DeviceRepository {
  DeviceRepository(this._db, this._adapter);

  final AppDatabase _db;
  final RouterAdapter _adapter;

  Future<List<Device>> fetchAndSync() async {
    final db = await _db.database;
    await _prepareSource(db);
    if (_adapter.isDemo) {
      await _seedIfNeeded(db);
    }

    final live = await _adapter.fetchDevices();
    final rows = await db.query('devices');
    final local = <String, Device>{
      for (final row in rows) row['mac'] as String: Device.fromMap(row),
    };

    final merged = <Device>[];
    final batch = db.batch();
    final now = DateTime.now();

    for (final fresh in live) {
      final existing = local[fresh.mac];
      final device = existing == null
          ? fresh
          : existing.copyWith(
              vendor: fresh.vendor,
              type: fresh.type,
              ip: fresh.ip,
              online: fresh.online,
              blocked: _adapter.isDemo ? existing.blocked : fresh.blocked,
              lastSeen: fresh.online ? now : existing.lastSeen,
            );
      batch.insert(
        'devices',
        device.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      merged.add(device);
    }

    if (!_adapter.isDemo) {
      final liveMacs = live.map((device) => device.mac).toSet();
      final stale = local.keys
          .where((mac) => !liveMacs.contains(mac))
          .toList(growable: false);
      if (stale.isNotEmpty) {
        await db.delete(
          'devices',
          where: 'mac IN (${List.filled(stale.length, '?').join(',')})',
          whereArgs: stale,
        );
      }
    }

    await batch.commit(noResult: true);
    merged.sort(_compareDevices);
    return merged;
  }

  Future<void> _prepareSource(Database db) async {
    final desired = _adapter.isDemo ? 'demo' : 'live';
    final rows = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: const ['source'],
      limit: 1,
    );
    final current = rows.isEmpty ? null : rows.first['value'] as String?;
    if (current == desired) return;

    await db.delete('devices');
    await db.delete('events');
    await db.insert('meta', {
      'key': 'source',
      'value': desired,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  int _compareDevices(Device a, Device b) {
    if (a.online != b.online) return a.online ? -1 : 1;
    if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  Future<void> _seedIfNeeded(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM devices'),
        ) ??
        0;
    if (count > 0) return;

    final devices = await _adapter.fetchDevices();
    final events = await _adapter.seedEvents();
    final batch = db.batch();
    for (final device in devices) {
      batch.insert('devices', device.toMap());
    }
    for (final event in events) {
      batch.insert('events', event.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveDevice(Device device) async {
    final db = await _db.database;
    await db.insert(
      'devices',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> appendEvent(NetworkEvent event) async {
    final db = await _db.database;
    await db.insert('events', event.toMap());
  }

  Future<List<NetworkEvent>> fetchEvents({String? mac, int limit = 60}) async {
    final db = await _db.database;
    final rows = await db.query(
      'events',
      where: mac == null ? null : 'mac = ?',
      whereArgs: mac == null ? null : [mac],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(NetworkEvent.fromMap).toList();
  }

  Future<Device> setBlocked(Device device, bool blocked) async {
    final verified = await _adapter.setBlocked(
      device.mac,
      blocked,
      name: device.name,
    );
    if (!verified) {
      throw const RouterActionException(
        'The router did not confirm this change. Nothing was modified.',
      );
    }

    final updated = device.copyWith(blocked: blocked);
    await saveDevice(updated);
    await appendEvent(
      NetworkEvent(
        mac: device.mac,
        kind: blocked ? EventKind.blocked : EventKind.unblocked,
        severity: blocked ? EventSeverity.warning : EventSeverity.info,
        title: '${device.name} ${blocked ? 'blocked' : 'unblocked'}',
        detail: 'Policy change verified on router',
        createdAt: DateTime.now(),
      ),
    );
    return updated;
  }

  Future<void> clearEvents() async {
    final db = await _db.database;
    await db.delete('events');
  }
}

class RouterActionException implements Exception {
  const RouterActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

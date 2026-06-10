// lib/services/address_storage_service.dart
// ══════════════════════════════════════════════════════════════
//  AddressStorageService
//  Persist / load saved addresses from SharedPreferences.
//  Data survives app restarts — stored as JSON list.
// ══════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_address_model.dart';

class AddressStorageService {
  static const _key = 'saved_delivery_addresses_v1';

  // ── Read ────────────────────────────────────────────────────
  static Future<List<SavedAddress>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list  = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write (upsert) ─────────────────────────────────────────
  /// Saves an address. If isDefault == true, clears default on all others.
  static Future<void> save(SavedAddress address) async {
    final all = await getAll();

    // Remove existing entry with same id (update)
    all.removeWhere((a) => a.id == address.id);

    // If new address is default, clear default on others
    List<SavedAddress> updated;
    if (address.isDefault) {
      updated = all.map((a) => a.copyWith(isDefault: false)).toList();
    } else {
      updated = all;
    }

    // Insert at top
    updated.insert(0, address);
    await _persist(updated);
  }

  // ── Set default ────────────────────────────────────────────
  static Future<void> setDefault(String id) async {
    final all     = await getAll();
    final updated = all.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    await _persist(updated);
  }

  // ── Delete ─────────────────────────────────────────────────
  static Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((a) => a.id == id);

    // If deleted address was default, promote first remaining as default
    if (all.isNotEmpty && !all.any((a) => a.isDefault)) {
      all[0] = all[0].copyWith(isDefault: true);
    }
    await _persist(all);
  }

  // ── Clear all ───────────────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ── Internal ────────────────────────────────────────────────
  static Future<void> _persist(List<SavedAddress> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(list.map((a) => a.toJson()).toList()),
    );
  }
}
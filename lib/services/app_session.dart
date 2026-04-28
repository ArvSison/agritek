import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static const _kToken = 'auth_token';
  static const _kGate = 'admin_gate_token';
  static const _kUid = 'user_id';
  static const _kUsername = 'user_username';
  static const _kEmail = 'user_email';
  static const _kRole = 'user_role';
  static const _kDisplayName = 'user_display_name';
  static const _kAvatarUrl = 'user_avatar_url';

  static SharedPreferences? _prefs;
  static String? authToken;
  static String? adminGateToken;
  static int? userId;
  static String? username;
  static String? email;
  static String? userRole;
  static String? displayName;
  static String? avatarUrl;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    authToken = _prefs!.getString(_kToken);
    adminGateToken = _prefs!.getString(_kGate);
    userId = _prefs!.getInt(_kUid);
    username = _prefs!.getString(_kUsername);
    email = _prefs!.getString(_kEmail);
    userRole = _prefs!.getString(_kRole);
    displayName = _prefs!.getString(_kDisplayName);
    avatarUrl = _prefs!.getString(_kAvatarUrl);
  }

  static Future<void> setAuthToken(String? token) async {
    _prefs ??= await SharedPreferences.getInstance();
    authToken = token;
    if (token == null || token.isEmpty) {
      await _prefs!.remove(_kToken);
    } else {
      await _prefs!.setString(_kToken, token);
    }
  }

  static Future<void> setUserId(int? id) async {
    _prefs ??= await SharedPreferences.getInstance();
    userId = id;
    if (id == null) {
      await _prefs!.remove(_kUid);
    } else {
      await _prefs!.setInt(_kUid, id);
    }
  }

  static Future<void> setAdminGateToken(String? token) async {
    _prefs ??= await SharedPreferences.getInstance();
    adminGateToken = token;
    if (token == null || token.isEmpty) {
      await _prefs!.remove(_kGate);
    } else {
      await _prefs!.setString(_kGate, token);
    }
  }

  static Future<void> clearAuth() async {
    await setAuthToken(null);
    await setUserId(null);
  }

  static Future<void> clearAdminGate() async {
    await setAdminGateToken(null);
  }

  /// Updates username/email/role plus optional display name and avatar from API `user` map.
  static Future<void> applyFromProfileRow(Map<String, dynamic> row) async {
    _prefs ??= await SharedPreferences.getInstance();
    final un = (row['username'] ?? '') as String;
    final em = row['email'] as String?;
    final role = (row['role'] ?? 'buyer') as String;
    await setProfile(username: un, email: em, role: role);
    final dn = (row['display_name'] as String?)?.trim();
    displayName = (dn != null && dn.isNotEmpty) ? dn : null;
    final av = (row['avatar_url'] as String?)?.trim();
    avatarUrl = (av != null && av.isNotEmpty) ? av : null;
    if (displayName == null || displayName!.isEmpty) {
      await _prefs!.remove(_kDisplayName);
    } else {
      await _prefs!.setString(_kDisplayName, displayName!);
    }
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      await _prefs!.remove(_kAvatarUrl);
    } else {
      await _prefs!.setString(_kAvatarUrl, avatarUrl!);
    }
  }

  static Future<void> setProfile({
    required String username,
    String? email,
    required String role,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    AppSession.username = username;
    AppSession.email = email;
    AppSession.userRole = role;
    await _prefs!.setString(_kUsername, username);
    if (email == null || email.isEmpty) {
      await _prefs!.remove(_kEmail);
    } else {
      await _prefs!.setString(_kEmail, email);
    }
    await _prefs!.setString(_kRole, role);
  }

  /// Clears auth, admin gate, user id, and cached profile (call on logout).
  static Future<void> clearAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    await setAuthToken(null);
    await setUserId(null);
    await setAdminGateToken(null);
    username = null;
    email = null;
    userRole = null;
    displayName = null;
    avatarUrl = null;
    await _prefs!.remove(_kUsername);
    await _prefs!.remove(_kEmail);
    await _prefs!.remove(_kRole);
    await _prefs!.remove(_kDisplayName);
    await _prefs!.remove(_kAvatarUrl);
  }
}

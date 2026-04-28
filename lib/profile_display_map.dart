import 'services/app_session.dart';

/// Maps API `user` object (login or profile.php) to the UI map used by Me / Edit Profile.
Map<String, String> mapProfileForUi(Map<String, dynamic> row) {
  final un = (row['username'] ?? '') as String;
  final dn = (row['display_name'] as String?)?.trim();
  final name = (dn != null && dn.isNotEmpty) ? dn : (un.isNotEmpty ? un : 'Account');
  final role = (row['role'] ?? AppSession.userRole ?? '') as String;
  final bd = row['birth_date'];
  String birth = '';
  if (bd != null && '$bd'.trim().isNotEmpty) {
    birth = '$bd'.trim();
    if (birth.contains(' ')) birth = birth.split(' ').first;
    if (birth.length > 10) birth = birth.substring(0, 10);
  }
  final av = (row['avatar_url'] as String?)?.trim() ?? '';
  return {
    'username': un,
    'name': name,
    'email': (row['email'] as String?)?.trim() ?? '',
    'address': (row['address'] as String?)?.trim() ?? '',
    'phone': (row['phone'] as String?)?.trim() ?? '',
    'gender': (row['gender'] as String?)?.trim() ?? '',
    'birth': birth,
    'businessType': role,
    'avatarUrl': av,
  };
}

Map<String, String> mapProfileFallbackSession() {
  return mapProfileForUi({
    'username': AppSession.username ?? '',
    'email': AppSession.email,
    'role': AppSession.userRole ?? '',
    'display_name': AppSession.displayName,
    'address': null,
    'phone': null,
    'gender': null,
    'birth_date': null,
    'avatar_url': AppSession.avatarUrl,
  });
}

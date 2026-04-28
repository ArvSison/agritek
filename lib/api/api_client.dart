import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/app_session.dart';
import 'api_config.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _http;

  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool admin = false, bool includeAuth = true}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (includeAuth) {
      final t = AppSession.authToken;
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    if (admin) {
      final g = AppSession.adminGateToken;
      if (g != null && g.isNotEmpty) {
        h['X-Admin-Gate'] = g;
      }
    }
    return h;
  }

  Map<String, dynamic> _decodeMap(http.Response res) {
    final dynamic data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) {
      throw ApiException('Invalid server response');
    }
    return data;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _http.post(
      _uri('/login.php'),
      headers: _headers(includeAuth: false),
      body: jsonEncode({'username': username, 'password': password}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Login failed') as String);
    }
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Login succeeded but server returned no token');
    }
    await AppSession.setAuthToken(token);
    return json;
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await _http.post(
      _uri('/register.php'),
      headers: _headers(includeAuth: false),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Register failed') as String);
    }
  }

  Future<String> verifyAdminPin(String pin) async {
    final res = await _http.post(
      _uri('/admin_verify_pin.php'),
      headers: _headers(includeAuth: false),
      body: jsonEncode({'pin': pin}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Wrong PIN') as String);
    }
    final gate = json['admin_gate_token'] as String?;
    if (gate == null || gate.isEmpty) throw ApiException('No gate token');
    await AppSession.setAdminGateToken(gate);
    return gate;
  }

  Future<List<ApiProduct>> productsPublic() async {
    final res = await _http.get(_uri('/products.php'));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Failed to load products') as String);
    }
    final raw = (json['products'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiProduct.fromJson)
        .toList();
  }

  Future<List<ApiProduct>> productsFeed({String mode = 'following'}) async {
    final res = await _http.get(_uri('/products_feed.php?mode=$mode'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Failed to load feed') as String);
    }
    final raw = (json['products'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiProduct.fromJson)
        .toList();
  }

  Future<List<ApiProduct>> farmerMyProducts() async {
    final res = await _http.get(_uri('/farmer_my_products.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Failed to load farmer products') as String);
    }
    final raw = (json['products'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiProduct.fromJson)
        .toList();
  }

  Future<void> farmerAddProduct(Map<String, dynamic> body) async {
    final res = await _http.post(
      _uri('/farmer_products.php'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Add product failed') as String);
    }
  }

  Future<void> farmerUpdateProduct(Map<String, dynamic> body) async {
    final res = await _http.patch(
      _uri('/farmer_products.php'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Update product failed') as String);
    }
  }

  /// Multipart upload (farmer only). Returns public image URL for `image_url`.
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _http.get(_uri('/profile.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Failed to load profile') as String);
    }
    final u = json['user'];
    if (u is! Map<String, dynamic>) {
      throw ApiException('Invalid profile response');
    }
    return u;
  }

  Future<Map<String, dynamic>> patchProfile(Map<String, dynamic> body) async {
    final res = await _http.patch(
      _uri('/profile.php'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Profile update failed') as String);
    }
    final u = json['user'];
    if (u is! Map<String, dynamic>) {
      throw ApiException('Invalid profile response');
    }
    return u;
  }

  /// Any logged-in role. Returns public image URL; save with [patchProfile] `avatar_url`.
  Future<String> uploadProfileImage(List<int> bytes, {String filename = 'avatar.jpg'}) async {
    final token = AppSession.authToken;
    if (token == null || token.isEmpty) {
      throw ApiException('Not logged in');
    }
    final uri = _uri('/upload_profile_image.php');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
      ),
    );
    final streamed = await _http.send(request);
    final res = await http.Response.fromStream(streamed);
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Image upload failed') as String);
    }
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Upload succeeded but no URL returned');
    }
    return url;
  }

  Future<String> farmerUploadProductImage(List<int> bytes, {String filename = 'photo.jpg'}) async {
    final token = AppSession.authToken;
    if (token == null || token.isEmpty) {
      throw ApiException('Not logged in');
    }
    final uri = _uri('/upload_product_image.php');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
      ),
    );
    final streamed = await _http.send(request);
    final res = await http.Response.fromStream(streamed);
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Image upload failed') as String);
    }
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ApiException('Upload succeeded but no URL returned');
    }
    return url;
  }

  Future<List<ApiCartLine>> cartGet() async {
    final res = await _http.get(_uri('/cart.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Cart failed') as String);
    }
    final raw = (json['items'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiCartLine.fromJson)
        .toList();
  }

  Future<void> cartAdd({required int productId, int qty = 1}) async {
    final res = await _http.post(
      _uri('/cart.php'),
      headers: _headers(),
      body: jsonEncode({'product_id': productId, 'qty': qty}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Add to cart failed') as String);
    }
  }

  Future<void> cartRemove(int productId) async {
    final res = await _http.delete(_uri('/cart.php?product_id=$productId'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Remove failed') as String);
    }
  }

  Future<ApiOrder> checkoutCart() async {
    final res = await _http.post(_uri('/orders.php'), headers: _headers(), body: jsonEncode({}));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Checkout failed') as String);
    }
    return ApiOrder.fromJson(json['order'] as Map<String, dynamic>);
  }

  Future<List<ApiOrder>> ordersMine() async {
    final res = await _http.get(_uri('/orders.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Orders failed') as String);
    }
    final raw = (json['orders'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiOrder.fromJson)
        .toList();
  }

  Future<ApiOrder> orderAction({required int id, required String action}) async {
    final res = await _http.patch(
      _uri('/orders.php'),
      headers: _headers(),
      body: jsonEncode({'id': id, 'action': action}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Order update failed') as String);
    }
    return ApiOrder.fromJson(json['order'] as Map<String, dynamic>);
  }

  Future<List<ApiNotification>> notificationsMine() async {
    final res = await _http.get(_uri('/notifications.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Notifications failed') as String);
    }
    final raw = (json['notifications'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiNotification.fromJson)
        .toList();
  }

  Future<void> notificationMarkRead(int id) async {
    final res = await _http.patch(_uri('/notifications.php?id=$id'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Mark read failed') as String);
    }
  }

  Future<List<ApiPublicUser>> usersDiscovery(String role) async {
    final res = await _http.get(_uri('/users_discovery.php?role=$role'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Users failed') as String);
    }
    final raw = (json['users'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiPublicUser.fromJson)
        .toList();
  }

  Future<void> followUser(int userId) async {
    final res = await _http.post(
      _uri('/follows.php'),
      headers: _headers(),
      body: jsonEncode({'user_id': userId}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Follow failed') as String);
    }
  }

  Future<void> unfollowUser(int userId) async {
    final res = await _http.delete(
      _uri('/follows.php?user_id=$userId'),
      headers: _headers(),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Unfollow failed') as String);
    }
  }

  Future<List<ApiPublicUser>> followingList() async {
    final res = await _http.get(_uri('/follows.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Failed to load following') as String);
    }
    final raw = (json['following'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiPublicUser.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> messagesWith(int peerId) async {
    final res = await _http.get(_uri('/messages.php?with=$peerId'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Messages failed') as String);
    }
    final raw = (json['messages'] as List?) ?? const [];
    return raw.whereType<Map>().map((m) => m.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  Future<void> sendMessage({required int toUserId, required String body}) async {
    final res = await _http.post(
      _uri('/messages.php'),
      headers: _headers(),
      body: jsonEncode({'to_user_id': toUserId, 'body': body}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Send failed') as String);
    }
  }

  Future<List<Map<String, dynamic>>> messageConversations() async {
    final res = await _http.get(_uri('/messages.php'), headers: _headers());
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'Conversations failed') as String);
    }
    final raw = (json['conversations'] as List?) ?? const [];
    return raw.whereType<Map>().map((m) => m.map((k, v) => MapEntry(k.toString(), v))).toList();
  }

  Future<List<Map<String, dynamic>>> adminUsers() async {
    final res = await _http.get(_uri('/admin_users.php'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'admin users failed') as String);
    }
    return ((json['users'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> adminUserApprove(int id) async {
    final res = await _http.patch(_uri('/admin_users.php?id=$id&action=approve'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'approve failed') as String);
    }
  }

  Future<void> adminUserReject(int id) async {
    final res = await _http.patch(_uri('/admin_users.php?id=$id&action=reject'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'reject failed') as String);
    }
  }

  Future<void> adminUserDelete(int id) async {
    final res = await _http.delete(_uri('/admin_users.php?id=$id'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'delete failed') as String);
    }
  }

  Future<void> adminUserUpdate(Map<String, dynamic> body) async {
    final res = await _http.put(_uri('/admin_users.php'), headers: _headers(admin: true), body: jsonEncode(body));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'update failed') as String);
    }
  }

  Future<List<Map<String, dynamic>>> adminProductsRaw() async {
    final res = await _http.get(_uri('/admin_products.php'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'admin products failed') as String);
    }
    return ((json['products'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> adminProductAction({required int id, required String action}) async {
    final res = await _http.patch(
      _uri('/admin_products.php?id=$id&action=$action'),
      headers: _headers(admin: true),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'product action failed') as String);
    }
  }

  Future<void> adminProductDelete({required int id, required String reason}) async {
    final res = await _http.patch(
      _uri('/admin_products.php?id=$id&action=delete'),
      headers: _headers(admin: true),
      body: jsonEncode({'reason': reason}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'product delete failed') as String);
    }
  }

  Future<List<Map<String, dynamic>>> adminOrdersRaw() async {
    final res = await _http.get(_uri('/admin_orders.php'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'admin orders failed') as String);
    }
    return ((json['orders'] as List?) ?? const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> adminOrderSetStatus({required int id, required String status}) async {
    final res = await _http.patch(
      _uri('/admin_orders.php'),
      headers: _headers(admin: true),
      body: jsonEncode({'id': id, 'status': status}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'admin order patch failed') as String);
    }
  }

  Future<List<ApiNotification>> adminNotifications() async {
    final res = await _http.get(_uri('/admin_notifications.php'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'admin notifications failed') as String);
    }
    final raw = (json['notifications'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ApiNotification.fromJson)
        .toList();
  }

  Future<void> adminNotificationMarkRead(int id) async {
    final res = await _http.patch(_uri('/admin_notifications.php?id=$id'), headers: _headers(admin: true));
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'mark read failed') as String);
    }
  }

  Future<void> adminSendMessage({required int toUserId, required String body}) async {
    final res = await _http.post(
      _uri('/admin_messages.php'),
      headers: _headers(admin: true),
      body: jsonEncode({'to_user_id': toUserId, 'body': body}),
    );
    final json = _decodeMap(res);
    if (res.statusCode != 200 || json['ok'] != true) {
      throw ApiException((json['error'] ?? 'admin message failed') as String);
    }
  }
}

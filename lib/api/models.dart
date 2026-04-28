class ApiUser {
  final int id;
  final String username;
  final String? email;
  final String role;
  final String? status;

  const ApiUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.status,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: (json['id'] as num).toInt(),
      username: (json['username'] ?? '') as String,
      email: json['email'] as String?,
      role: (json['role'] ?? 'buyer') as String,
      status: json['status'] as String?,
    );
  }
}

class ApiProduct {
  final int id;
  final String name;
  final String price;
  final String? harvestDate;
  final String? image;
  final String? description;
  final String? farmerName;
  final String? farmerLocation;
  final String? weight;
  final int? farmerId;
  final String? status;

  const ApiProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.harvestDate,
    required this.image,
    required this.description,
    required this.farmerName,
    required this.farmerLocation,
    required this.weight,
    this.farmerId,
    this.status,
  });

  Map<String, String> toLegacyMapForUi() {
    return {
      'id': id.toString(),
      'name': name,
      'price': price,
      'harvestDate': harvestDate ?? 'N/A',
      'image': image ?? '',
      if (description != null && description!.isNotEmpty) 'description': description!,
      if (farmerName != null && farmerName!.isNotEmpty) 'farmerName': farmerName!,
      if (farmerLocation != null && farmerLocation!.isNotEmpty) 'farmerLocation': farmerLocation!,
      if (weight != null && weight!.isNotEmpty) 'weight': weight!,
      if (farmerId != null) 'farmerId': farmerId.toString(),
      if (status != null && status!.isNotEmpty) 'productStatus': status!,
    };
  }

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      price: (json['price'] ?? '') as String,
      harvestDate: json['harvestDate'] as String?,
      image: json['image'] as String?,
      description: json['description'] as String?,
      farmerName: json['farmerName'] as String?,
      farmerLocation: json['farmerLocation'] as String?,
      weight: json['weight'] as String?,
      farmerId: (json['farmerId'] as num?)?.toInt(),
      status: json['status'] as String? ?? json['productStatus'] as String?,
    );
  }
}

class ApiOrder {
  final int id;
  final String status;
  final String totalPhp;
  final String? buyerUsername;
  final List<Map<String, dynamic>> items;

  ApiOrder({
    required this.id,
    required this.status,
    required this.totalPhp,
    required this.buyerUsername,
    required this.items,
  });

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return ApiOrder(
      id: (json['id'] as num).toInt(),
      status: (json['status'] ?? '') as String,
      totalPhp: (json['total_php'] ?? json['totalPhp'] ?? '0').toString(),
      buyerUsername: json['buyer_username'] as String?,
      items: rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
}

class ApiNotification {
  final int id;
  final String type;
  final String title;
  final String? body;
  final String? readAt;

  ApiNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.readAt,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> json) {
    return ApiNotification(
      id: (json['id'] as num).toInt(),
      type: (json['type'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      body: json['body'] as String?,
      readAt: json['read_at'] as String?,
    );
  }
}

class ApiCartLine {
  final int productId;
  final int qty;
  final String name;
  final String priceLabel;
  final double pricePhp;

  ApiCartLine({
    required this.productId,
    required this.qty,
    required this.name,
    required this.priceLabel,
    required this.pricePhp,
  });

  factory ApiCartLine.fromJson(Map<String, dynamic> json) {
    return ApiCartLine(
      productId: (json['product_id'] as num).toInt(),
      qty: (json['qty'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      priceLabel: (json['price'] ?? '') as String,
      pricePhp: (json['price_php'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ApiPublicUser {
  final int id;
  final String username;
  final String role;
  final String? displayName;

  ApiPublicUser({required this.id, required this.username, required this.role, this.displayName});

  String get fullName {
    final dn = (displayName ?? '').trim();
    if (dn.isNotEmpty) return dn;
    return username;
  }

  factory ApiPublicUser.fromJson(Map<String, dynamic> json) {
    return ApiPublicUser(
      id: (json['id'] as num).toInt(),
      username: (json['username'] ?? '') as String,
      role: (json['role'] ?? '') as String,
      displayName: json['display_name'] as String?,
    );
  }
}

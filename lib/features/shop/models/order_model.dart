class OrderItemModel {
  final int id;
  final String productName;
  final String variantLabel;
  final int quantity;
  final double unitPrice;

  const OrderItemModel({
    required this.id,
    required this.productName,
    required this.variantLabel,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
        id: j['id'] as int? ?? 0,
        productName: j['product_name'] as String? ?? j['product'] as String? ?? '',
        variantLabel: j['variant_label'] as String? ?? '',
        quantity: j['quantity'] as int? ?? 1,
        unitPrice: double.tryParse(j['unit_price']?.toString() ?? '0') ?? 0,
      );
}

class OrderModel {
  final int id;
  final String status;
  final DateTime? createdAt;
  final double total;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.status,
    this.createdAt,
    required this.total,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: j['id'] as int,
        status: j['status'] as String? ?? '',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        total: double.tryParse(j['total']?.toString() ?? '0') ?? 0,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

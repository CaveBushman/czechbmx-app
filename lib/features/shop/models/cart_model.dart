class CartItem {
  final int variantId;
  final String productSlug;
  final String productName;
  final String variantLabel;
  final double unitPrice;
  final String? imageUrl;
  final int quantity;

  const CartItem({
    required this.variantId,
    required this.productSlug,
    required this.productName,
    required this.variantLabel,
    required this.unitPrice,
    this.imageUrl,
    this.quantity = 1,
  });

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        variantId: variantId,
        productSlug: productSlug,
        productName: productName,
        variantLabel: variantLabel,
        unitPrice: unitPrice,
        imageUrl: imageUrl,
        quantity: quantity ?? this.quantity,
      );
}

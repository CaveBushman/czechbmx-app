import '../../../core/constants/api_constants.dart';

class CategoryModel {
  final int id;
  final String name;
  final String slug;

  const CategoryModel({required this.id, required this.name, required this.slug});

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'] as int,
        name: j['name'] as String,
        slug: j['slug'] as String,
      );
}

class ProductVariantModel {
  final int id;
  final String label;
  final double price;
  final int stock;

  const ProductVariantModel({
    required this.id,
    required this.label,
    required this.price,
    required this.stock,
  });

  bool get inStock => stock > 0;

  factory ProductVariantModel.fromJson(Map<String, dynamic> j) =>
      ProductVariantModel(
        id: j['id'] as int,
        label: j['label'] as String,
        price: double.parse(j['price'].toString()),
        stock: j['stock'] as int? ?? 0,
      );
}

class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String? subtitle;
  final String? description;
  final String? material;
  final String? fitNote;
  final String? imageUrl;
  final int totalStock;
  final List<ProductVariantModel> variants;
  final String? categoryName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    this.subtitle,
    this.description,
    this.material,
    this.fitNote,
    this.imageUrl,
    required this.totalStock,
    required this.variants,
    this.categoryName,
  });

  bool get inStock => totalStock > 0;

  double get minPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (variants.isEmpty) return 0;
    return variants.map((v) => v.price).reduce((a, b) => a > b ? a : b);
  }

  String get priceLabel {
    if (variants.isEmpty) return '';
    final mn = minPrice;
    final mx = maxPrice;
    if ((mx - mn).abs() < 0.01) return '${mn.toStringAsFixed(0)} Kč';
    return '${mn.toStringAsFixed(0)}–${mx.toStringAsFixed(0)} Kč';
  }

  String? get imageAbsoluteUrl =>
      imageUrl != null ? ApiConstants.mediaPath(imageUrl!) : null;

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j['id'] as int,
        name: j['name'] as String,
        slug: j['slug'] as String,
        subtitle: j['subtitle'] as String?,
        description: j['description'] as String?,
        material: j['material'] as String?,
        fitNote: j['fit_note'] as String?,
        imageUrl: j['image_url'] as String?,
        totalStock: j['total_stock'] as int? ?? 0,
        variants: (j['variants'] as List<dynamic>? ?? [])
            .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        categoryName: j['category_name'] as String?,
      );
}

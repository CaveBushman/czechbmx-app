import '../../../core/constants/api_constants.dart';

class CategoryModel {
  final int id;
  final String name;
  final String slug;

  const CategoryModel(
      {required this.id, required this.name, required this.slug});

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
        id: _intFromJson(j['id']),
        label: j['label'] as String? ?? '',
        price: double.tryParse(j['price'].toString()) ?? 0,
        stock: _intFromJson(j['stock']),
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
  final int? categoryId;
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
    this.categoryId,
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
        id: _intFromJson(j['id']),
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        subtitle: j['subtitle'] as String?,
        description: j['description'] as String?,
        material: j['material'] as String?,
        fitNote: j['fit_note'] as String?,
        imageUrl: j['image_url'] as String?,
        totalStock: _intFromJson(j['total_stock']),
        variants: (j['variants'] as List<dynamic>? ?? [])
            .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        categoryId: _categoryIdFromJson(j['category']),
        categoryName: _stringFromJson(j['category_name']) ??
            _categoryNameFromJson(j['category']),
      );
}

int? _categoryIdFromJson(dynamic value) {
  if (value is Map) return _intOrNull(value['id']);
  return _intOrNull(value);
}

String? _categoryNameFromJson(dynamic value) {
  if (value is! Map) return null;
  for (final key in const ['name', 'title']) {
    final name = _stringFromJson(value[key]);
    if (name != null) return name;
  }
  return null;
}

String? _stringFromJson(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return value.toString();
  return null;
}

int? _intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int _intFromJson(dynamic value) {
  return _intOrNull(value) ?? 0;
}

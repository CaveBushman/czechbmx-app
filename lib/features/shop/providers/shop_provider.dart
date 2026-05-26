import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../shop_repository.dart';

final shopSelectedCategoryProvider = StateProvider<String?>((ref) => null);

final shopCategoriesProvider =
    AsyncNotifierProvider<_CategoriesNotifier, List<CategoryModel>>(
  _CategoriesNotifier.new,
);

class _CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() =>
      ref.read(shopRepositoryProvider).fetchCategories();

  Future<void> refresh() => Future.sync(() => ref.invalidateSelf());
}

final shopProductsProvider =
    AsyncNotifierProvider<_ProductsNotifier, List<ProductModel>>(
  _ProductsNotifier.new,
);

class _ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    final selectedCategorySlug = ref.watch(shopSelectedCategoryProvider);
    final products = await ref.read(shopRepositoryProvider).fetchProducts();
    if (selectedCategorySlug == null) return products;

    final categories = await ref.watch(shopCategoriesProvider.future);
    return filterProductsByCategory(
      products: products,
      categories: categories,
      selectedCategorySlug: selectedCategorySlug,
    );
  }

  Future<void> refresh() => Future.sync(() => ref.invalidateSelf());
}

List<ProductModel> filterProductsByCategory({
  required List<ProductModel> products,
  required List<CategoryModel> categories,
  required String? selectedCategorySlug,
}) {
  if (selectedCategorySlug == null) return products;

  final selectedCategory = _categoryForSlug(categories, selectedCategorySlug);
  if (selectedCategory == null) return const [];

  return products.where((product) {
    if (product.categoryId != null) {
      return product.categoryId == selectedCategory.id;
    }

    return _normalizeCategory(product.categoryName) ==
        _normalizeCategory(selectedCategory.name);
  }).toList();
}

CategoryModel? _categoryForSlug(
  List<CategoryModel> categories,
  String slug,
) {
  for (final category in categories) {
    if (category.slug == slug) return category;
  }
  return null;
}

String _normalizeCategory(String? value) {
  return value?.trim().toLowerCase() ?? '';
}

final shopProductProvider =
    AsyncNotifierProviderFamily<_ProductDetailNotifier, ProductModel, String>(
  _ProductDetailNotifier.new,
);

class _ProductDetailNotifier extends FamilyAsyncNotifier<ProductModel, String> {
  @override
  Future<ProductModel> build(String slug) =>
      ref.read(shopRepositoryProvider).fetchProduct(slug);
}

final myOrdersProvider =
    AsyncNotifierProvider<_OrdersNotifier, List<OrderModel>>(
  _OrdersNotifier.new,
);

class _OrdersNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() =>
      ref.read(authenticatedShopRepositoryProvider).fetchOrders();

  Future<void> refresh() => Future.sync(() => ref.invalidateSelf());
}

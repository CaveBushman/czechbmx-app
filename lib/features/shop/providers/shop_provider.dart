import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  Future<List<ProductModel>> build() {
    final category = ref.watch(shopSelectedCategoryProvider);
    return ref
        .read(shopRepositoryProvider)
        .fetchProducts(categorySlug: category);
  }

  Future<void> refresh() => Future.sync(() => ref.invalidateSelf());
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

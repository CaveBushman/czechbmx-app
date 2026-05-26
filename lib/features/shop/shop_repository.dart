import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'models/order_model.dart';
import 'models/product_model.dart';

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepository(ref.read(publicDioProvider)),
);

final authenticatedShopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepository(ref.read(dioProvider)),
);

class ShopRepository {
  final Dio _dio;
  const ShopRepository(this._dio);

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final r = await _dio.get(ApiConstants.shopCategories);
      final list =
          r.data is List ? r.data as List : (r.data['results'] as List);
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final r = await _dio.get(ApiConstants.shopProducts);
      final list =
          r.data is List ? r.data as List : (r.data['results'] as List);
      return list
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductModel> fetchProduct(String slug) async {
    try {
      final r = await _dio.get(ApiConstants.shopProduct(slug));
      return ProductModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<OrderModel>> fetchOrders() async {
    try {
      final r = await _dio.get(ApiConstants.shopOrders);
      final list = r.data is List ? r.data as List : (r.data['results'] as List? ?? []);
      return list
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> checkout({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _dio.post(
        ApiConstants.shopCheckout,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (note != null && note.isNotEmpty) 'note': note,
          'items': items,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

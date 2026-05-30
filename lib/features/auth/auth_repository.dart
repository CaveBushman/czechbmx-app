// Auth repository — API volání pro správu účtu.
//
// UserModel: data přihlášeného uživatele (id, email, jméno, kredit, role, foto,
//            rider_uci_id = UCI ID navázaného jezdce)
//
// Metody AuthRepository:
//   login()          — POST /api/auth/login/ → uloží tokeny, vrátí UserModel
//   logout()         — POST /api/auth/logout/ → smaže tokeny lokálně
//   register()       — POST /api/auth/register/ → vytvoří účet (nevrátí tokeny)
//   restoreSession() — načte refresh token z TokenStorage, ověří ho na /api/auth/me/
//   fetchMe()        — GET /api/auth/me/ → aktuální data uživatele (refresh profilu)
//   updatePhoto()    — PATCH /api/auth/me/ s multipart/form-data → nahraje avatar
//   registerFcmToken() — POST /api/auth/fcm-token/ → registruje push token
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/token_storage.dart';

// ── User model ────────────────────────────────────────────────────────────────

class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isStaff;
  final bool isRider;
  final bool isClubManager;
  final bool isCommissar;
  final bool isTrainer;
  final int credit;
  final String? photoUrl;
  final int? riderUciId;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isStaff,
    required this.isRider,
    required this.isClubManager,
    required this.isCommissar,
    required this.isTrainer,
    required this.credit,
    this.photoUrl,
    this.riderUciId,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayName =>
      fullName.isNotEmpty ? fullName : email.split('@').first;
  bool get isAdmin => isStaff;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        isStaff: json['is_staff'] as bool? ?? false,
        isRider: json['is_rider'] as bool? ?? false,
        isClubManager: json['is_club_manager'] as bool? ?? false,
        isCommissar: json['is_commissar'] as bool? ?? false,
        isTrainer: json['is_trainer'] as bool? ?? false,
        credit: json['credit'] as int? ?? 0,
        photoUrl: _mediaUrl(json['photo_url']),
        riderUciId: json['rider_uci_id'] as int? ?? json['uci_id'] as int?,
      );

  static String? _mediaUrl(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    // Pokud už URL začíná protokolem http, nebudeme ji znovu prefixovat doménou
    if (trimmed.startsWith('http')) return trimmed;
    return ApiConstants.mediaPath(trimmed);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    publicDio: ref.watch(publicDioProvider),
    authedDio: ref.watch(dioProvider),
  ),
);

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _dio;       // public — login, logout, register
  final Dio _authedDio; // authenticated + locale-aware — me, photo

  const AuthRepository({required Dio publicDio, required Dio authedDio})
      : _dio = publicDio,
        _authedDio = authedDio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.authLogin,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      await TokenStorage.save(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await TokenStorage.getRefresh();
      if (refresh != null) {
        await _dio.post(ApiConstants.authLogout, data: {'refresh': refresh});
      }
    } catch (_) {
      // Logout locally even if server call fails
    } finally {
      await TokenStorage.clear();
    }
  }

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      await _dio.post(
        ApiConstants.authRegister,
        data: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(ApiConstants.authPasswordReset, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel?> restoreSession() async {
    final access = await TokenStorage.getAccess();
    if (access == null) return null;
    try {
      final response = await _authedDio.get(ApiConstants.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      await TokenStorage.clear();
      return null;
    }
  }

  Future<UserModel> fetchMe() async {
    try {
      final response = await _authedDio.get(ApiConstants.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _authedDio.post(ApiConstants.authFcmToken, data: {'fcm_token': token});
    } catch (_) {
      // Non-critical — swallow silently.
    }
  }

  Future<UserModel> updatePhoto(String filePath) async {
    try {
      final filename = filePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: filename),
      });
      final response = await _authedDio.patch(
        ApiConstants.authMe,
        data: formData,
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

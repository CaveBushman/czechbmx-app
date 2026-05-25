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
  });

  String get fullName => '$firstName $lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : email.split('@').first;
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
        photoUrl: json['photo_url'] as String?,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(DioClient.create(withAuth: false)),
);

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  final Dio _dio;

  const AuthRepository(this._dio);

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

  Future<UserModel?> restoreSession() async {
    final access = await TokenStorage.getAccess();
    if (access == null) return null;
    try {
      final authedDio = DioClient.create();
      final response = await authedDio.get(ApiConstants.authMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      await TokenStorage.clear();
      return null;
    }
  }
}

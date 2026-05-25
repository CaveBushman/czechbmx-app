class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://czechbmx.cz';
  static const String mediaUrl = 'https://czechbmx.cz';

  static const String news = '/api/news/';
  static const String events = '/api/events/';
  static const String riders = '/api/riders/';
  static const String clubs = '/api/clubs/';
  static const String authLogin = '/api/auth/login/';
  static const String authLogout = '/api/auth/logout/';
  static const String authMe = '/api/auth/me/';
  static const String authRefresh = '/api/auth/token/refresh/';

  static String mediaPath(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    return '$mediaUrl$relativePath';
  }
}

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://czechbmx.cz',
  );
  static const String mediaUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: baseUrl,
  );

  static const String news = '/api/news/';
  static const String events = '/api/events/';
  static const String riders = '/api/riders/';
  static const String clubs = '/api/clubs/';
  static const String teams = '/api/teams/';
  static const String authLogin = '/api/auth/login/';
  static const String authLogout = '/api/auth/logout/';
  static const String authMe = '/api/auth/me/';
  static const String authRefresh = '/api/auth/token/refresh/';
  static const String authRegister = '/api/auth/register/';
  static const String authPasswordReset = '/api/auth/password/reset/';
  static const String authPasswordResetConfirm =
      '/api/auth/password/reset/confirm/';
  static const String authPasswordChange = '/api/auth/password/change/';

  static const String plateRequest = '/api/riders/plate-request/';
  static const String plateRequestLookup = '/api/riders/plate-request/lookup/';
  static const String plateRequestFreePlates = '/api/riders/plate-request/free-plates/';

  static const String rankingCategories = '/api/ranking/categories/';
  static const String ranking = '/api/ranking/';

  static const String entriesMy = '/api/entries/my/';
  static String entryCancel(int id) => '/api/entries/$id/cancel/';
  static String eventEntryInfo(int id) => '/api/events/$id/entry-info/';
  static String eventEnter(int id) => '/api/events/$id/enter/';
  static String eventForeignEntryInfo(int id) => '/api/events/$id/foreign-entry-info/';
  static String eventForeignEnter(int id) => '/api/events/$id/foreign-enter/';
  static String foreignEntryCancel(int id) => '/api/entries/foreign/$id/cancel/';
  static String eventRegisteredRiders(int id) => '/event/entry-riders/$id';

  static const String shopCategories = '/api/eshop/categories/';
  static const String shopProducts = '/api/eshop/products/';
  static String shopProduct(String slug) => '/api/eshop/products/$slug/';
  static const String creditTopUp = '/api/credit/topup/';
  static const String shopCart = '/api/eshop/cart/';
  static String shopCartItem(int variantId) => '/api/eshop/cart/$variantId/';
  static const String shopCheckout = '/api/eshop/checkout/';
  static const String shopOrders = '/api/eshop/orders/';
  static String shopOrder(int id) => '/api/eshop/orders/$id/';
  static String shopOrderCancel(int id) => '/api/eshop/orders/$id/cancel/';

  static String mediaPath(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    final normalizedBase = mediaUrl.endsWith('/')
        ? mediaUrl.substring(0, mediaUrl.length - 1)
        : mediaUrl;
    final normalizedPath =
        relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$normalizedBase$normalizedPath';
  }
}

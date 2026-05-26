import 'package:app_links/app_links.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _appLinks = AppLinks();

/// Maps external URIs to internal GoRouter paths.
/// Handles Czech website URL conventions:
///   https://czechbmx.cz/jezdci/{uciId}  →  /riders/{uciId}
///   https://czechbmx.cz/event/{id}      →  /events/{id}
///   czechbmx://…                         →  path as-is
String _toPath(Uri uri) {
  final path = uri.path.isEmpty ? '/' : uri.path;
  if (path.startsWith('/jezdci/')) {
    return '/riders/${path.substring('/jezdci/'.length)}';
  }
  if (path.startsWith('/event/') && !path.startsWith('/events/')) {
    return '/events/${path.substring('/event/'.length)}';
  }
  return path;
}

/// Resolves the URI that launched the app (cold start).
/// Returns null when the app was opened normally.
final initialDeepLinkProvider = FutureProvider<String?>((ref) async {
  try {
    final uri = await _appLinks.getInitialLink();
    return uri != null ? _toPath(uri) : null;
  } catch (_) {
    return null;
  }
});

/// Emits paths for links received while the app is running (warm start).
final deepLinkStreamProvider = StreamProvider<String>((ref) {
  return _appLinks.uriLinkStream.map(_toPath);
});

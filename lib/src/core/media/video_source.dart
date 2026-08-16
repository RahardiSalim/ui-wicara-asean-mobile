import 'package:video_player/video_player.dart';

/// Builds a player for either a remote URL or a clip bundled with the app.
///
/// The Manim template pack ships as Flutter assets, and an asset path is not a
/// URL: handing `assets/videos/folk_tale.mp4` to
/// [VideoPlayerController.networkUrl] gives the platform a relative reference
/// with no origin to resolve against, so it fails to initialise on iOS and
/// Android. Flutter web serves the same bundle one directory deeper, which is
/// why a bundled clip reads as `assets/assets/videos/...` there — that outer
/// segment is the web spelling, not part of the asset key.
VideoPlayerController createVideoController(String source) {
  final trimmed = source.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.scheme != 'asset') {
    return VideoPlayerController.networkUrl(uri);
  }
  return VideoPlayerController.asset(videoAssetKey(trimmed));
}

/// Whether [source] points at a clip bundled with the app rather than a remote
/// one. A schemeless path is always local — nothing else could serve it.
bool isBundledVideo(String source) {
  final uri = Uri.tryParse(source.trim());
  return uri == null || !uri.hasScheme || uri.scheme == 'asset';
}

/// The key the asset bundle knows a bundled clip by.
String videoAssetKey(String source) {
  var key = source.trim();
  if (key.startsWith('asset:')) {
    key = key.substring('asset:'.length);
  }
  while (key.startsWith('/')) {
    key = key.substring(1);
  }
  if (key.startsWith('assets/assets/')) {
    key = key.substring('assets/'.length);
  }
  return key;
}

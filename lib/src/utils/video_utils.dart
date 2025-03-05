import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

import 'video_precacher.dart';

class VideoUtils {
  VideoUtils._();

  // Singleton instance of VideoUtils.
  static final VideoUtils instance = VideoUtils._();

  // Cache manager to handle caching of video files.
  final _cacheManager = DefaultCacheManager();

  // Method to create a VideoPlayerController from a URL.
  // If cacheFile is true, it attempts to cache the video file.
  Future<VideoPlayerController> videoControllerFromUrl({
    required String url,
    bool? cacheFile = false,
    VideoPlayerOptions? videoPlayerOptions,
  }) async {
    if (cacheFile ?? false) {
      return VideoPrecacher.instance
          .getController(url, videoPlayerOptions: videoPlayerOptions);
    }

    return VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  // Method to create a VideoPlayerController from a local file.
  VideoPlayerController videoControllerFromFile({
    required File file,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return VideoPlayerController.file(
      file,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  // Method to create a VideoPlayerController from an asset file.
  VideoPlayerController videoControllerFromAsset({
    required String assetPath,
    VideoPlayerOptions? videoPlayerOptions,
  }) {
    return VideoPlayerController.asset(
      assetPath,
      videoPlayerOptions: videoPlayerOptions,
    );
  }

  /// Preloads a video from a URL
  Future<void> preloadVideo(String url,
      {VideoPlayerOptions? videoPlayerOptions}) {
    return VideoPrecacher.instance
        .preloadVideo(url, videoPlayerOptions: videoPlayerOptions);
  }

  /// Clears all preloaded videos from memory
  void clearPreloadedVideos() {
    VideoPrecacher.instance.clearPreloadedVideos();
  }
}

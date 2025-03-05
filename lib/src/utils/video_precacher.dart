import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';

class VideoPrecacher {
  VideoPrecacher._();

  static final VideoPrecacher instance = VideoPrecacher._();

  final _cacheManager = DefaultCacheManager();
  final _preloadedControllers =
      HashMap<String, Future<VideoPlayerController>>();

  /// Preloads a video from a URL and keeps it in memory
  /// Returns a Future that completes when the video is initialized
  Future<void> preloadVideo(String url,
      {VideoPlayerOptions? videoPlayerOptions}) async {
    if (_preloadedControllers.containsKey(url)) {
      return;
    }

    _preloadedControllers[url] =
        _initializeVideo(url, videoPlayerOptions: videoPlayerOptions);
    await _preloadedControllers[url]; // Wait for initialization
  }

  /// Gets a preloaded video controller if available, otherwise creates a new one
  Future<VideoPlayerController> getController(String url,
      {VideoPlayerOptions? videoPlayerOptions}) async {
    if (_preloadedControllers.containsKey(url)) {
      final controller = await _preloadedControllers[url];
      _preloadedControllers
          .remove(url); // Remove from cache since it's now being used
      return controller;
    }

    return _initializeVideo(url, videoPlayerOptions: videoPlayerOptions);
  }

  Future<VideoPlayerController> _initializeVideo(String url,
      {VideoPlayerOptions? videoPlayerOptions}) async {
    try {
      final cachedVideo = await _cacheManager.getSingleFile(url);
      final controller = VideoPlayerController.file(
        cachedVideo,
        videoPlayerOptions: videoPlayerOptions,
      );
      await controller.initialize();
      return controller;
    } catch (e) {
      debugPrint('Error precaching video: $e');
      // Fallback to network URL if caching fails
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: videoPlayerOptions,
      );
      await controller.initialize();
      return controller;
    }
  }

  /// Clears all preloaded controllers from memory
  void clearPreloadedVideos() {
    for (final controllerFuture in _preloadedControllers.values) {
      controllerFuture.then((controller) => controller.dispose());
    }
    _preloadedControllers.clear();
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_story_presenter/flutter_story_presenter.dart';
import 'package:flutter_story_presenter/src/utils/video_utils.dart';
import 'package:video_player/video_player.dart';

/// A widget that displays a video story view, supporting different video sources
/// (network, file, asset) and optional thumbnail and error widgets.
class VideoStoryView extends StatefulWidget {
  /// The story item containing video data and configuration.
  final StoryItem storyItem;

  /// Callback function to notify when the video is loaded.
  final OnVideoLoad? onVideoLoad;

  /// In case of single video story
  final bool? looping;

  /// The next story item, if any, for precaching
  final StoryItem? nextStoryItem;

  /// Creates a [VideoStoryView] widget.
  const VideoStoryView({
    required this.storyItem,
    this.onVideoLoad,
    this.looping,
    this.nextStoryItem,
    super.key,
  });

  @override
  State<VideoStoryView> createState() => _VideoStoryViewState();
}

class _VideoStoryViewState extends State<VideoStoryView> {
  VideoPlayerController? videoPlayerController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _preloadNextStory(); // Precache next story if applicable
  }

  Future<void> _initializeController() async {
    try {
      if (widget.storyItem.videoConfig?.videoPlayerController != null) {
        // Use pre-initialized controller if provided
        videoPlayerController =
            widget.storyItem.videoConfig!.videoPlayerController;
      } else if (widget.storyItem.storyItemSource == StoryItemSource.network &&
          widget.storyItem.url != null) {
        // Create controller with caching for network source
        videoPlayerController =
            await VideoUtils.instance.videoControllerFromUrl(
          url: widget.storyItem.url!,
          cacheFile: widget.storyItem.videoConfig?.cacheVideo ?? false,
          videoPlayerOptions: widget.storyItem.videoConfig?.videoPlayerOptions,
        );
      } else if (widget.storyItem.storyItemSource == StoryItemSource.file &&
          widget.storyItem.url != null) {
        // Create controller for file source (no caching needed)
        videoPlayerController = VideoUtils.instance.videoControllerFromFile(
          file: File(widget.storyItem.url!),
          videoPlayerOptions: widget.storyItem.videoConfig?.videoPlayerOptions,
        );
      } else if (widget.storyItem.storyItemSource == StoryItemSource.asset &&
          widget.storyItem.url != null) {
        // Create controller for asset source (no caching needed)
        videoPlayerController = VideoUtils.instance.videoControllerFromAsset(
          assetPath: widget.storyItem.url!,
          videoPlayerOptions: widget.storyItem.videoConfig?.videoPlayerOptions,
        );
      } else {
        hasError = true;
        debugPrint('Invalid story item configuration');
        _scheduleStateUpdate();
        return;
      }

      if (!videoPlayerController!.value.isInitialized) {
        await videoPlayerController!.initialize();
      }
      widget.onVideoLoad?.call(videoPlayerController!);
      await videoPlayerController?.play();
      await videoPlayerController?.setLooping(widget.looping ?? false);
      await videoPlayerController
          ?.setVolume(widget.storyItem.isMuteByDefault ? 0 : 1);
    } catch (e) {
      hasError = true;
      debugPrint('Error initializing video: $e');
      _scheduleStateUpdate();
    }
  }

  void _scheduleStateUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _preloadNextStory() async {
    if (widget.nextStoryItem != null &&
        widget.nextStoryItem!.storyItemSource == StoryItemSource.network &&
        widget.nextStoryItem!.videoConfig?.cacheVideo == true &&
        widget.nextStoryItem!.url != null) {
      await VideoUtils.instance.preloadVideo(widget.nextStoryItem!.url!);
    }
  }

  @override
  void dispose() {
    videoPlayerController?.dispose();
    super.dispose();
  }

  BoxFit get fit => widget.storyItem.videoConfig?.fit ?? BoxFit.cover;

  @override
  Widget build(BuildContext context) {
    // Existing build method remains unchanged
    return Stack(
      alignment: (fit == BoxFit.cover) ? Alignment.topCenter : Alignment.center,
      fit: (fit == BoxFit.cover) ? StackFit.expand : StackFit.loose,
      children: [
        if (widget.storyItem.videoConfig?.loadingWidget != null) ...{
          widget.storyItem.videoConfig!.loadingWidget!,
        } else if (widget.storyItem.thumbnail != null) ...{
          widget.storyItem.thumbnail!,
        },
        if (widget.storyItem.errorWidget != null && hasError) ...{
          widget.storyItem.errorWidget!,
        },
        if (videoPlayerController != null) ...{
          if (widget.storyItem.videoConfig?.useVideoAspectRatio ?? false) ...{
            AspectRatio(
              aspectRatio: videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(videoPlayerController!),
            )
          } else ...{
            FittedBox(
              fit: widget.storyItem.videoConfig?.fit ?? BoxFit.cover,
              alignment: Alignment.center,
              child: SizedBox(
                width: widget.storyItem.videoConfig?.width ??
                    videoPlayerController!.value.size.width,
                height: widget.storyItem.videoConfig?.height ??
                    videoPlayerController!.value.size.height,
                child: VideoPlayer(videoPlayerController!),
              ),
            )
          },
        }
      ],
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../models/story_item.dart';
import '../story_presenter/story_view.dart';
import '../utils/story_utils.dart';
import '../utils/video_utils.dart';

/// A widget that displays a video story view, supporting different video sources
/// (network, file, asset) and optional thumbnail and error widgets.
class VideoStoryView extends StatefulWidget {
  final StoryItem storyItem;
  final OnVideoLoad? onVideoLoad;
  final bool? looping;

  const VideoStoryView({
    required this.storyItem,
    this.onVideoLoad,
    this.looping,
    super.key,
  });

  @override
  State<VideoStoryView> createState() => _VideoStoryViewState();
}

class _VideoStoryViewState extends State<VideoStoryView> {
  VideoPlayerController? videoPlayerController;
  bool hasError = false;
  bool isVertical = false;

  @override
  void initState() {
    if (widget.storyItem.videoConfig?.externalController != null) {
      _useExternalController();
    } else {
      _initialiseVideoPlayer();
    }
    super.initState();
  }

  Future<void> _useExternalController() async {
    try {
      videoPlayerController = widget.storyItem.videoConfig!.externalController;
      if (!videoPlayerController!.value.isInitialized) {
        await videoPlayerController!.initialize();
      }
      _checkVideoOrientation();
      widget.onVideoLoad?.call(videoPlayerController!);
      await videoPlayerController?.setLooping(widget.looping ?? false);
      await videoPlayerController
          ?.setVolume(widget.storyItem.isMuteByDefault ? 0 : 1);
      await videoPlayerController?.play();
    } catch (e) {
      hasError = true;
      debugPrint('$e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  Future<void> _initialiseVideoPlayer() async {
    try {
      final storyItem = widget.storyItem;
      if (storyItem.storyItemSource.isNetwork) {
        videoPlayerController =
            await VideoUtils.instance.videoControllerFromUrl(
          url: storyItem.url!,
          cacheFile: storyItem.videoConfig?.cacheVideo,
          videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
        );
      } else if (storyItem.storyItemSource.isFile) {
        videoPlayerController = VideoUtils.instance.videoControllerFromFile(
          file: File(storyItem.url!),
          videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
        );
      } else {
        videoPlayerController = VideoUtils.instance.videoControllerFromAsset(
          assetPath: storyItem.url!,
          videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
        );
      }
      await videoPlayerController?.initialize();
      _checkVideoOrientation();
      widget.onVideoLoad?.call(videoPlayerController!);
      await videoPlayerController?.play();
      await videoPlayerController?.setLooping(widget.looping ?? false);
      await videoPlayerController?.setVolume(storyItem.isMuteByDefault ? 0 : 1);
    } catch (e) {
      hasError = true;
      debugPrint('$e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  /// Check if the video is vertical (height > width)
  void _checkVideoOrientation() {
    if (videoPlayerController != null &&
        videoPlayerController!.value.isInitialized) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final aspectRatio = videoPlayerController!.value.aspectRatio;
        setState(() {
          isVertical = aspectRatio < 1.0; // Vertical if width < height
        });
      });
    }
  }

  BoxFit get fit => widget.storyItem.videoConfig?.fit ?? BoxFit.cover;

  @override
  void dispose() {
    if (widget.storyItem.videoConfig?.externalController == null) {
      videoPlayerController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand, // Ensure the Stack fills the parent
      children: [
        if (videoPlayerController != null &&
            videoPlayerController!.value.isInitialized) ...[
          if (isVertical) ...[
            // For vertical videos, force full height and adjust width
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // Fill the screen, cropping if necessary
                alignment: Alignment.center,
                child: SizedBox(
                  width: videoPlayerController!.value.size.width,
                  height: videoPlayerController!.value.size.height,
                  child: VideoPlayer(videoPlayerController!),
                ),
              ),
            ),
          ] else if (widget.storyItem.videoConfig?.useVideoAspectRatio ??
              false) ...[
            // Use aspect ratio for non-vertical videos if specified
            AspectRatio(
              aspectRatio: videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(videoPlayerController!),
            ),
          ] else ...[
            // Default behavior for non-vertical videos
            FittedBox(
              fit: fit,
              alignment: Alignment.center,
              child: SizedBox(
                width: widget.storyItem.videoConfig?.width ??
                    videoPlayerController!.value.size.width,
                height: widget.storyItem.videoConfig?.height ??
                    videoPlayerController!.value.size.height,
                child: VideoPlayer(videoPlayerController!),
              ),
            ),
          ],
        ],
        // Loading widget or thumbnail
        if (videoPlayerController == null ||
            !videoPlayerController!.value.isInitialized) ...[
          if (widget.storyItem.videoConfig?.loadingWidget != null) ...[
            widget.storyItem.videoConfig!.loadingWidget!,
          ] else if (widget.storyItem.thumbnail != null) ...[
            widget.storyItem.thumbnail!,
          ],
        ],
        // Error widget
        if (widget.storyItem.errorWidget != null && hasError) ...[
          widget.storyItem.errorWidget!,
        ],
      ],
    );
  }
}

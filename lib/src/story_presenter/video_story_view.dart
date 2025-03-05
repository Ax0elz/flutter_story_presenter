import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/story_item.dart';
import '../story_presenter/story_view.dart';

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
    videoPlayerController = widget.storyItem.videoConfig?.videoPlayerController;
    if (videoPlayerController != null) {
      _initializeController();
    } else {
      hasError = true;
      debugPrint('No video controller provided in StoryItem videoConfig');
    }
    super.initState();
  }

  /// Initializes the video controller with the widget's settings
  Future<void> _initializeController() async {
    try {
      if (!videoPlayerController!.value.isInitialized) {
        await videoPlayerController!.initialize();
      }
      widget.onVideoLoad?.call(videoPlayerController!);
      await videoPlayerController?.play();
      await videoPlayerController?.setLooping(widget.looping ?? false);
      await videoPlayerController
          ?.setVolume(widget.storyItem.isMuteByDefault ? 0 : 1);
      setState(() {});
    } catch (e) {
      hasError = true;
      debugPrint('$e');
      setState(() {});
    }
  }

  BoxFit get fit => widget.storyItem.videoConfig?.fit ?? BoxFit.cover;

  @override
  void dispose() {
    videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: (fit == BoxFit.cover) ? Alignment.topCenter : Alignment.center,
      fit: (fit == BoxFit.cover) ? StackFit.expand : StackFit.loose,
      children: [
        if (widget.storyItem.videoConfig?.loadingWidget != null) ...{
          widget.storyItem.videoConfig!.loadingWidget!,
        } else if (widget.storyItem.thumbnail != null) ...{
          // Display the thumbnail if provided.
          widget.storyItem.thumbnail!,
        },
        if (widget.storyItem.errorWidget != null && hasError) ...{
          // Display the error widget if an error occurred.
          widget.storyItem.errorWidget!,
        },
        if (videoPlayerController != null) ...{
          if (widget.storyItem.videoConfig?.useVideoAspectRatio ?? false) ...{
            // Display the video with aspect ratio if specified.
            AspectRatio(
              aspectRatio: videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(
                videoPlayerController!,
              ),
            )
          } else ...{
            // Display the video fitted to the screen.
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

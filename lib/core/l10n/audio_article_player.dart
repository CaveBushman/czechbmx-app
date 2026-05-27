import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';

class AudioArticlePlayer extends StatefulWidget {
  final String url;
  final String title;

  const AudioArticlePlayer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AudioArticlePlayer> createState() => _AudioArticlePlayerState();
}

class _AudioArticlePlayerState extends State<AudioArticlePlayer> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.headphones_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.audioArticle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _PlayPauseButton(player: _player),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(player: _player),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final AudioPlayer player;
  const _PlayPauseButton({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.primary),
            ),
          );
        } else if (playing != true) {
          return IconButton.filled(
            onPressed: player.play,
            icon: const Icon(Icons.play_arrow_rounded, size: 32),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton.filled(
            onPressed: player.pause,
            icon: const Icon(Icons.pause_rounded, size: 32),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          );
        } else {
          return IconButton.filled(
            onPressed: () => player.seek(Duration.zero),
            icon: const Icon(Icons.replay_rounded, size: 32),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          );
        }
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioPlayer player;
  const _ProgressBar({required this.player});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: colors.border.withValues(alpha: 0.3),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble().clamp(0.01, double.infinity),
                onChanged: (v) => player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(position),
                      style: TextStyle(fontSize: 11, color: colors.textMuted)),
                  Text(_format(duration),
                      style: TextStyle(fontSize: 11, color: colors.textMuted)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _format(Duration d) {
    final min = d.inMinutes;
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
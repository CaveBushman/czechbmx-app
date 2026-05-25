import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class NewsAudioPlayer extends HookWidget {
  final String url;

  const NewsAudioPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final player = useMemoized(AudioPlayer.new);
    final isReady = useState(false);
    final isPlaying = useState(false);
    final isLoading = useState(false);
    final hasError = useState(false);
    final position = useState(Duration.zero);
    final duration = useState(Duration.zero);

    useEffect(() {
      Future<void> init() async {
        try {
          isLoading.value = true;
          await player.setUrl(url);
          duration.value = player.duration ?? Duration.zero;
          isReady.value = true;
        } catch (_) {
          hasError.value = true;
        } finally {
          isLoading.value = false;
        }
      }

      init();

      final posSub = player.positionStream.listen((p) => position.value = p);
      final durSub = player.durationStream.listen(
        (d) => duration.value = d ?? Duration.zero,
      );
      final stateSub = player.playerStateStream.listen((s) {
        isPlaying.value = s.playing;
        // Auto-reset to start when finished
        if (s.processingState == ProcessingState.completed) {
          player.seek(Duration.zero);
          player.pause();
        }
      });

      return () {
        posSub.cancel();
        durSub.cancel();
        stateSub.cancel();
        player.dispose();
      };
    }, []);

    if (hasError.value) return const SizedBox.shrink();

    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.headphones, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                context.l10n.audioArticle,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                _fmt(duration.value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: colors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: duration.value.inMilliseconds > 0
                  ? position.value.inMilliseconds.toDouble().clamp(
                        0,
                        duration.value.inMilliseconds.toDouble(),
                      )
                  : 0,
              max: duration.value.inMilliseconds > 0
                  ? duration.value.inMilliseconds.toDouble()
                  : 1,
              onChanged: isReady.value
                  ? (v) => player.seek(Duration(milliseconds: v.toInt()))
                  : null,
            ),
          ),
          // Time row + play button
          Row(
            children: [
              Text(
                _fmt(position.value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              // Rewind 10s
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.replay_10, color: colors.textSecondary),
                onPressed: isReady.value
                    ? () => player.seek(
                          Duration(
                            milliseconds:
                                (position.value.inMilliseconds - 10000)
                                    .clamp(0, double.infinity)
                                    .toInt(),
                          ),
                        )
                    : null,
              ),
              // Play / pause
              _PlayButton(
                isLoading:
                    isLoading.value || (!isReady.value && !hasError.value),
                isPlaying: isPlaying.value,
                onTap: () {
                  if (!isReady.value) return;
                  isPlaying.value ? player.pause() : player.play();
                },
              ),
              // Forward 10s
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.forward_10, color: colors.textSecondary),
                onPressed: isReady.value
                    ? () => player.seek(
                          Duration(
                            milliseconds:
                                (position.value.inMilliseconds + 10000)
                                    .clamp(0, duration.value.inMilliseconds),
                          ),
                        )
                    : null,
              ),
              const Spacer(),
              Text(
                _fmt(duration.value),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PlayButton extends StatelessWidget {
  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isLoading,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }
}

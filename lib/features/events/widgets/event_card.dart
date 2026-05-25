import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';

class EventCard extends HookWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tilt = useState(Offset.zero);
    final pressed = useState(false);

    if (event.canceled) {
      return Opacity(opacity: 0.45, child: _CardContent(event: event, onTap: null));
    }

    void onPointerMove(PointerEvent e) {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;
      final local = box.globalToLocal(e.position);
      tilt.value = Offset(
        ((local.dx / box.size.width) - 0.5).clamp(-1.0, 1.0),
        ((local.dy / box.size.height) - 0.5).clamp(-1.0, 1.0),
      );
    }

    void onPointerEnd(PointerEvent _) {
      tilt.value = Offset.zero;
      pressed.value = false;
    }

    return Listener(
      onPointerMove: onPointerMove,
      onPointerUp: onPointerEnd,
      onPointerCancel: onPointerEnd,
      child: GestureDetector(
        onTap: onTap,
        onTapDown: (_) => pressed.value = true,
        onTapUp: (_) => pressed.value = false,
        onTapCancel: () => pressed.value = false,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: Offset.zero, end: tilt.value),
          duration: tilt.value == Offset.zero
              ? const Duration(milliseconds: 400)
              : const Duration(milliseconds: 80),
          curve: tilt.value == Offset.zero ? Curves.easeOutBack : Curves.easeOut,
          builder: (context, value, child) {
            final intensity = value.distance;
            return AnimatedScale(
              scale: pressed.value ? 0.975 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(-value.dy * 0.18)
                  ..rotateY(value.dx * 0.18),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    child!,
                    // Specular highlight
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  (-value.dx * 1.8).clamp(-1.5, 1.5),
                                  (-value.dy * 1.8).clamp(-1.5, 1.5),
                                ),
                                radius: 1.4,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: (0.22 * intensity).clamp(0, 0.18),
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: _CardContent(event: event, onTap: onTap),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _CardContent({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typeColor = _typeColor(event.type, context);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: typeColor, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.date != null) _DateBadge(date: event.date!, typeColor: typeColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeChip(type: event.type, color: typeColor),
                  const SizedBox(height: 6),
                  Text(
                    event.canceled
                        ? '${event.name} — ${context.l10n.canceled}'
                        : event.name,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          decoration: event.canceled ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (event.doubleRace)
                        _SmallBadge(context.l10n.twoDays, AppColors.primary),
                      if (event.isUciRace)
                        _SmallBadge('UCI', Colors.blue.shade700),
                      if (event.isRegistrationOpen)
                        _SmallBadge(context.l10n.registrationOpen, AppColors.success),
                      if (event.type.isInternational)
                        _SmallBadge(context.l10n.international, Colors.purple.shade700),
                    ],
                  ),
                ],
              ),
            ),
            if (!event.canceled)
              Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  static Color _typeColor(EventType type, BuildContext context) {
    return switch (type) {
      EventType.mistrovstviCrJednotlivcu ||
      EventType.mistrovstviCrDruzstev =>
        const Color(0xFFFFD700),
      EventType.ceskyPohar => AppColors.primary,
      EventType.ceskaLiga => const Color(0xFF22C55E),
      EventType.moravskaLiga => const Color(0xFF8B5CF6),
      EventType.evropskyPohar || EventType.mistrovstviEvropy => Colors.blue,
      EventType.mistrovstviSveta || EventType.svetovyPohar => const Color(0xFFEC4899),
      _ => context.colors.textMuted,
    };
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final Color typeColor;

  const _DateBadge({required this.date, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: typeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('d').format(date),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1,
            ),
          ),
          Text(
            DateFormat('MMM', context.l10n.languageCode).format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: typeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final EventType type;
  final Color color;

  const _TypeChip({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      type.label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: color,
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

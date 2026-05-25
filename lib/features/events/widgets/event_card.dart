import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: event.canceled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: event.canceled ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: _typeColor(event.type, context), width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.date != null) _DateBadge(date: event.date!),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TypeChip(type: event.type),
                      const SizedBox(height: 6),
                      Text(
                        event.canceled ? '${event.name} — ZRUŠENO' : event.name,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                              decoration: event.canceled ? TextDecoration.lineThrough : null,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (event.doubleRace) const _SmallBadge('2 dny', AppColors.primary),
                          if (event.isUciRace) _SmallBadge('UCI', Colors.blue.shade700),
                          if (event.isRegistrationOpen)
                            const _SmallBadge('Registrace otevřena', AppColors.success),
                          if (event.type.isInternational)
                            _SmallBadge('Mezinárodní', Colors.purple.shade700),
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

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
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
            DateFormat('MMM', 'cs').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
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

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Text(
      type.label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: EventCard._typeColor(type, context),
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
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

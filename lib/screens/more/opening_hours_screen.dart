import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../data/library_images.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Library opening hours — also linked from Home and More.
class OpeningHoursScreen extends StatefulWidget {
  const OpeningHoursScreen({super.key});

  @override
  State<OpeningHoursScreen> createState() => _OpeningHoursScreenState();
}

class _OpeningHoursScreenState extends State<OpeningHoursScreen> {
  late Timer _timer;
  late DateTime _pkTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update every minute to keep the status fresh
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    // Pakistan is UTC+5
    _pkTime = DateTime.now().toUtc().add(const Duration(hours: 5));
  }

  static const _schedule = <(String, String)>[
    ('Monday – Thursday', '8:00 AM – 9:00 PM'),
    ('Friday', '8:00 AM – 5:00 PM'),
    ('Saturday & Sunday', 'Closed'),
  ];

  _StatusData _calculateStatus() {
    final day = _pkTime.weekday;
    final hour = _pkTime.hour;
    final minute = _pkTime.minute;
    final currentTimeInMinutes = hour * 60 + minute;

    // Define hours in minutes from midnight
    const openTime = 8 * 60; // 8:00 AM
    const closeTimeMonThu = 21 * 60; // 9:00 PM
    const closeTimeFri = 17 * 60; // 5:00 PM

    bool isOpen = false;
    int minutesUntilChange = 0;
    bool transitionToClosed = true;

    if (day >= DateTime.monday && day <= DateTime.thursday) {
      if (currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTimeMonThu) {
        isOpen = true;
        minutesUntilChange = closeTimeMonThu - currentTimeInMinutes;
        transitionToClosed = true;
      } else if (currentTimeInMinutes < openTime) {
        isOpen = false;
        minutesUntilChange = openTime - currentTimeInMinutes;
        transitionToClosed = false;
      } else {
        isOpen = false;
        minutesUntilChange = (24 * 60 - currentTimeInMinutes) + openTime;
        transitionToClosed = false;
      }
    } else if (day == DateTime.friday) {
      if (currentTimeInMinutes >= openTime && currentTimeInMinutes < closeTimeFri) {
        isOpen = true;
        minutesUntilChange = closeTimeFri - currentTimeInMinutes;
        transitionToClosed = true;
      } else if (currentTimeInMinutes < openTime) {
        isOpen = false;
        minutesUntilChange = openTime - currentTimeInMinutes;
        transitionToClosed = false;
      } else {
        isOpen = false;
        // Next open is Monday 8 AM
        minutesUntilChange = (24 * 60 - currentTimeInMinutes) + (2 * 24 * 60) + openTime;
        transitionToClosed = false;
      }
    } else {
      // Saturday or Sunday
      isOpen = false;
      int daysUntilMonday = (8 - day) % 7;
      if (daysUntilMonday == 0) daysUntilMonday = 7;
      minutesUntilChange = (daysUntilMonday - 1) * 24 * 60 + (24 * 60 - currentTimeInMinutes) + openTime;
      transitionToClosed = false;
    }

    String label = isOpen ? "Open Now" : "Closed";
    String relativeMsg = "";

    if (minutesUntilChange <= 15) {
      relativeMsg = transitionToClosed ? "Less than 15 mins to close" : "Less than 15 mins to open";
    } else if (minutesUntilChange <= 60) {
      relativeMsg = transitionToClosed ? "Closing in an hour" : "Opening in an hour";
    }

    return _StatusData(
      isOpen: isOpen,
      label: label,
      relativeMsg: relativeMsg,
      isWarning: minutesUntilChange <= 60,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);
    final status = _calculateStatus();

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                frontDeskImagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Heading(level: 4, text: 'Opening Hours'),
              _buildStatusBadge(colors, status),
            ],
          ),
          if (status.relativeMsg.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              status.relativeMsg,
              variant: 'bodySmall',
              style: TextStyle(
                color: status.isWarning ? Colors.orange.shade700 : colors.text.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: colors.background.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: shadow.border,
              boxShadow: shadow.boxShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _schedule.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.ms,
                    ),
                    decoration: BoxDecoration(
                      border: i < _schedule.length - 1
                          ? Border(bottom: BorderSide(color: colors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 18,
                          color: colors.brand,
                        ),
                        const SizedBox(width: AppSpacing.ms),
                        Expanded(
                          child: AppText(
                            _schedule[i].$1,
                            variant: 'bodyBase',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        AppText(
                          _schedule[i].$2,
                          variant: 'bodySmall',
                          tone: 'secondary',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            'On Fridays, service counters close from 1:00 PM to 2:00 PM for Jumma prayer.',
            variant: 'bodyBase',
            tone: 'secondary',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SemanticColors colors, _StatusData status) {
    final bgColor = status.isOpen
        ? (status.isWarning ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1))
        : Colors.red.withOpacity(0.1);
    final textColor = status.isOpen
        ? (status.isWarning ? Colors.orange.shade800 : Colors.green.shade800)
        : Colors.red.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          AppText(
            status.label,
            variant: 'bodySmall',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusData {
  final bool isOpen;
  final String label;
  final String relativeMsg;
  final bool isWarning;

  _StatusData({
    required this.isOpen,
    required this.label,
    required this.relativeMsg,
    required this.isWarning,
  });
}
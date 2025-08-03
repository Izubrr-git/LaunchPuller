import 'package:flutter/material.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';

/// Индикатор статуса Launchpool
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 8,
    this.showLabel = false,
  });

  final LaunchpoolStatus status;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(LaunchpoolStatus status) {
    switch (status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }
}

/// Анимированный индикатор статуса
class AnimatedStatusIndicator extends StatefulWidget {
  const AnimatedStatusIndicator({
    super.key,
    required this.status,
    this.size = 8,
    this.showLabel = false,
  });

  final LaunchpoolStatus status;
  final double size;
  final bool showLabel;

  @override
  State<AnimatedStatusIndicator> createState() => _AnimatedStatusIndicatorState();
}

class _AnimatedStatusIndicatorState extends State<AnimatedStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.status == LaunchpoolStatus.active) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.status == LaunchpoolStatus.active) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(widget.status);

    Widget indicator = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.status == LaunchpoolStatus.active
              ? _scaleAnimation.value
              : 1.0,
          child: Opacity(
            opacity: widget.status == LaunchpoolStatus.active
                ? _opacityAnimation.value
                : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: widget.status == LaunchpoolStatus.active
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
              ),
            ),
          ),
        );
      },
    );

    if (widget.showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(width: 6),
          Text(
            widget.status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return indicator;
  }

  Color _getStatusColor(LaunchpoolStatus status) {
    switch (status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }
}

/// Статусный чип
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final LaunchpoolStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusIndicator(
            status: status,
            size: compact ? 6 : 8,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            status.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LaunchpoolStatus status) {
    switch (status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }
}

/// Прогресс-бар статуса
class StatusProgressBar extends StatelessWidget {
  const StatusProgressBar({
    super.key,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.height = 4,
  });

  final LaunchpoolStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final double height;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime).inMilliseconds;
    final elapsed = now.difference(startTime).inMilliseconds;

    double progress = 0.0;
    Color color = Colors.grey;

    switch (status) {
      case LaunchpoolStatus.upcoming:
        progress = 0.0;
        color = Colors.blue;
        break;
      case LaunchpoolStatus.active:
        if (totalDuration > 0) {
          progress = (elapsed / totalDuration).clamp(0.0, 1.0);
        }
        color = Colors.green;
        break;
      case LaunchpoolStatus.ended:
        progress = 1.0;
        color = Colors.grey;
        break;
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
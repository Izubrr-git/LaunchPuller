import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/cards/launchpool_card.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
    this.breakpoint = 800,
  });

  final Widget mobile;
  final Widget desktop;
  final Widget? tablet;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return desktop;
        } else if (tablet != null && constraints.maxWidth >= 600) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveLaunchpoolGrid extends StatelessWidget {
  const ResponsiveLaunchpoolGrid({
    super.key,
    required this.launchpools,
  });

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileLayout(launchpools: launchpools),
      tablet: _TabletLayout(launchpools: launchpools),
      desktop: _DesktopLayout(launchpools: launchpools),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.launchpools});

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    // Мобильная версия остается ListView для лучшего UX
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: launchpools.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return LaunchpoolCard(launchpool: launchpools[index]);
      },
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.launchpools});

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: launchpools.map((launchpool) {
          return StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: LaunchpoolCard(launchpool: launchpool),
          );
        }).toList(),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.launchpools});

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: StaggeredGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        children: launchpools.map((launchpool) {
          return StaggeredGridTile.fit(
            crossAxisCellCount: 1,
            child: LaunchpoolCard(launchpool: launchpool),
          );
        }).toList(),
      ),
    );
  }
}

/// Альтернативная версия с лучшей производительностью для больших списков
class _TabletLayoutPerformant extends StatelessWidget {
  const _TabletLayoutPerformant({required this.launchpools});

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      itemCount: launchpools.length,
      itemBuilder: (context, index) {
        return LaunchpoolCard(launchpool: launchpools[index]);
      },
    );
  }
}

class _DesktopLayoutPerformant extends StatelessWidget {
  const _DesktopLayoutPerformant({required this.launchpools});

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 3,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      itemCount: launchpools.length,
      itemBuilder: (context, index) {
        return LaunchpoolCard(launchpool: launchpools[index]);
      },
    );
  }
}

/// Адаптивная версия, которая автоматически выбирает количество колонок
class ResponsiveStaggeredGrid extends StatelessWidget {
  const ResponsiveStaggeredGrid({
    super.key,
    required this.launchpools,
    this.minItemWidth = 300,
    this.spacing = 16,
    this.padding,
  });

  final List<Launchpool> launchpools;
  final double minItemWidth;
  final double spacing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Автоматически вычисляем количество колонок
        final availableWidth = constraints.maxWidth - (padding?.horizontal ?? 32);
        final crossAxisCount = (availableWidth / (minItemWidth + spacing)).floor().clamp(1, 4);

        return SingleChildScrollView(
          padding: padding ?? const EdgeInsets.all(16),
          child: StaggeredGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            children: launchpools.map((launchpool) {
              return StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: LaunchpoolCard(launchpool: launchpool),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Специальная версия для разных размеров карточек
class AdvancedStaggeredGrid extends StatelessWidget {
  const AdvancedStaggeredGrid({
    super.key,
    required this.launchpools,
  });

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StaggeredGrid.count(
        crossAxisCount: 4, // Базовая сетка 4 колонки
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: launchpools.asMap().entries.map((entry) {
          final index = entry.key;
          final launchpool = entry.value;

          // Разные размеры для различных типов проектов
          int crossAxisCellCount = 1;

          // Активные проекты выделяются
          if (launchpool.isActive && index == 0) {
            crossAxisCellCount = 2;
          }

          return StaggeredGridTile.fit(
            crossAxisCellCount: crossAxisCellCount,
            child: LaunchpoolCard(launchpool: launchpool),
          );
        }).toList(),
      ),
    );
  }
}
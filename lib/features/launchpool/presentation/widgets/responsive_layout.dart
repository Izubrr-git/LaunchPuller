import 'package:flutter/material.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/launchpool_card.dart';

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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: launchpools.length,
      itemBuilder: (context, index) {
        return LaunchpoolCard(launchpool: launchpools[index]);
      },
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.launchpools});

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.75,
      ),
      itemCount: launchpools.length,
      itemBuilder: (context, index) {
        return LaunchpoolCard(launchpool: launchpools[index]);
      },
    );
  }
}
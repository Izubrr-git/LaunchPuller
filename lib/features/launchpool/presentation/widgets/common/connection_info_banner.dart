import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';

class ConnectionInfoBanner extends ConsumerWidget {
  const ConnectionInfoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (authState) {
        if (!authState.isAuthenticated) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Настройте API ключи для участия в пулах',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AuthSetupDialog(),
                    );
                  },
                  child: const Text('Настроить'),
                ),
              ],
            ),
          );
        }

        if (authState.credentials?.isTestnet == true) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  '🧪 Режим Testnet активен',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
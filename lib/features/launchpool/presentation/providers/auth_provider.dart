import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  @override
  Future<AuthData> build() async {
    final authService = ref.watch(bybitAuthServiceProvider);
    final credentials = await authService.getCredentials();

    return AuthData(
      isAuthenticated: credentials != null,
      credentials: credentials,
    );
  }

  Future<void> setCredentials({
    required String apiKey,
    required String apiSecret,
    required bool isTestnet,
  }) async {
    final authService = ref.read(bybitAuthServiceProvider);
    final credentials = BybitCredentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      isTestnet: isTestnet,
    );

    await authService.saveCredentials(credentials);

    state = AsyncValue.data(AuthData(
      isAuthenticated: true,
      credentials: credentials,
    ));
  }

  Future<void> clearCredentials() async {
    final authService = ref.read(bybitAuthServiceProvider);
    await authService.clearCredentials();

    state = const AsyncValue.data(AuthData(
      isAuthenticated: false,
      credentials: null,
    ));
  }

  Future<void> toggleTestnet() async {
    final currentState = state.value;
    if (currentState?.credentials == null) return;

    final authService = ref.read(bybitAuthServiceProvider);
    await authService.toggleTestnet();

    final newCredentials = currentState!.credentials!.copyWith(
      isTestnet: !currentState.credentials!.isTestnet,
    );

    await authService.saveCredentials(newCredentials);

    state = AsyncValue.data(AuthData(
      isAuthenticated: true,
      credentials: newCredentials,
    ));
  }
}

class AuthData {
  const AuthData({
    required this.isAuthenticated,
    this.credentials,
  });

  final bool isAuthenticated;
  final BybitCredentials? credentials;

  AuthData copyWith({
    bool? isAuthenticated,
    BybitCredentials? credentials,
  }) {
    return AuthData(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      credentials: credentials ?? this.credentials,
    );
  }
}
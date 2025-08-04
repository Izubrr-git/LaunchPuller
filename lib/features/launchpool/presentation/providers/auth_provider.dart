import 'package:launch_puller/core/security/secure_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthState extends _$AuthState {
  @override
  Future<AuthData> build() async {
    final authService = ref.watch(bybitAuthServiceProvider);
    final credentials = await authService.getCredentials(requireAuth: false);

    return AuthData(
      isAuthenticated: credentials != null,
      credentials: credentials,
      securityAssessment: await authService.assessSecurity(),
    );
  }

  Future<void> setCredentials({
    required String apiKey,
    required String apiSecret,
    required bool isTestnet,
    String? userPassword,
  }) async {
    final authService = ref.read(bybitAuthServiceProvider);
    final credentials = BybitCredentials(
      apiKey: apiKey,
      apiSecret: apiSecret,
      isTestnet: isTestnet,
    );

    await authService.saveCredentials(
      credentials,
      userPassword: userPassword,
    );

    // Обновляем состояние
    state = AsyncValue.data(AuthData(
      isAuthenticated: true,
      credentials: credentials,
      securityAssessment: await authService.assessSecurity(),
    ));
  }

  Future<void> clearCredentials() async {
    final authService = ref.read(bybitAuthServiceProvider);
    await authService.clearCredentials();

    state = AsyncValue.data(AuthData(
      isAuthenticated: false,
      credentials: null,
      securityAssessment: await authService.assessSecurity(),
    ));
  }

  Future<void> toggleTestnet() async {
    final authService = ref.read(bybitAuthServiceProvider);
    await authService.toggleTestnet();

    // Обновляем состояние
    final currentState = state.value;
    if (currentState?.credentials != null) {
      final updatedCredentials = currentState!.credentials!.copyWith(
        isTestnet: !currentState.credentials!.isTestnet,
      );

      state = AsyncValue.data(currentState.copyWith(
        credentials: updatedCredentials,
      ));
    }
  }

  Future<void> refreshSecurityAssessment() async {
    final currentState = state.value;
    if (currentState == null) return;

    final authService = ref.read(bybitAuthServiceProvider);
    final newAssessment = await authService.assessSecurity();

    state = AsyncValue.data(currentState.copyWith(
      securityAssessment: newAssessment,
    ));
  }
}

class AuthData {
  const AuthData({
    required this.isAuthenticated,
    this.credentials,
    required this.securityAssessment,
  });

  final bool isAuthenticated;
  final BybitCredentials? credentials;
  final SecurityAssessment securityAssessment;

  AuthData copyWith({
    bool? isAuthenticated,
    BybitCredentials? credentials,
    SecurityAssessment? securityAssessment,
  }) {
    return AuthData(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      credentials: credentials ?? this.credentials,
      securityAssessment: securityAssessment ?? this.securityAssessment,
    );
  }
}
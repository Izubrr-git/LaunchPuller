// bybit_datasource.dart - ОБНОВЛЕННАЯ ВЕРСИЯ
import 'dart:convert';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/exchange_exceptions.dart';
import '../../../../../core/services/cache_service.dart';
import '../../../../../core/utils/api_client.dart';
import '../exchange_datasource.dart';
import 'bybit_api_models.dart';
import 'bybit_auth_service.dart';

part 'bybit_datasource.g.dart';

@riverpod
BybitDataSource bybitDataSource(BybitDataSourceRef ref) {
  return BybitDataSource(
    apiClient: ref.watch(apiClientProvider),
    cacheService: ref.watch(cacheServiceProvider),
    authService: ref.watch(bybitAuthServiceProvider),
  );
}

class BybitDataSource implements ExchangeDataSource {
  const BybitDataSource({
    required this.apiClient,
    required this.cacheService,
    required this.authService,
  });

  final ApiClient apiClient;
  final CacheService cacheService;
  final BybitAuthService authService;

  @override
  ExchangeType get exchangeType => ExchangeType.bybit;

  @override
  Future<List<Map<String, dynamic>>> fetchLaunchpools() async {
    const cacheKey = 'bybit_launchpools_all';

    // Проверяем кэш
    final cached = cacheService.get(cacheKey);
    if (cached != null && !cached.isExpired) {
      return List<Map<String, dynamic>>.from(cached.data);
    }

    try {
      // Получаем активные Launchpool проекты
      final currentProjects = await _fetchCurrentLaunchpools();
      print('🔴 Активных проектов: ${currentProjects.length}');

      // Получаем завершённые Launchpool проекты (историю)
      final historyProjects = await _fetchLaunchpoolHistoryProjects();
      print('🔵 Завершённых проектов: ${historyProjects.length}');

      // Объединяем активные и завершённые проекты
      final allProjects = <Map<String, dynamic>>[
        // Активные проекты (из /home)
        ...currentProjects.map((p) => _currentProjectToMap(p)),
        // Завершённые проекты (из /history)
        ...historyProjects.map((h) => _historyItemToMap(h)),
      ];

      print('📊 Всего проектов: ${allProjects.length}');

      // Сохраняем в кэш
      cacheService.set(cacheKey, allProjects, duration: ApiConstants.cacheExpiry);
      return allProjects;

    } catch (e) {
      throw NetworkException('Ошибка получения Launchpool данных: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchLaunchpoolById(String id) async {
    final pools = await fetchLaunchpools();
    final pool = pools.firstWhere(
          (p) => p['productId'] == id,
      orElse: () => throw ApiException('Launchpool с ID $id не найден'),
    );
    return pool;
  }

  /// Получение активных Launchpool проектов (/home)
  Future<List<BybitLaunchpoolProject>> _fetchCurrentLaunchpools() async {
    try {
      final response = await apiClient.get(
        url: '${ApiConstants.bybitWebApi}${ApiConstants.bybitLaunchpoolCurrent}',
        headers: ApiConstants.webApiHeaders,
      );

      final homeResponse = BybitLaunchpoolHomeResponse.fromJson(response);
      print('✅ Активных Launchpool: ${homeResponse.projects.length}');

      return homeResponse.projects;
    } catch (e) {
      print('⚠️ Ошибка получения активных Launchpool: $e');
      return [];
    }
  }

  /// Получение завершённых Launchpool проектов (/history)
  Future<List<BybitLaunchpoolHistoryItem>> _fetchLaunchpoolHistoryProjects({
    int pageSize = 20,
    int current = 1,
  }) async {
    try {
      final body = {
        'pageSize': pageSize,
        'current': current,
      };

      final response = await apiClient.post(
        url: '${ApiConstants.bybitWebApi}${ApiConstants.bybitLaunchpoolHistory}',
        headers: ApiConstants.webApiHeaders,
        body: jsonEncode(body),
      );

      print('🔍 Ответ history API: ${response.keys.toList()}');

      final historyResponse = BybitLaunchpoolHistoryResponse.fromJson(response);
      print('✅ Завершённых Launchpool: ${historyResponse.items.length}');

      return historyResponse.items;
    } catch (e) {
      print('⚠️ Ошибка получения истории Launchpool: $e');
      return [];
    }
  }

  /// Преобразование активного проекта в Map
  Map<String, dynamic> _currentProjectToMap(BybitLaunchpoolProject project) {
    return {
      'productId': project.id,
      'category': 'Launchpool',
      'coin': project.symbol,
      'estimateApr': '${project.apr}%',
      'minStakeAmount': project.minStakeAmount?.toString() ?? '0',
      'maxStakeAmount': project.maxStakeAmount?.toString() ?? '0',
      'status': 'Available', // Активные всегда Available
      'productName': project.name,
      'description': project.description,
      'startTime': project.startTime.millisecondsSinceEpoch.toString(),
      'endTime': project.endTime.millisecondsSinceEpoch.toString(),
      'totalReward': project.totalReward ?? '0',
      'stakingTokens': project.stakingTokens ?? [project.symbol],
      'projectType': 'current', // Метка для различения
    };
  }

  /// Преобразование исторического проекта в Map - ОБНОВЛЕНО под новую модель Launchpool
  Map<String, dynamic> _historyItemToMap(BybitLaunchpoolHistoryItem item) {
    final primaryPool = item.primaryPool;

    return {
      'productId': item.code,
      'category': 'Launchpool',
      'coin': item.returnCoin,
      'estimateApr': '${item.maxApr.toStringAsFixed(2)}%',
      'minStakeAmount': item.minStakeAmount.toString(),
      'maxStakeAmount': item.maxStakeAmount.toString(),
      'status': item.isActive ? 'Available' : 'NotAvailable',
      'productName': item.name,
      'description': item.desc.length > 200
          ? '${item.desc.substring(0, 200)}...'
          : item.desc,
      'startTime': item.startTime.millisecondsSinceEpoch.toString(),
      'endTime': item.endTime.millisecondsSinceEpoch.toString(),
      'totalReward': item.totalPoolAmount,
      'stakingTokens': item.stakingTokens,
      'projectType': 'history',
      'returnCoinIcon': item.returnCoinIcon,
      'website': item.website,
      'whitepaper': item.whitepaper,
      'rules': item.rules,
      'totalUsers': primaryPool?.totalUser ?? 0,
      'totalStaked': primaryPool?.totalAmountDouble ?? 0.0,
      // Новые поля для полного маппинга
      'code': item.code,
      'aprHigh': item.maxApr,
      'stakeBeginTime': item.stakeBeginTime,
      'stakeEndTime': item.stakeEndTime,
      'tradeBeginTime': item.tradeBeginTime,
      'feTimeStatus': item.feTimeStatus,
      'signUpStatus': item.signUpStatus,
      'openWarmingUpPledge': item.openWarmingUpPledge,
      'stakePoolList': item.stakePoolList.map((pool) => {
        'stakePoolCode': pool.stakePoolCode,
        'stakeCoin': pool.stakeCoin,
        'stakeCoinIcon': pool.stakeCoinIcon,
        'apr': pool.aprDouble,
        'aprVip': pool.aprVipDouble,
        'minStakeAmount': pool.minStakeAmountDouble,
        'maxStakeAmount': pool.maxStakeAmountDouble,
        'totalUsers': pool.totalUser,
        'poolAmount': pool.poolAmountDouble,
        'totalAmount': pool.totalAmountDouble,
        'samePeriod': pool.samePeriod,
        'stakeBeginTime': pool.stakeBeginTime,
        'stakeEndTime': pool.stakeEndTime,
        'vipAdd': pool.vipAdd,
        'minVipAmount': pool.minVipAmountDouble,
        'maxVipAmount': pool.maxVipAmountDouble,
        'vipPercent': pool.vipPercent,
        'poolTag': pool.poolTag,
        'useNewUserFunction': pool.useNewUserFunction,
        'useNewVipFunction': pool.useNewVipFunction,
        'openWarmingUpPledge': pool.openWarmingUpPledge,
        'newVipPercent': pool.newVipPercent,
        'minNewVipAmount': pool.minNewVipAmount,
        'maxNewVipAmount': pool.maxNewVipAmount,
        'newVipValidateDays': pool.newVipValidateDays,
        'minNewUserAmount': pool.minNewUserAmount,
        'maxNewUserAmount': pool.maxNewUserAmount,
        'newUserValidateDays': pool.newUserValidateDays,
        'newUserPercent': pool.newUserPercent,
        'myTotalYield': pool.myTotalYield,
        'poolLoanConfig': pool.poolLoanConfig,
        'leverage': pool.leverage,
        'maxStakeLimit': pool.maxStakeLimit,
        'dailyIncomeAmt': pool.dailyIncomeAmt,
        'newUserTag': pool.newUserTag,
        'newVipUserTag': pool.newVipUserTag,
      }).toList(),
    };
  }

  /// Получение истории Launchpool для пользователей
  Future<List<BybitLaunchpoolHistoryItem>> fetchLaunchpoolHistoryItems({
    int pageSize = 20,
    int current = 1,
  }) async {
    return await _fetchLaunchpoolHistoryProjects(
      pageSize: pageSize,
      current: current,
    );
  }

  /// Подписка на продукт
  Future<String> subscribeToLaunchpool({
    required String productId,
    required String amount,
  }) async {
    try {
      final credentials = await authService.getCredentials();
      if (credentials == null) {
        throw const ApiException('Необходима аутентификация');
      }

      final body = {
        'productId': productId,
        'amount': amount,
      };
      final bodyString = jsonEncode(body);

      final headers = await authService.buildAuthHeaders(
        endpoint: ApiConstants.bybitEarnSubscribe,
        method: 'POST',
        body: bodyString,
      );

      final response = await apiClient.post(
        url: '${credentials.baseUrl}${ApiConstants.bybitEarnSubscribe}',
        headers: headers,
        body: bodyString,
      );

      final apiResponse = BybitApiResponse<BybitEarnOperationResponse>.fromJson(
        response,
            (json) => BybitEarnOperationResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(
          'Ошибка подписки: ${apiResponse.errorMessage}',
          apiResponse.retCode,
        );
      }

      return apiResponse.result?.orderId ?? '';
    } catch (e) {
      throw NetworkException('Ошибка подписки на продукт: $e');
    }
  }

  /// Погашение продукта
  Future<String> redeemFromLaunchpool({
    required String productId,
    required String amount,
  }) async {
    try {
      final credentials = await authService.getCredentials();
      if (credentials == null) {
        throw const ApiException('Необходима аутентификация');
      }

      final body = {
        'productId': productId,
        'amount': amount,
      };
      final bodyString = jsonEncode(body);

      final headers = await authService.buildAuthHeaders(
        endpoint: ApiConstants.bybitEarnRedeem,
        method: 'POST',
        body: bodyString,
      );

      final response = await apiClient.post(
        url: '${credentials.baseUrl}${ApiConstants.bybitEarnRedeem}',
        headers: headers,
        body: bodyString,
      );

      final apiResponse = BybitApiResponse<BybitEarnOperationResponse>.fromJson(
        response,
            (json) => BybitEarnOperationResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(
          'Ошибка погашения: ${apiResponse.errorMessage}',
          apiResponse.retCode,
        );
      }

      return apiResponse.result?.orderId ?? '';
    } catch (e) {
      throw NetworkException('Ошибка погашения продукта: $e');
    }
  }

  /// Получение подробной информации о конкретном пуле стейкинга
  Future<Map<String, dynamic>?> fetchStakePoolDetails({
    required String stakePoolCode,
  }) async {
    try {
      final historyItems = await fetchLaunchpoolHistoryItems(pageSize: 50);

      for (final item in historyItems) {
        final pool = item.stakePoolList.firstWhere(
              (pool) => pool.stakePoolCode == stakePoolCode,
          orElse: () => throw Exception('Pool not found'),
        );

        if (pool.stakePoolCode == stakePoolCode) {
          return {
            'stakePoolCode': pool.stakePoolCode,
            'stakeCoin': pool.stakeCoin,
            'stakeCoinIcon': pool.stakeCoinIcon,
            'apr': pool.aprDouble,
            'aprVip': pool.aprVipDouble,
            'minStakeAmount': pool.minStakeAmountDouble,
            'maxStakeAmount': pool.maxStakeAmountDouble,
            'totalUsers': pool.totalUser,
            'poolAmount': pool.poolAmountDouble,
            'totalAmount': pool.totalAmountDouble,
            'projectInfo': {
              'code': item.code,
              'returnCoin': item.returnCoin,
              'desc': item.desc,
              'website': item.website,
              'whitepaper': item.whitepaper,
              'rules': item.rules,
            },
          };
        }
      }

      return null;
    } catch (e) {
      print('⚠️ Ошибка получения деталей пула $stakePoolCode: $e');
      return null;
    }
  }

  /// Получение статистики по всем Launchpool проектам
  Future<Map<String, dynamic>> fetchLaunchpoolStatistics() async {
    try {
      final allProjects = await fetchLaunchpools();

      final activePools = allProjects.where((p) => p['status'] == 'Available').length;
      final endedPools = allProjects.where((p) => p['status'] == 'NotAvailable').length;

      final totalUsers = allProjects.fold<int>(0, (sum, project) {
        return sum + (project['totalUsers'] as int? ?? 0);
      });

      final totalStaked = allProjects.fold<double>(0.0, (sum, project) {
        return sum + (project['totalStaked'] as double? ?? 0.0);
      });

      final highestApr = allProjects.fold<double>(0.0, (maxApr, project) {
        final aprString = project['estimateApr'] as String? ?? '0%';
        final apr = double.tryParse(aprString.replaceAll('%', '')) ?? 0.0;
        return apr > maxApr ? apr : maxApr;
      });

      return {
        'totalProjects': allProjects.length,
        'activePools': activePools,
        'endedPools': endedPools,
        'totalUsers': totalUsers,
        'totalStaked': totalStaked,
        'highestApr': highestApr,
        'averageApr': allProjects.isNotEmpty
            ? allProjects.fold<double>(0.0, (sum, project) {
          final aprString = project['estimateApr'] as String? ?? '0%';
          return sum + (double.tryParse(aprString.replaceAll('%', '')) ?? 0.0);
        }) / allProjects.length
            : 0.0,
      };
    } catch (e) {
      throw NetworkException('Ошибка получения статистики: $e');
    }
  }

  Map<String, String> _buildPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'LaunchpoolManager/1.0.0',
    };
  }
}
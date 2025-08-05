import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

class NetworkStatusIndicator extends StatefulWidget {
  const NetworkStatusIndicator(String string, {
    super.key,
    this.checkInterval = const Duration(seconds: 30),
    this.testUrl = 'https://www.google.com',
    this.size = 20.0,
    this.showText = false,
    this.instanceId,
  });

  /// Интервал проверки подключения
  final Duration checkInterval;

  /// URL для проверки интернет-соединения
  final String testUrl;

  /// Размер иконки
  final double size;

  /// Показывать ли текст рядом с иконкой
  final bool showText;

  final String? instanceId;

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _internetCheckTimer;

  NetworkStatus _networkStatus = NetworkStatus.checking;
  String _connectionType = '';

  @override
  void initState() {
    super.initState();
    _initConnectivityListener();
    _checkNetworkStatus();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetCheckTimer?.cancel();
    super.dispose();
  }

  /// Инициализация слушателя изменений подключения
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged as void Function(List<ConnectivityResult> event)?) as StreamSubscription<ConnectivityResult>?;
  }

  /// Обработка изменений подключения
  void _onConnectivityChanged(ConnectivityResult result) {
    setState(() {
      _connectionType = _getConnectionTypeString(result);
    });

    if (result == ConnectivityResult.none) {
      setState(() {
        _networkStatus = NetworkStatus.offline;
      });
    } else {
      // Проверяем реальное интернет-соединение
      _checkInternetConnection();
    }
  }

  /// Запуск периодической проверки
  void _startPeriodicCheck() {
    _internetCheckTimer = Timer.periodic(widget.checkInterval, (_) {
      _checkNetworkStatus();
    });
  }

  /// Полная проверка статуса сети
  Future<void> _checkNetworkStatus() async {
    setState(() {
      _networkStatus = NetworkStatus.checking;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _connectionType = _getConnectionTypeString(connectivityResult as ConnectivityResult);

      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _networkStatus = NetworkStatus.offline;
        });
        return;
      }

      await _checkInternetConnection();
    } catch (e) {
      setState(() {
        _networkStatus = NetworkStatus.offline;
      });
    }
  }

  /// Проверка реального интернет-соединения
  Future<void> _checkInternetConnection() async {
    try {
      final response = await http.get(
        Uri.parse(widget.testUrl),
      ).timeout(const Duration(seconds: 5));

      setState(() {
        _networkStatus = response.statusCode == 200
            ? NetworkStatus.online
            : NetworkStatus.limited;
      });
    } on SocketException {
      setState(() {
        _networkStatus = NetworkStatus.offline;
      });
    } on TimeoutException {
      setState(() {
        _networkStatus = NetworkStatus.limited;
      });
    } catch (e) {
      setState(() {
        _networkStatus = NetworkStatus.limited;
      });
    }
  }

  /// Преобразование типа подключения в строку
  String _getConnectionTypeString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Мобильная сеть';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Другое';
      case ConnectivityResult.none:
      default:
        return 'Нет подключения';
    }
  }

  /// Получение данных для отображения статуса
  NetworkDisplayData _getDisplayData() {
    switch (_networkStatus) {
      case NetworkStatus.online:
        return NetworkDisplayData(
          icon: Icons.wifi,
          color: Colors.green,
          message: 'Онлайн ($_connectionType)',
          text: 'Онлайн',
        );
      case NetworkStatus.limited:
        return const NetworkDisplayData(
          icon: Icons.wifi_protected_setup,
          color: Colors.orange,
          message: 'Ограниченное подключение',
          text: 'Ограничено',
        );
      case NetworkStatus.offline:
        return const NetworkDisplayData(
          icon: Icons.wifi_off,
          color: Colors.red,
          message: 'Нет интернет-соединения',
          text: 'Оффлайн',
        );
      case NetworkStatus.checking:
        return const NetworkDisplayData(
          icon: Icons.wifi_find,
          color: Colors.grey,
          message: 'Проверка подключения...',
          text: 'Проверка...',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _getDisplayData();

    return GestureDetector(
      onTap: _checkNetworkStatus, // Проверка при нажатии
      child: Tooltip(
        message: displayData.message,
        child: widget.showText
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(displayData),
            const SizedBox(width: 4),
            Text(
              displayData.text,
              style: TextStyle(
                fontSize: 12,
                color: displayData.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
            : _buildIcon(displayData),
      ),
    );
  }

  Widget _buildIcon(NetworkDisplayData displayData) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Icon(
        displayData.icon,
        key: ValueKey(_networkStatus),
        color: displayData.color,
        size: widget.size,
      ),
    );
  }
}

/// Перечисление возможных статусов сети
enum NetworkStatus {
  online,    // Полное подключение к интернету
  limited,   // Есть подключение, но интернет недоступен
  offline,   // Нет подключения
  checking,  // Проверка статуса
}

/// Класс для хранения данных отображения
class NetworkDisplayData {
  final IconData icon;
  final Color color;
  final String message;
  final String text;

  const NetworkDisplayData({
    required this.icon,
    required this.color,
    required this.message,
    required this.text,
  });
}
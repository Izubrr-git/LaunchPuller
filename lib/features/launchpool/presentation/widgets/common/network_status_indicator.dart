import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkStatusIndicator extends StatefulWidget {
  const NetworkStatusIndicator(String string, {
    super.key,
    this.size = 20.0,
    this.showText = false,
    this.instanceId,
  });

  final double size;
  final bool showText;

  final String? instanceId;

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;
  String _connectionType = '';

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _listenToConnectivity() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (!mounted) return;

    final hasConnection = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    setState(() {
      _isConnected = hasConnection;
      _connectionType = hasConnection
          ? _getConnectionTypeString(results.first)
          : 'Нет подключения';
    });
  }

  String _getConnectionTypeString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Мобильная сеть';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      default:
        return 'Подключено';
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _isConnected ? Icons.wifi : Icons.wifi_off;
    final color = _isConnected ? Colors.green : Colors.red;
    final text = _isConnected ? 'Онлайн' : 'Оффлайн';

    return Tooltip(
      message: _connectionType,
      child: widget.showText
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: widget.size),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          : Icon(icon, color: color, size: widget.size),
    );
  }
}
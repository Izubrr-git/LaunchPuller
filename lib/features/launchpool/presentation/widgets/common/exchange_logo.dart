import 'package:flutter/material.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';

class ExchangeLogo extends StatelessWidget {
  const ExchangeLogo({
    super.key,
    required this.exchange,
    this.size = 24,
  });

  final ExchangeType exchange;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getExchangeColor(exchange),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getExchangeInitial(exchange),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getExchangeColor(ExchangeType exchange) {
    switch (exchange) {
      case ExchangeType.bybit:
        return const Color(0xFFF7931A); // Оранжевый Bybit
    case ExchangeType.binance:
      return const Color(0xFFF0B90B); // Желтый Binance
    case ExchangeType.okx:
      return const Color(0xFF0052FF); // Синий OKX
    }
  }

  String _getExchangeInitial(ExchangeType exchange) {
    switch (exchange) {
      case ExchangeType.bybit:
        return 'B';
    case ExchangeType.binance:
      return 'B';
    case ExchangeType.okx:
      return 'O';
    }
  }
}
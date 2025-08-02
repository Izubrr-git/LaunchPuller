class ExchangeException implements Exception {
  const ExchangeException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;
}

class NetworkException extends ExchangeException {
  const NetworkException(super.message, [super.statusCode]);
}

class ParseException extends ExchangeException {
  const ParseException(super.message);
}

class ApiException extends ExchangeException {
  const ApiException(super.message, [super.statusCode]);
}

class RateLimitException extends ExchangeException {
  const RateLimitException() : super('Превышен лимит запросов');
}
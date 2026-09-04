abstract class CustomException implements Exception {
  final dynamic errorMessage;
  const CustomException([this.errorMessage]);

  @override
  String toString() {
    return errorMessage != null ? "Exception: $errorMessage" : "Exception";
  }
}

class NetworkException extends CustomException {
  NetworkException([super.errorMessage]);
}

class TimeoutApiException extends CustomException {
  TimeoutApiException([super.errorMessage]);
}

/// Generic Server Exception (Non-HTTP)
/// Backend down, maintenance, unknown server failure
class ServerException extends CustomException {
  ServerException([super.errorMessage]);
}

class ParsingException extends CustomException {
  ParsingException([super.errorMessage]);
}

/// 3xx – Redirection
class RedirectionException extends CustomException {
  const RedirectionException( [super.errorMessage]);
}


/// 4xx – Client Error

class ClientErrorException extends CustomException {
  final int statusCode;
  const ClientErrorException(this.statusCode, [String? message]): super(message ?? "Client error ($statusCode)");
}


/// 5xx – Server Error
class ServerErrorException extends CustomException {
  const ServerErrorException([super.errorMessage]);
}

/// Anything unexpected
class UnknownException extends CustomException {
  const UnknownException([super.errorMessage]);
}
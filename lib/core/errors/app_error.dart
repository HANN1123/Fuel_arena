sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => code == null ? message : '$code: $message';
}

class AppError extends AppException {
  const AppError(super.message, {super.code, super.cause});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.cause});
}

class SupabaseRequestException extends AppException {
  const SupabaseRequestException(super.message, {super.code, super.cause});
}

class AdException extends AppException {
  const AdException(super.message, {super.code, super.cause});
}

class PurchaseException extends AppException {
  const PurchaseException(super.message, {super.code, super.cause});
}

class DriveTrackingException extends AppException {
  const DriveTrackingException(super.message, {super.code, super.cause});
}

class ErrorMapper {
  const ErrorMapper();

  String titleFor(Object error) {
    if (error is PermissionException) {
      return '권한이 필요해요';
    }
    if (error is AuthException) {
      return '다시 로그인해주세요';
    }
    if (error is NetworkException) {
      return '인터넷 연결이 불안정해요';
    }
    if (error is AdException) {
      return '광고를 불러올 수 없어요';
    }
    return '일시적인 문제가 발생했어요';
  }

  String messageFor(Object error) {
    if (error is AppException && error.message.isNotEmpty) {
      return error.message;
    }
    if (error is StateError) {
      final message = error.message.trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    if (error is UnsupportedError) {
      final message = (error.message ?? '').trim();
      if (message.isNotEmpty && message != 'null') {
        return message;
      }
    }
    if (error is NetworkException) {
      return '네트워크 연결을 확인하고 다시 시도해주세요.';
    }
    if (error is AdException) {
      return '기본 보상은 유지됩니다. 잠시 후 다시 시도해주세요.';
    }
    return '잠시 후 다시 시도해주세요.';
  }
}

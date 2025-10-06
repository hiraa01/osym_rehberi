/// Custom exceptions for ÖSYM Rehberi Flutter app

abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? data;
  
  const AppException(this.message, {this.code, this.data});
  
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.data});
}

class ApiException extends AppException {
  final int? statusCode;
  
  const ApiException(super.message, {super.code, this.statusCode, super.data});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.data});
}

class StudentNotFoundException extends AppException {
  const StudentNotFoundException(super.message, {super.code, super.data});
}

class RecommendationException extends AppException {
  const RecommendationException(super.message, {super.code, super.data});
}

class ScoreCalculationException extends AppException {
  const ScoreCalculationException(super.message, {super.code, super.data});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.data});
}

/// Exception handling utilities
class ExceptionHandler {
  static String getUserFriendlyMessage(AppException exception) {
    switch (exception.runtimeType) {
      case NetworkException:
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      case ApiException:
        final apiException = exception as ApiException;
        if (apiException.statusCode == 404) {
          return 'Aradığınız bilgi bulunamadı.';
        } else if (apiException.statusCode == 500) {
          return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
        }
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
      case ValidationException:
        return 'Lütfen giriş bilgilerinizi kontrol edin.';
      case StudentNotFoundException:
        return 'Öğrenci profili bulunamadı.';
      case RecommendationException:
        return 'Tercih önerileri oluşturulamadı. Lütfen tekrar deneyin.';
      case ScoreCalculationException:
        return 'Puan hesaplama sırasında bir hata oluştu.';
      case DatabaseException:
        return 'Veri işleme hatası. Lütfen tekrar deneyin.';
      default:
        return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
  
  static void logException(AppException exception, {String? context}) {
    // Log exception details for debugging
    // In production, this could be sent to crash reporting service
  }
}

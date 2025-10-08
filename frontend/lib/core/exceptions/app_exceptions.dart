/// Custom exceptions for ÖSYM Rehberi Flutter app
library;

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
    return switch (exception) {
      NetworkException _ =>
        'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      ApiException(statusCode: 404) =>
        'Aradığınız bilgi bulunamadı.',
      ApiException(statusCode: 500) =>
        'Sunucu hatası. Lütfen daha sonra tekrar deneyin.',
      ApiException _ =>
        'Bir hata oluştu. Lütfen tekrar deneyin.',
      ValidationException _ =>
        'Lütfen giriş bilgilerinizi kontrol edin.',
      StudentNotFoundException _ =>
        'Öğrenci profili bulunamadı.',
      RecommendationException _ =>
        'Tercih önerileri oluşturulamadı. Lütfen tekrar deneyin.',
      ScoreCalculationException _ =>
        'Puan hesaplama sırasında bir hata oluştu.',
      DatabaseException _ =>
        'Veri işleme hatası. Lütfen tekrar deneyin.',
      _ =>
        'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
    };
  }
  
  static void logException(AppException exception, {String? context}) {
    // Log exception details for debugging
    // In production, this could be sent to crash reporting service
  }
}

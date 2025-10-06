import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logging service for ÖSYM Rehberi
class AppLogger {
  static const String _tag = '[OSYM_REHBERI]';
  
  /// Log info messages
  static void info(String message, {String? module, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage(message, module, data);
    if (kDebugMode) {
      developer.log(logMessage, name: 'INFO');
    }
  }
  
  /// Log error messages
  static void error(String message, {String? module, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage(message, module, data);
    if (kDebugMode) {
      developer.log(
        logMessage,
        name: 'ERROR',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Log warning messages
  static void warning(String message, {String? module, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage(message, module, data);
    if (kDebugMode) {
      developer.log(logMessage, name: 'WARNING');
    }
  }
  
  /// Log debug messages
  static void debug(String message, {String? module, Map<String, dynamic>? data}) {
    final logMessage = _formatMessage(message, module, data);
    if (kDebugMode) {
      developer.log(logMessage, name: 'DEBUG');
    }
  }
  
  /// Format log message with context
  static String _formatMessage(String message, String? module, Map<String, dynamic>? data) {
    final buffer = StringBuffer();
    buffer.write('$_tag ');
    
    if (module != null) {
      buffer.write('[$module] ');
    }
    
    buffer.write(message);
    
    if (data != null && data.isNotEmpty) {
      buffer.write(' — ');
      buffer.write(data.entries.map((e) => '${e.key}=${e.value}').join(', '));
    }
    
    return buffer.toString();
  }
}

/// Module-specific loggers
class ApiLogger {
  static void request(String method, String url, {Map<String, dynamic>? data}) {
    AppLogger.info(
      'API Request: $method $url',
      module: 'API',
      data: data,
    );
  }
  
  static void response(String method, String url, int statusCode, {Map<String, dynamic>? data}) {
    AppLogger.info(
      'API Response: $method $url - $statusCode',
      module: 'API',
      data: data,
    );
  }
  
  static void error(String method, String url, Object error, {StackTrace? stackTrace}) {
    AppLogger.error(
      'API Error: $method $url',
      module: 'API',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class RecommendationLogger {
  static void generateRecommendations(int studentId, int limit) {
    AppLogger.info(
      'Generating recommendations',
      module: 'RECOMMENDER',
      data: {'student_id': studentId, 'limit': limit},
    );
  }
  
  static void recommendationGenerated(int studentId, int count) {
    AppLogger.info(
      'Recommendations generated successfully',
      module: 'RECOMMENDER',
      data: {'student_id': studentId, 'count': count},
    );
  }
  
  static void recommendationError(int studentId, Object error) {
    AppLogger.error(
      'Recommendation generation failed',
      module: 'RECOMMENDER',
      error: error,
      data: {'student_id': studentId},
    );
  }
}

class AuthLogger {
  static void loginAttempt(String email) {
    AppLogger.info(
      'Login attempt',
      module: 'AUTH',
      data: {'email': email},
    );
  }
  
  static void loginSuccess(String email) {
    AppLogger.info(
      'Login successful',
      module: 'AUTH',
      data: {'email': email},
    );
  }
  
  static void loginFailed(String email, String reason) {
    AppLogger.warning(
      'Login failed',
      module: 'AUTH',
      data: {'email': email, 'reason': reason},
    );
  }
}

class NetCalcLogger {
  static void scoreCalculation(int studentId, String fieldType) {
    AppLogger.info(
      'Starting score calculation',
      module: 'NET_CALC',
      data: {'student_id': studentId, 'field_type': fieldType},
    );
  }
  
  static void scoreCalculated(int studentId, double totalScore, int rank) {
    AppLogger.info(
      'Score calculation completed',
      module: 'NET_CALC',
      data: {'student_id': studentId, 'total_score': totalScore, 'rank': rank},
    );
  }
  
  static void scoreError(int studentId, Object error) {
    AppLogger.error(
      'Score calculation failed',
      module: 'NET_CALC',
      error: error,
      data: {'student_id': studentId},
    );
  }
}

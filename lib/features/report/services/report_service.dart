// lib/features/report/services/report_service.dart
import 'package:dio/dio.dart';
import 'package:onlyfeed_frontend/shared/services/dio_client.dart';
import 'package:onlyfeed_frontend/features/report/models/report_model.dart';

class ReportService {
  final Dio _dio = DioClient().dio;

  /// Créer un nouveau signalement
  Future<Report> createReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    required String description,
  }) async {
    try {
      final request = CreateReportRequest(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        description: description,
      );

      final response = await _dio.post(
        '/api/reports',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        return Report.fromJson(response.data['report']);
      } else {
        throw Exception('Erreur lors de la création du signalement');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('Vous avez déjà signalé cet élément');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Élément à signaler non trouvé');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Vous devez être connecté pour signaler');
      }
      throw Exception('Erreur lors du signalement: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors du signalement: $e');
    }
  }

  /// Récupérer les signalements (admin seulement)
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int limit = 20,
    ReportStatus? status,
    ReportTargetType? targetType,
    ReportReason? reason,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) {
        queryParams['status'] = Report._statusToString(status);
      }
      if (targetType != null) {
        queryParams['target_type'] = Report._targetTypeToString(targetType);
      }
      if (reason != null) {
        queryParams['reason'] = Report._reasonToString(reason);
      }

      final response = await _dio.get(
        '/api/admin/reports',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> reportsJson = response.data['reports'] ?? [];
        final reports = reportsJson
            .map((json) => ReportWithTarget.fromJson(json))
            .toList();

        return {
          'reports': reports,
          'pagination': response.data['pagination'] ?? {},
        };
      } else {
        throw Exception('Erreur lors de la récupération des signalements');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé - Droits administrateur requis');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Non authentifié');
      }
      throw Exception('Erreur lors de la récupération des signalements: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des signalements: $e');
    }
  }

  /// Mettre à jour un signalement (admin seulement)
  Future<Report> updateReport({
    required String reportId,
    required ReportStatus status,
    required String adminNote,
  }) async {
    try {
      final request = UpdateReportRequest(
        status: status,
        adminNote: adminNote,
      );

      final response = await _dio.put(
        '/api/admin/reports/$reportId',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Report.fromJson(response.data['report']);
      } else {
        throw Exception('Erreur lors de la mise à jour du signalement');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Signalement non trouvé');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé - Droits administrateur requis');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Non authentifié');
      }
      throw Exception('Erreur lors de la mise à jour: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  /// Supprimer un signalement (admin seulement)
  Future<void> deleteReport(String reportId) async {
    try {
      final response = await _dio.delete('/api/admin/reports/$reportId');

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la suppression du signalement');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Signalement non trouvé');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé - Droits administrateur requis');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Non authentifié');
      }
      throw Exception('Erreur lors de la suppression: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Récupérer les statistiques des signalements (admin seulement)
  Future<ReportStats> getReportStats() async {
    try {
      final response = await _dio.get('/api/admin/reports/stats');

      if (response.statusCode == 200) {
        return ReportStats.fromJson(response.data);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé - Droits administrateur requis');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Non authentifié');
      }
      throw Exception('Erreur lors de la récupération des statistiques: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
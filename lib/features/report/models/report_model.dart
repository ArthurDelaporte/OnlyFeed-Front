// lib/features/report/models/report_model.dart

enum ReportTargetType {
  post,
  user,
  comment,
}

enum ReportReason {
  inappropriateContent,
  spam,
  hateSpeech,
  impersonation,
  copyright,
  other,
}

enum ReportStatus {
  pending,
  reviewed,
  resolved,
  rejected,
}

class Report {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reporterId;
  final String? reporterUsername;
  final String? reporterAvatarUrl;
  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String description;
  final ReportStatus status;
  final String? adminId;
  final String? adminUsername;
  final String adminNote;
  final DateTime? resolvedAt;

  Report({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.reporterId,
    this.reporterUsername,
    this.reporterAvatarUrl,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
    required this.status,
    this.adminId,
    this.adminUsername,
    required this.adminNote,
    this.resolvedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      reporterId: json['reporter_id'] ?? '',
      reporterUsername: json['reporter']?['username'],
      reporterAvatarUrl: json['reporter']?['avatar_url'],
      targetType: _parseTargetType(json['target_type']),
      targetId: json['target_id'] ?? '',
      reason: _parseReason(json['reason']),
      description: json['description'] ?? '',
      status: _parseStatus(json['status']),
      adminId: json['admin_id'],
      adminUsername: json['admin']?['username'],
      adminNote: json['admin_note'] ?? '',
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reporter_id': reporterId,
      'target_type': _targetTypeToString(targetType),
      'target_id': targetId,
      'reason': _reasonToString(reason),
      'description': description,
      'status': _statusToString(status),
      'admin_id': adminId,
      'admin_note': adminNote,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  static ReportTargetType _parseTargetType(String? type) {
    switch (type) {
      case 'post': return ReportTargetType.post;
      case 'user': return ReportTargetType.user;
      case 'comment': return ReportTargetType.comment;
      default: return ReportTargetType.post;
    }
  }

  static ReportReason _parseReason(String? reason) {
    switch (reason) {
      case 'inappropriate_content': return ReportReason.inappropriateContent;
      case 'spam': return ReportReason.spam;
      case 'hate_speech': return ReportReason.hateSpeech;
      case 'impersonation': return ReportReason.impersonation;
      case 'copyright': return ReportReason.copyright;
      case 'other': return ReportReason.other;
      default: return ReportReason.other;
    }
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending': return ReportStatus.pending;
      case 'reviewed': return ReportStatus.reviewed;
      case 'resolved': return ReportStatus.resolved;
      case 'rejected': return ReportStatus.rejected;
      default: return ReportStatus.pending;
    }
  }

  static String _targetTypeToString(ReportTargetType type) {
    switch (type) {
      case ReportTargetType.post: return 'post';
      case ReportTargetType.user: return 'user';
      case ReportTargetType.comment: return 'comment';
    }
  }

  static String _reasonToString(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriateContent: return 'inappropriate_content';
      case ReportReason.spam: return 'spam';
      case ReportReason.hateSpeech: return 'hate_speech';
      case ReportReason.impersonation: return 'impersonation';
      case ReportReason.copyright: return 'copyright';
      case ReportReason.other: return 'other';
    }
  }

  static String _statusToString(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending: return 'pending';
      case ReportStatus.reviewed: return 'reviewed';
      case ReportStatus.resolved: return 'resolved';
      case ReportStatus.rejected: return 'rejected';
    }
  }
}

class ReportWithTarget extends Report {
  final Map<String, dynamic>? targetPost;
  final Map<String, dynamic>? targetUser;
  final Map<String, dynamic>? targetComment;

  ReportWithTarget({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String reporterId,
    String? reporterUsername,
    String? reporterAvatarUrl,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    required String description,
    required ReportStatus status,
    String? adminId,
    String? adminUsername,
    required String adminNote,
    DateTime? resolvedAt,
    this.targetPost,
    this.targetUser,
    this.targetComment,
  }) : super(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    reporterId: reporterId,
    reporterUsername: reporterUsername,
    reporterAvatarUrl: reporterAvatarUrl,
    targetType: targetType,
    targetId: targetId,
    reason: reason,
    description: description,
    status: status,
    adminId: adminId,
    adminUsername: adminUsername,
    adminNote: adminNote,
    resolvedAt: resolvedAt,
  );

  factory ReportWithTarget.fromJson(Map<String, dynamic> json) {
    final report = Report.fromJson(json);
    return ReportWithTarget(
      id: report.id,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
      reporterId: report.reporterId,
      reporterUsername: report.reporterUsername,
      reporterAvatarUrl: report.reporterAvatarUrl,
      targetType: report.targetType,
      targetId: report.targetId,
      reason: report.reason,
      description: report.description,
      status: report.status,
      adminId: report.adminId,
      adminUsername: report.adminUsername,
      adminNote: report.adminNote,
      resolvedAt: report.resolvedAt,
      targetPost: json['target_post'],
      targetUser: json['target_user'],
      targetComment: json['target_comment'],
    );
  }

  String? get targetTitle {
    switch (targetType) {
      case ReportTargetType.post:
        return targetPost?['title'] ?? targetPost?['Title'];
      case ReportTargetType.user:
        return targetUser?['username'];
      case ReportTargetType.comment:
        final content = targetComment?['content'] ?? targetComment?['text'] ?? '';
        return content.length > 50 ? '${content.substring(0, 50)}...' : content;
    }
  }
}

class CreateReportRequest {
  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String description;

  CreateReportRequest({
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'target_type': Report._targetTypeToString(targetType),
      'target_id': targetId,
      'reason': Report._reasonToString(reason),
      'description': description,
    };
  }
}

class UpdateReportRequest {
  final ReportStatus status;
  final String adminNote;

  UpdateReportRequest({
    required this.status,
    required this.adminNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': Report._statusToString(status),
      'admin_note': adminNote,
    };
  }
}

class ReportStats {
  final List<ReportStatusStat> statsByStatus;
  final List<ReportTypeStat> statsByType;
  final List<ReportReasonStat> statsByReason;
  final int recentCount;

  ReportStats({
    required this.statsByStatus,
    required this.statsByType,
    required this.statsByReason,
    required this.recentCount,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      statsByStatus: (json['stats_by_status'] as List? ?? [])
          .map((e) => ReportStatusStat.fromJson(e))
          .toList(),
      statsByType: (json['stats_by_type'] as List? ?? [])
          .map((e) => ReportTypeStat.fromJson(e))
          .toList(),
      statsByReason: (json['stats_by_reason'] as List? ?? [])
          .map((e) => ReportReasonStat.fromJson(e))
          .toList(),
      recentCount: json['recent_count'] ?? 0,
    );
  }
}

class ReportStatusStat {
  final ReportStatus status;
  final int count;

  ReportStatusStat({required this.status, required this.count});

  factory ReportStatusStat.fromJson(Map<String, dynamic> json) {
    return ReportStatusStat(
      status: Report._parseStatus(json['status']),
      count: json['count'] ?? 0,
    );
  }
}

class ReportTypeStat {
  final ReportTargetType targetType;
  final int count;

  ReportTypeStat({required this.targetType, required this.count});

  factory ReportTypeStat.fromJson(Map<String, dynamic> json) {
    return ReportTypeStat(
      targetType: Report._parseTargetType(json['target_type']),
      count: json['count'] ?? 0,
    );
  }
}

class ReportReasonStat {
  final ReportReason reason;
  final int count;

  ReportReasonStat({required this.reason, required this.count});

  factory ReportReasonStat.fromJson(Map<String, dynamic> json) {
    return ReportReasonStat(
      reason: Report._parseReason(json['reason']),
      count: json['count'] ?? 0,
    );
  }
}
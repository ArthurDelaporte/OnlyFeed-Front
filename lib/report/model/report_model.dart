class Report {
  final String id;
  final String targetId;
  final String type;
  final String reason;
  final DateTime date;

  Report({
    required this.id,
    required this.targetId,
    required this.type,
    required this.reason,
    required this.date,
  });
}
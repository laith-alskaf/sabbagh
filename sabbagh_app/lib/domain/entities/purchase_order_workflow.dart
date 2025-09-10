/// Workflow step entity for purchase order timeline
class PurchaseOrderWorkflowStep {
  final String action; // raw backend action
  final String step; // normalized step key (e.g., created, submitted, assistant_review)
  final String status; // approved | rejected | pending | routed | updated | created | completed
  final String? actorId;
  final String? actorName;
  final String? actorEmail;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const PurchaseOrderWorkflowStep({
    required this.action,
    required this.step,
    required this.status,
    required this.timestamp,
    this.actorId,
    this.actorName,
    this.actorEmail,
    this.details,
  });

  factory PurchaseOrderWorkflowStep.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    return PurchaseOrderWorkflowStep(
      action: json['action'] as String,
      step: json['step'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      actorId: actor is Map<String, dynamic> ? actor['id'] as String? : null,
      actorName: actor is Map<String, dynamic> ? actor['name'] as String? : null,
      actorEmail: actor is Map<String, dynamic> ? actor['email'] as String? : null,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }
}
class RoadDamageReport {
  final String? id;
  final String imagePath;
  final String description;
  final String location;
  final DateTime reportedAt;
  RoadDamageReport({
    this.id,
    required this.imagePath,
    required this.description,
    required this.location,
    DateTime? reportedAt,
  }) : reportedAt = reportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'description': description,
      'location': location,
      'reportedAt': reportedAt.toIso8601String(),
    };
  }

  factory RoadDamageReport.fromJson(Map<String, dynamic> json) {
    return RoadDamageReport(
      id: json['id'],
      imagePath: json['imagePath'],
      description: json['description'],
      location: json['location'],
      reportedAt: DateTime.parse(json['reportedAt']),
    );
  }
}

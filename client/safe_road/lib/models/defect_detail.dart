class DefectDetail {
  final double confidence;
  final String defectClass;
  final Map<String, double> boundingBox;

  DefectDetail({
    required this.confidence,
    required this.defectClass,
    required this.boundingBox,
  });

  factory DefectDetail.fromJson(Map<String, dynamic> json) {
    return DefectDetail(
      confidence: json['confidence'].toDouble(),
      defectClass: json['class'],
      boundingBox: {
        'x1': json['bounding_box']['x1'].toDouble(),
        'y1': json['bounding_box']['y1'].toDouble(),
        'x2': json['bounding_box']['x2'].toDouble(),
        'y2': json['bounding_box']['y2'].toDouble(),
      },
    );
  }
}
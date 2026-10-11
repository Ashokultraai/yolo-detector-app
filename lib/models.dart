// Data models mirroring the backend JSON.

class Detection {
  final String label;
  final double confidence;
  final List<double> box; // [x1, y1, x2, y2] in ORIGINAL image pixels
  final String sourceModel;

  Detection({
    required this.label,
    required this.confidence,
    required this.box,
    required this.sourceModel,
  });

  factory Detection.fromJson(Map<String, dynamic> j) => Detection(
        label: j['label'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        box: (j['box'] as List).map((e) => (e as num).toDouble()).toList(),
        sourceModel: (j['source_model'] ?? '') as String,
      );
}

class DetectResult {
  final List<Detection> detections;
  final Map<String, dynamic> perModel;
  final int imageWidth;
  final int imageHeight;

  DetectResult({
    required this.detections,
    required this.perModel,
    required this.imageWidth,
    required this.imageHeight,
  });

  factory DetectResult.fromJson(Map<String, dynamic> j) {
    final size = (j['image_size'] ?? {}) as Map<String, dynamic>;
    return DetectResult(
      detections: ((j['detections'] ?? []) as List)
          .map((e) => Detection.fromJson(e as Map<String, dynamic>))
          .toList(),
      perModel: (j['per_model'] ?? {}) as Map<String, dynamic>,
      imageWidth: (size['width'] ?? 1) as int,
      imageHeight: (size['height'] ?? 1) as int,
    );
  }

  /// Total backend latency summed across the models that actually ran.
  double get totalMs {
    double sum = 0;
    perModel.forEach((_, v) {
      final ms = (v as Map)['ms'];
      if (ms is num) sum += ms.toDouble();
    });
    return sum;
  }
}

/// A stable color per label (kept in sync with backend/labels.py).
const Map<String, int> kLabelColors = {
  'mobile': 0xFFFF6347,
  'fan': 0xFF1E90FF,
  'clock': 0xFF3CB371,
  'watch': 0xFFFFA500,
  'laptop': 0xFF9370DB,
};

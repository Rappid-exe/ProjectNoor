/// Status of the Gemma model
enum ModelStatus {
  notDownloaded,
  downloading,
  ready,
  error,
  initializing,
  initialized,
}

/// Information about the current model state
class ModelInfo {
  final ModelStatus status;
  final double? downloadProgress;
  final String? error;
  final int? modelSize;
  final String? modelPath;
  
  const ModelInfo({
    required this.status,
    this.downloadProgress,
    this.error,
    this.modelSize,
    this.modelPath,
  });

  /// Create a copy with modified values
  ModelInfo copyWith({
    ModelStatus? status,
    double? downloadProgress,
    String? error,
    int? modelSize,
    String? modelPath,
  }) {
    return ModelInfo(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
      modelSize: modelSize ?? this.modelSize,
      modelPath: modelPath ?? this.modelPath,
    );
  }

  @override
  String toString() {
    return 'ModelInfo(status: $status, downloadProgress: $downloadProgress, error: $error, modelSize: $modelSize, modelPath: $modelPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModelInfo &&
        other.status == status &&
        other.downloadProgress == downloadProgress &&
        other.error == error &&
        other.modelSize == modelSize &&
        other.modelPath == modelPath;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        downloadProgress.hashCode ^
        error.hashCode ^
        modelSize.hashCode ^
        modelPath.hashCode;
  }
}
/// Configuration for the Gemma model
class GemmaModelConfig {
  final String modelType;
  final String backend;
  final int maxTokens;
  final bool supportImage;
  final int maxNumImages;
  final List<dynamic>? tools;
  
  const GemmaModelConfig({
    this.modelType = 'gemmaIt',
    this.backend = 'gpu',
    this.maxTokens = 4096,
    this.supportImage = false,
    this.maxNumImages = 1,
    this.tools,
  });

  /// Create a copy with modified values
  GemmaModelConfig copyWith({
    String? modelType,
    String? backend,
    int? maxTokens,
    bool? supportImage,
    int? maxNumImages,
    List<dynamic>? tools,
  }) {
    return GemmaModelConfig(
      modelType: modelType ?? this.modelType,
      backend: backend ?? this.backend,
      maxTokens: maxTokens ?? this.maxTokens,
      supportImage: supportImage ?? this.supportImage,
      maxNumImages: maxNumImages ?? this.maxNumImages,
      tools: tools ?? this.tools,
    );
  }

  @override
  String toString() {
    return 'GemmaModelConfig(modelType: $modelType, backend: $backend, maxTokens: $maxTokens, supportImage: $supportImage, maxNumImages: $maxNumImages, tools: ${tools?.length ?? 0})';
  }
}

/// Configuration for Gemma chat sessions
class GemmaChatConfig {
  final double temperature;
  final int randomSeed;
  final int topK;
  final bool supportImage;
  final List<dynamic>? tools;
  final bool supportsFunctionCalls;
  
  const GemmaChatConfig({
    this.temperature = 0.8,
    this.randomSeed = 1,
    this.topK = 1,
    this.supportImage = false,
    this.tools,
    this.supportsFunctionCalls = false,
  });

  /// Create a copy with modified values
  GemmaChatConfig copyWith({
    double? temperature,
    int? randomSeed,
    int? topK,
    bool? supportImage,
    List<dynamic>? tools,
    bool? supportsFunctionCalls,
  }) {
    return GemmaChatConfig(
      temperature: temperature ?? this.temperature,
      randomSeed: randomSeed ?? this.randomSeed,
      topK: topK ?? this.topK,
      supportImage: supportImage ?? this.supportImage,
      tools: tools ?? this.tools,
      supportsFunctionCalls: supportsFunctionCalls ?? this.supportsFunctionCalls,
    );
  }

  @override
  String toString() {
    return 'GemmaChatConfig(temperature: $temperature, randomSeed: $randomSeed, topK: $topK, supportImage: $supportImage, supportsFunctionCalls: $supportsFunctionCalls, tools: ${tools?.length ?? 0})';
  }
}
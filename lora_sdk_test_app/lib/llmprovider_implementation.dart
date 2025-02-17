import 'package:lora_sdk/lora_sdk.dart' as sdk;
import 'package:fllama/fllama.dart';

class FllamaWrapper implements sdk.LLMInterface<sdk.OpenAiRequest> {
  OpenAiRequest _convertRequest(
    int maxTokens,
    List<sdk.Message> messages,
    int numGpuLayers,
    String modelPath,
    double frequencyPenalty,
    double presencePenalty,
    double topP,
    int contextSize,
    double temperature,
    Function(String)? logger,
  ) {
    return OpenAiRequest(
      maxTokens: maxTokens,
      messages:
          messages.map((m) => Message(_convertRole(m.role), m.text)).toList(),
      numGpuLayers: numGpuLayers,
      modelPath: modelPath,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      topP: topP,
      contextSize: contextSize,
      temperature: temperature,
      logger: logger,
    );
  }

  Role _convertRole(sdk.Role role) {
    switch (role) {
      case sdk.Role.assistant:
        return Role.assistant;
      case sdk.Role.system:
        return Role.system;
      case sdk.Role.user:
        return Role.user;
    }
  }

  @override
  Future<int> chat(
      sdk.OpenAiRequest request, Function(String, bool) onResponse) {
    final fllamaRequest = _convertRequest(
      request.maxTokens,
      request.messages,
      request.numGpuLayers,
      request.modelPath,
      request.frequencyPenalty,
      request.presencePenalty,
      request.topP,
      request.contextSize,
      request.temperature,
      request.logger,
    );
    return fllamaChat(fllamaRequest, onResponse);
  }

  @override
  Future<int> chatMlcWeb(sdk.OpenAiRequest request,
      Function(double, double) onProgress, Function(String, bool) onResponse) {
    final fllamaRequest = _convertRequest(
      request.maxTokens,
      request.messages,
      request.numGpuLayers,
      request.modelPath,
      request.frequencyPenalty,
      request.presencePenalty,
      request.topP,
      request.contextSize,
      request.temperature,
      request.logger,
    );
    return fllamaChatMlcWeb(fllamaRequest, onProgress, onResponse);
  }

  @override
  void cancelInference(int requestId) {
    fllamaCancelInference(requestId);
  }
}

import 'package:flutter/material.dart';
import 'package:lora_sdk/lora_sdk.dart';
import 'llmprovider_implementation.dart';

void main() => runApp(const MaterialApp(home: SdkTestPage()));

class SdkTestPage extends StatefulWidget {
  const SdkTestPage({super.key});

  @override
  State<SdkTestPage> createState() => _SdkTestPageState();
}

class _SdkTestPageState extends State<SdkTestPage> {
  LoraSdk? _sdk;
  String _streamResponse = '';
  String _blockResponse = '';
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    try {
      final myLlmProvider = FllamaWrapper();
      final sdk = await LoraSdk.initialize(
        licenseKey: 'your-license-key',
        llmProvider: myLlmProvider,
      );

      // 초기화 후 상태 확인
      if (sdk.loraState.value.modelStatus == ModelStatus.error) {
        _showError(
            sdk.loraState.value.errorMessage ?? 'SDK initialization failed');
        return;
      }

      setState(() => _sdk = sdk);
    } catch (e) {
      _showError('Initialization failed: $e');
    }
  }

  Future<void> _downloadModel() async {
    if (_sdk == null) return;
    try {
      await _sdk!.downloadModel(
        onProgress: (_) {},
        onError: _showError,
      );
    } catch (e) {
      _showError('Download failed: $e');
    }
  }

  Future<void> _warmup() async {
    if (_sdk == null) return;
    try {
      await _sdk!.warmup(
        onProgress: (_) {},
        onError: _showError,
      );
    } catch (e) {
      _showError('Warmup failed: $e');
    }
  }

  Future<void> _generateStreamResponse() async {
    if (_sdk == null || _inputController.text.isEmpty) return;

    setState(() => _streamResponse = '');
    try {
      await for (final chunk
          in _sdk!.generateStreamResponse(_inputController.text)) {
        setState(() => _streamResponse += chunk);
      }
    } catch (e) {
      _showError('Stream generation failed: $e');
    }
  }

  Future<void> _generateBlockResponse() async {
    if (_sdk == null || _inputController.text.isEmpty) return;

    setState(() => _blockResponse = '');
    try {
      final response = await _sdk!.generateResponse(_inputController.text);
      setState(() => _blockResponse = response);
    } catch (e) {
      _showError('Block generation failed: $e');
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    if (_sdk == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lora SDK Test')),
        body: Center(
          child: Text(
            'SDK initialization failed. Please enter a valid license key. You can get a license key from our website. Please refer to the README for more details.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lora SDK Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<LoraState>(
              valueListenable: _sdk!.loraState,
              builder: (context, state, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Status: ${_getStatusMessage(state)}'),
                    if (state.downloadProgress != null ||
                        state.warmupProgress != null)
                      LinearProgressIndicator(
                        value: state.downloadProgress ?? state.warmupProgress,
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          (state.modelStatus != ModelStatus.downloading &&
                                  !state.isModelDownloaded &&
                                  state.isInitialized)
                              ? _downloadModel
                              : null,
                      child: const Text('Download Model'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: state.modelStatus != ModelStatus.warming &&
                              state.isModelDownloaded &&
                              !state.isWarmedUp
                          ? _warmup
                          : null,
                      child: const Text('Start Warmup'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Input Text',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state.isWarmedUp
                                ? _generateStreamResponse
                                : null,
                            child: const Text('Generate Stream Response'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state.isWarmedUp
                                ? _generateBlockResponse
                                : null,
                            child: const Text('Generate Block Response'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.blue,
                      tabs: [
                        Tab(text: 'Stream Response'),
                        Tab(text: 'Block Response'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_streamResponse),
                            ),
                          ),
                          SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(_blockResponse),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(LoraState state) {
    switch (state.modelStatus) {
      case ModelStatus.notInitialized:
        return 'SDK initialization required';
      case ModelStatus.initializing:
        return 'Initializing SDK...';
      case ModelStatus.initialized:
        return 'SDK initialized. Model download required';
      case ModelStatus.downloading:
        return 'Downloading model... ${(state.downloadProgress! * 100).toInt()}%';
      case ModelStatus.downloaded:
        return 'Model downloaded. Warmup required';
      case ModelStatus.warming:
        return 'Warming up... ${(state.warmupProgress! * 100).toInt()}%';
      case ModelStatus.ready:
        return 'Ready';
      case ModelStatus.error:
        return 'Error: ${state.errorMessage}';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}

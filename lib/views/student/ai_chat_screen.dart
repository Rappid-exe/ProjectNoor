import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noor/views/setup/model_setup_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  static const platform = MethodChannel('com.example.noor/gemini');
  bool _isLoading = false;
  bool _isModelReady = false;
  String _modelStatus = 'Initializing AI model...';

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    try {
      final bool isReady = await platform.invokeMethod('isModelReady');
      if (!mounted) return;
      
      setState(() {
        _isModelReady = isReady;
        _modelStatus = isReady ? 'AI model ready' : 'Model loading...';
      });
      
      // If not ready, check again in 2 seconds
      if (!isReady && mounted) {
        Future.delayed(const Duration(seconds: 2), _checkModelStatus);
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _modelStatus = 'Model initialization failed: ${e.toString()}';
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _textController.clear();

    try {
      final String response = await platform.invokeMethod('generateText', {'prompt': text});
      setState(() {
        _messages.add({'role': 'model', 'text': response});
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _messages.add({'role': 'model', 'text': "Error: ${e.message}"});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            height: 4.0,
            color: _isModelReady ? Colors.green : Colors.orange,
          ),
        ),
      ),
      body: Column(
        children: [
          // Model status indicator
          if (!_isModelReady)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _modelStatus,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isModelReady ? Icons.chat_bubble_outline : Icons.smart_toy_outlined,
                          size: 64,
                          color: _isModelReady ? Colors.grey.shade400 : Colors.orange.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isModelReady ? 'Welcome to your AI Tutor!' : 'AI Model Setup Required',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isModelReady 
                              ? 'Ask me anything about your studies'
                              : 'Set up the AI model to start learning',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (!_isModelReady) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: const Text('Setup AI Model'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ModelSetupScreen(),
                                ),
                              ).then((_) => _checkModelStatus());
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24, 
                                vertical: 12
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: isUser ? Theme.of(context).primaryColor : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            message['text']!,
                            style: TextStyle(color: isUser ? Colors.white : Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
            
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: _isModelReady && !_isLoading,
                    decoration: InputDecoration(
                      hintText: _isModelReady 
                          ? 'Ask a question...' 
                          : 'Waiting for AI model...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, 
                        vertical: 10
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: (_isModelReady && !_isLoading) 
                      ? () => _sendMessage(_textController.text)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
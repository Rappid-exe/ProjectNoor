import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/chat_message.dart';
import '../../services/gemma_native_service.dart';

class GemmaChatPage extends StatefulWidget {
  const GemmaChatPage({Key? key}) : super(key: key);

  @override
  State<GemmaChatPage> createState() => _GemmaChatPageState();
}

class _GemmaChatPageState extends State<GemmaChatPage> {
  final GemmaNativeService _gemmaService = GemmaNativeService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isModelLoaded = false;
  bool _isLoading = true;
  bool _isGenerating = false;
  String _currentStreamingMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _gemmaService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    try {
      final success = await _gemmaService.initializeModel();
      if (mounted) {
        setState(() {
          _isModelLoaded = success;
          _isLoading = false;
        });

        if (!success) {
          _showErrorSnackBar('Failed to load model. Please check your setup.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error initializing model: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty || !_isModelLoaded || _isGenerating) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      // Add placeholder for AI response
      setState(() {
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      // Use streaming for better UX
      final stream = _gemmaService.generateTextStream(text);

      String fullResponse = '';
      await for (final chunk in stream) {
        if (mounted) {
          // Replace the last message with updated content
          // Don't append to existing content to avoid duplicates
          fullResponse = chunk; // Use assignment, not +=

          setState(() {
            _messages.last = ChatMessage(
              text: fullResponse,
              isUser: false,
              timestamp: _messages.last.timestamp,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.last = ChatMessage(
            text: 'Error generating response: $e',
            isUser: false,
            timestamp: _messages.last.timestamp,
            isError: true,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gemma Chat'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeModel,
            tooltip: 'Reload Model',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          _buildStatusBar(),

          // Chat Messages
          Expanded(
            child: _buildMessageList(),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    if (!_isLoading && _isModelLoaded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: _isLoading ? Colors.blue.shade100 : Colors.orange.shade100,
      child: Row(
        children: [
          if (_isLoading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ],
          Icon(
            _isLoading ? Icons.downloading : Icons.warning_amber_rounded,
            size: 16,
            color: _isLoading ? Colors.blue.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isLoading
                  ? 'Loading Gemma model...'
                  : 'Model not loaded. Tap refresh to retry.',
              style: TextStyle(
                fontSize: 14,
                color: _isLoading ? Colors.blue.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation with Gemma',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Running locally on your device',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _MessageBubble(
          message: message,
          isGenerating: _isGenerating && index == _messages.length - 1 && !message.isUser,
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: _isModelLoaded && !_isGenerating,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _handleSubmit,
                  decoration: InputDecoration(
                    hintText: _isModelLoaded
                        ? 'Type your message...'
                        : 'Waiting for model to load...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isGenerating ? Icons.stop : Icons.send,
                    color: Colors.white,
                  ),
                  onPressed: !_isModelLoaded || (_isGenerating && false)
                      ? null
                      : () => _handleSubmit(_textController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isGenerating;

  const _MessageBubble({
    Key? key,
    required this.message,
    this.isGenerating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).primaryColor
                    : message.isError
                    ? Colors.red.shade100
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text.isEmpty && isGenerating
                        ? '...'
                        : message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : message.isError
                          ? Colors.red.shade700
                          : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  if (isGenerating && message.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


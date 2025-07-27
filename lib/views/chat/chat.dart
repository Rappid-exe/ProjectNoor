import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../models/gemma_message.dart';
import '../../models/gemma_status.dart';
import '../../models/gemma_exceptions.dart';
import '../../models/gemma_config.dart';
import '../../services/flutter_gemma_service.dart';
import '../../services/gemma_chat.dart';

class GemmaChatPage extends StatefulWidget {
  const GemmaChatPage({Key? key}) : super(key: key);

  @override
  State<GemmaChatPage> createState() => _GemmaChatPageState();
}

class _GemmaChatPageState extends State<GemmaChatPage> {
  final FlutterGemmaService _gemmaService = FlutterGemmaService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<GemmaMessage> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();

  GemmaChat? _gemmaChat;
  ModelInfo _modelInfo = const ModelInfo(status: ModelStatus.notDownloaded);
  bool _isGenerating = false;
  String? _lastError;
  bool _showImagePicker = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _listenToModelStatus();
  }

  @override
  void dispose() {
    _gemmaChat?.close();
    _gemmaService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Listen to model status changes
  void _listenToModelStatus() {
    _gemmaService.statusStream.listen((modelInfo) {
      if (mounted) {
        setState(() {
          _modelInfo = modelInfo;
          if (modelInfo.status == ModelStatus.error) {
            _lastError = modelInfo.error;
          }
        });
      }
    });
  }

  Future<void> _initializeModel() async {
    try {
      // Initialize the FlutterGemmaService
      final success = await _gemmaService.initialize();
      
      if (success) {
        // Create a chat session with multimodal support
        _gemmaChat = await GemmaChat.create(
          config: const GemmaChatConfig(supportImage: true),
        );
      }
      
      if (!success && mounted) {
        _showErrorSnackBar('Failed to load model. Please check your setup.');
      }
    } catch (e) {
      if (mounted) {
        _lastError = e.toString();
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
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _retryLastAction,
        ),
      ),
    );
  }



  void _retryLastAction() {
    if (_modelInfo.status == ModelStatus.error) {
      _initializeModel();
    }
  }

  /// Handle image selection from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        _showImagePreview(bytes);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  /// Show image preview dialog before sending
  void _showImagePreview(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.memory(imageBytes),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Add a message with your image...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleImageSubmit(_textController.text, imageBytes);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty || !_isModelReady || _isGenerating || _gemmaChat == null) return;

    _textController.clear();

    setState(() {
      _messages.add(TextMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isGenerating = true;
    });

    _scrollToBottom();
    await _processTextMessage(text);
  }

  Future<void> _handleImageSubmit(String text, Uint8List imageBytes) async {
    if (!_isModelReady || _isGenerating || _gemmaChat == null) return;

    setState(() {
      _messages.add(ImageMessage(
        text: text.isEmpty ? 'Image' : text,
        imageBytes: imageBytes,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isGenerating = true;
    });

    _scrollToBottom();
    await _processImageMessage(text, imageBytes);
  }

  Future<void> _processTextMessage(String text) async {
    try {
      // Add placeholder for AI response
      setState(() {
        _messages.add(TextMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      // Use streaming for better UX
      final stream = _gemmaChat!.sendMessageStream(text);

      String fullResponse = '';
      await for (final chunk in stream) {
        if (mounted) {
          fullResponse += chunk;
          setState(() {
            _messages.last = TextMessage(
              text: fullResponse,
              isUser: false,
              timestamp: _messages.last.timestamp,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      await _handleMessageError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _processImageMessage(String text, Uint8List imageBytes) async {
    try {
      // Add placeholder for AI response
      setState(() {
        _messages.add(TextMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      // Use streaming for multimodal response
      final stream = _gemmaChat!.sendImageMessageStream(text, imageBytes);

      String fullResponse = '';
      await for (final chunk in stream) {
        if (mounted) {
          fullResponse += chunk;
          setState(() {
            _messages.last = TextMessage(
              text: fullResponse,
              isUser: false,
              timestamp: _messages.last.timestamp,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      await _handleMessageError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _handleMessageError(dynamic error) async {
    if (!mounted) return;

    String errorMessage = 'Error generating response';
    bool canRetry = true;

    if (error is GemmaException) {
      switch (error.type) {
        case GemmaErrorType.modelNotFound:
          errorMessage = 'Model not found. Please download the model.';
          canRetry = false;
          break;
        case GemmaErrorType.memoryError:
          errorMessage = 'Memory error. Try a shorter message.';
          break;
        case GemmaErrorType.inferenceError:
          errorMessage = 'Inference failed. Please try again.';
          break;
        case GemmaErrorType.networkError:
          errorMessage = 'Network error during model download.';
          break;
        default:
          errorMessage = error.message;
      }
    } else {
      errorMessage = 'Unexpected error: $error';
    }

    setState(() {
      _messages.last = TextMessage(
        text: errorMessage,
        isUser: false,
        timestamp: _messages.last.timestamp,
      );
      _lastError = errorMessage;
    });

    if (canRetry) {
      _showErrorSnackBar(errorMessage);
    }
  }

  bool get _isModelReady => _modelInfo.status == ModelStatus.initialized;

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
            onPressed: _modelInfo.status == ModelStatus.initializing ? null : _initializeModel,
            tooltip: 'Reload Model',
          ),
          if (_isModelReady)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearChat,
              tooltip: 'Clear Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Status Bar
          _buildEnhancedStatusBar(),

          // Chat Messages
          Expanded(
            child: _buildMessageList(),
          ),

          // Enhanced Input Area
          _buildEnhancedInputArea(),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _gemmaChat?.clearContext();
  }

  Widget _buildEnhancedStatusBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _shouldShowStatusBar ? null : 0,
      child: _shouldShowStatusBar ? Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _getStatusColor(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusMessage(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getStatusTextColor(),
                    ),
                  ),
                  if (_getStatusSubMessage() != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getStatusSubMessage()!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusTextColor().withOpacity(0.8),
                      ),
                    ),
                  ],
                  if (_modelInfo.downloadProgress != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _modelInfo.downloadProgress! / 100,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusTextColor(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_modelInfo.status == ModelStatus.error)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _retryLastAction,
                color: _getStatusTextColor(),
                tooltip: 'Retry',
              ),
          ],
        ),
      ) : const SizedBox.shrink(),
    );
  }

  bool get _shouldShowStatusBar {
    return _modelInfo.status != ModelStatus.initialized || _isGenerating;
  }

  Widget _buildStatusIcon() {
    switch (_modelInfo.status) {
      case ModelStatus.notDownloaded:
        return Icon(Icons.download, size: 20, color: _getStatusTextColor());
      case ModelStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusTextColor()),
          ),
        );
      case ModelStatus.initializing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusTextColor()),
          ),
        );
      case ModelStatus.ready:
        return Icon(Icons.check_circle, size: 20, color: _getStatusTextColor());
      case ModelStatus.initialized:
        if (_isGenerating) {
          return SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusTextColor()),
            ),
          );
        }
        return Icon(Icons.smart_toy, size: 20, color: _getStatusTextColor());
      case ModelStatus.error:
        return Icon(Icons.error, size: 20, color: _getStatusTextColor());
    }
  }

  Color _getStatusColor() {
    switch (_modelInfo.status) {
      case ModelStatus.notDownloaded:
        return Colors.orange.shade100;
      case ModelStatus.downloading:
        return Colors.blue.shade100;
      case ModelStatus.initializing:
        return Colors.blue.shade100;
      case ModelStatus.ready:
        return Colors.green.shade100;
      case ModelStatus.initialized:
        return _isGenerating ? Colors.blue.shade100 : Colors.green.shade100;
      case ModelStatus.error:
        return Colors.red.shade100;
    }
  }

  Color _getStatusTextColor() {
    switch (_modelInfo.status) {
      case ModelStatus.notDownloaded:
        return Colors.orange.shade800;
      case ModelStatus.downloading:
        return Colors.blue.shade800;
      case ModelStatus.initializing:
        return Colors.blue.shade800;
      case ModelStatus.ready:
        return Colors.green.shade800;
      case ModelStatus.initialized:
        return _isGenerating ? Colors.blue.shade800 : Colors.green.shade800;
      case ModelStatus.error:
        return Colors.red.shade800;
    }
  }

  String _getStatusMessage() {
    switch (_modelInfo.status) {
      case ModelStatus.notDownloaded:
        return 'Model not downloaded';
      case ModelStatus.downloading:
        return 'Downloading model...';
      case ModelStatus.initializing:
        return 'Initializing model...';
      case ModelStatus.ready:
        return 'Model ready';
      case ModelStatus.initialized:
        return _isGenerating ? 'AI is thinking...' : 'AI ready';
      case ModelStatus.error:
        return 'Error occurred';
    }
  }

  String? _getStatusSubMessage() {
    switch (_modelInfo.status) {
      case ModelStatus.downloading:
        if (_modelInfo.downloadProgress != null) {
          return '${_modelInfo.downloadProgress!.toStringAsFixed(1)}% complete';
        }
        return 'Please wait...';
      case ModelStatus.error:
        return _modelInfo.error ?? _lastError ?? 'Unknown error';
      case ModelStatus.initialized:
        if (_isGenerating) {
          return 'Generating response...';
        }
        return null;
      default:
        return null;
    }
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

  Widget _buildEnhancedInputArea() {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image picker options
              if (_showImagePicker)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImagePickerButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        onPressed: () {
                          setState(() => _showImagePicker = false);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildImagePickerButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        onPressed: () {
                          setState(() => _showImagePicker = false);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              
              // Main input row
              Row(
                children: [
                  // Image picker toggle
                  if (_isModelReady)
                    IconButton(
                      icon: Icon(
                        _showImagePicker ? Icons.close : Icons.image,
                        color: _showImagePicker 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.shade600,
                      ),
                      onPressed: _isGenerating 
                          ? null 
                          : () => setState(() => _showImagePicker = !_showImagePicker),
                      tooltip: _showImagePicker ? 'Close' : 'Add Image',
                    ),
                  
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: _isModelReady && !_isGenerating,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSubmit,
                      decoration: InputDecoration(
                        hintText: _getInputHintText(),
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
                  
                  // Send button
                  Container(
                    decoration: BoxDecoration(
                      color: _isModelReady && !_isGenerating
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isGenerating ? Icons.stop : Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: _isModelReady && !_isGenerating
                          ? () => _handleSubmit(_textController.text)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInputHintText() {
    switch (_modelInfo.status) {
      case ModelStatus.notDownloaded:
        return 'Model not downloaded...';
      case ModelStatus.downloading:
        return 'Downloading model...';
      case ModelStatus.initializing:
        return 'Initializing model...';
      case ModelStatus.ready:
      case ModelStatus.initialized:
        return _isGenerating 
            ? 'AI is responding...' 
            : 'Type your message...';
      case ModelStatus.error:
        return 'Error - tap refresh to retry...';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final GemmaMessage message;
  final bool isGenerating;

  const _MessageBubble({
    Key? key,
    required this.message,
    this.isGenerating = false,
  }) : super(key: key);

  /// Check if message represents an error
  bool _isErrorMessage(GemmaMessage message) {
    return message.text.startsWith('Error') || message.text.contains('error') || message.text.contains('failed');
  }

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
            _buildAvatar(context, isUser),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getBubbleColor(context, isUser),
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
              child: _buildMessageContent(context),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    if (isUser) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        child: Icon(
          Icons.person,
          size: 18,
          color: Colors.grey.shade700,
        ),
      );
    }

    // AI avatar with different icons based on message type
    IconData icon = Icons.auto_awesome;
    if (message is FunctionCallMessage) {
      icon = Icons.functions;
    } else if (message is ImageMessage) {
      icon = Icons.image;
    } else if (_isErrorMessage(message)) {
      icon = Icons.error_outline;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: _isErrorMessage(message) 
          ? Colors.red.shade600 
          : Theme.of(context).primaryColor,
      child: Icon(
        icon,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Color _getBubbleColor(BuildContext context, bool isUser) {
    if (isUser) {
      return Theme.of(context).primaryColor;
    }
    
    if (_isErrorMessage(message)) {
      return Colors.red.shade100;
    }
    
    if (message is FunctionCallMessage) {
      return Colors.blue.shade50;
    }
    
    return Colors.white;
  }

  Widget _buildMessageContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message type indicator for special messages
        if (message is FunctionCallMessage && !message.isUser)
          _buildFunctionCallHeader(),
        
        // Image content for image messages
        if (message is ImageMessage)
          _buildImageContent(),
        
        // Text content
        _buildTextContent(context),
        
        // Function call details for function messages
        if (message is FunctionCallMessage && !message.isUser)
          _buildFunctionCallDetails(),
        
        // Generation indicator
        if (isGenerating && message.text.isNotEmpty)
          _buildGeneratingIndicator(context),
        
        // Timestamp
        _buildTimestamp(),
      ],
    );
  }

  Widget _buildFunctionCallHeader() {
    final funcMessage = message as FunctionCallMessage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.functions, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            'Function: ${funcMessage.functionName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    final imageMessage = message as ImageMessage;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageMessage.imageBytes,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    final textColor = message.isUser
        ? Colors.white
        : _isErrorMessage(message)
        ? Colors.red.shade700
        : Colors.black87;

    return Text(
      message.text.isEmpty && isGenerating ? '...' : message.text,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
      ),
    );
  }

  Widget _buildFunctionCallDetails() {
    final funcMessage = message as FunctionCallMessage;
    if (funcMessage.arguments.isEmpty && funcMessage.response == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (funcMessage.arguments.isNotEmpty) ...[
            Text(
              'Arguments:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              funcMessage.arguments.toString(),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (funcMessage.response != null) ...[
            if (funcMessage.arguments.isNotEmpty) const SizedBox(height: 8),
            Text(
              'Result:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              funcMessage.response.toString(),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGeneratingIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Generating...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTimestamp(message.timestamp),
        style: TextStyle(
          fontSize: 10,
          color: message.isUser 
              ? Colors.white.withOpacity(0.7)
              : Colors.grey.shade500,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}


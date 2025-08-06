# Project Noor 🌟

**Educational Platform for Student In Low connectivity Areas with On-Device AI Integration**

## 🎯 Project Overview

Project Noor is a Flutter-based educational platform designed to empower Afghan women through accessible learning tools. The app features on-device AI capabilities powered by Google's Gemma models, ensuring privacy, offline functionality, and zero server costs.

## 🤖 AI Integration Achievement

**✅ Successfully Integrated Gemma 3N Model**
- **On-device inference** with GPU acceleration
- **Real-time chat capabilities** with conversational context
- **Offline functionality** - no internet required after model download
- **Privacy-first approach** - all processing happens locally

## 🛠️ Technical Stack

- **Framework**: Flutter (Cross-platform mobile development)
- **AI Engine**: `flutter_gemma` package with Google AI Edge
- **Model**: Gemma 3N 2B IT (Instruction-Tuned) with int4 quantization
- **Backend**: GPU acceleration with OpenCL/ML_DRIFT_CL delegate
- **Platforms**: Android (Primary), iOS, Web support

## 🚀 Key Features

### Current Implementation (Gemma 3N)
- ✅ **Text-based AI chat** with natural conversation flow
- ✅ **GPU-optimized inference** for fast response times
- ✅ **Automatic chat session management** with context preservation
- ✅ **Self-healing service** that handles app lifecycle changes
- ✅ **Memory-efficient architecture** with on-demand chat creation

### Planned Upgrade (Gemma 3n)
- 🎯 **Multimodal capabilities** (text + images + audio + video)
- 🎯 **Enhanced educational features** for visual learning
- 🎯 **Function calling support** for interactive learning tools
- 🎯 **Larger context window** (32K tokens) for complex educational content

## 🏗️ Architecture

### AI Service Layer
```
GemmaAiService (Singleton)
├── ModelAssetManager (File management)
├── Direct File Path Loading (Performance optimized)
├── On-demand Chat Creation (Memory efficient)
└── GPU Backend (Hardware accelerated)
```

### Key Components
- **`GemmaAiService`**: Core AI service with singleton pattern
- **`ModelAssetManager`**: Handles model file copying and path management
- **`SimpleChatScreen`**: Main chat interface with real-time messaging
- **Direct File Path Approach**: Bypasses asset bundle for better performance

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (latest stable)
- Android device with GPU/OpenCL support
- Minimum 4GB RAM (8GB+ recommended for Gemma 3n)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Rappid-exe/ProjectNoor.git
   cd ProjectNoor/Noor
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Place the AI model in the assets folder:
   ```
   Noor/assets/gemma3-1b-it-int4.task
   ```

4. Run on a real Android device:
   ```bash
   flutter run -d [DEVICE_ID]
   ```

**Note**: GPU-optimized models require real Android devices. Emulators will not work.

## 🧪 Testing

### Successful Test Cases
- ✅ Model initialization on real Android device
- ✅ Chat session creation and management
- ✅ Real-time text generation with GPU acceleration
- ✅ App backgrounding/foregrounding with state recovery
- ✅ Memory management with large model files
- ✅ Conversation context preservation

### Device Requirements
- **Android**: API level 21+ with OpenCL support
- **RAM**: 4GB minimum, 8GB+ recommended
- **Storage**: 2GB+ free space for model caching
- **GPU**: Adreno, Mali, or PowerVR with OpenCL 1.2+

## 🏆 Google Gemma 3n Impact Challenge

This project is being developed for the **Google Gemma 3n Impact Challenge**, focusing on:

- **Educational Impact**: Empowering Afghan women through accessible AI-powered learning
- **On-device Innovation**: Leveraging Gemma 3n's multimodal capabilities
- **Privacy & Accessibility**: Offline-first approach for regions with limited connectivity
- **Real-world Application**: Practical solutions for educational challenges

## 📈 Performance Metrics

### Current Performance (Gemma 3N)
- **Initialization Time**: ~5-10 seconds on mid-range devices
- **Response Time**: 1-3 seconds for typical queries
- **Memory Usage**: ~2-3GB during active inference
- **Model Size**: ~1GB (int4 quantized)

### Target Performance (Gemma 3n upgrade)
- **Model Size**: ~3.1GB (E2B variant)
- **Multimodal Support**: Images, audio, video processing
- **Enhanced Context**: 32K token context window
- **Function Calling**: Interactive educational tools

## 🔒 Privacy & Security

- **100% On-device Processing**: No data sent to external servers
- **Local Model Storage**: Models cached securely on device
- **No Network Dependencies**: Works completely offline after setup
- **User Data Protection**: All conversations remain private

## 📁 Project Structure

```
ProjectNoor/
├── Noor/                          # Main Flutter application
│   ├── lib/
│   │   ├── services/
│   │   │   ├── gemma_ai_service.dart      # Core AI service
│   │   │   └── model_asset_manager.dart   # Model file management
│   │   ├── views/
│   │   │   └── student/
│   │   │       └── simple_chat_screen.dart # Chat interface
│   │   └── main.dart                      # App entry point
│   ├── assets/
│   │   └── [AI models stored here]
│   └── pubspec.yaml                       # Dependencies
├── .gitignore                             # Excludes model files
└── README.md                              # This file
```

## 🤝 Contributing

This project is part of an educational initiative. Contributions focused on:
- Educational content and features
- Performance optimizations
- Accessibility improvements
- Localization support

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Google AI** for the Gemma model family and flutter_gemma package
- **Flutter Community** for the robust mobile development framework
- **Educational Partners** working to support Afghan women's education

---

**🌟 "Empowering education through AI, one conversation at a time" 🌟** 

# 🌟 Noor - AI-Powered Educational Platform

> **Empowering Afghan Women Through Accessible, Offline-First Education**

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-blue.svg)](https://flutter.dev/)
[![Gemma 3n](https://img.shields.io/badge/Gemma%203n-Multimodal%20AI-green.svg)](https://ai.google.dev/gemma)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🎯 Project Vision

**Noor** (meaning "light" in Persian/Dari) is an innovative educational platform designed specifically for Afghan women who face barriers to traditional education. Built for the **Google Gemma 3n Impact Challenge**, Noor leverages cutting-edge on-device AI to provide accessible, private, and offline-first learning experiences.

### 🌍 The Problem We're Solving

In Afghanistan, millions of women and girls are denied access to formal education. Noor addresses this critical challenge by providing:

- **Privacy-First Learning**: All AI processing happens locally on device
- **Offline Accessibility**: Works without internet connectivity
- **Culturally Sensitive**: Designed with Afghan women's needs in mind
- **Multimodal Support**: Text, image, and voice-based learning

## ✨ Key Features

### 🤖 **AI-Powered Learning Assistant**
- **Local Gemma 3n Integration**: Private, on-device AI conversations
- **Multilingual Support**: Supports Dari, Pashto, and English
- **Contextual Learning**: AI adapts to individual learning pace and style

### 📚 **Smart Course Generation**
- **AI-Generated Flashcards**: Create study materials from any topic
- **Adaptive Content**: Courses adjust to learner's progress
- **Offline Course Library**: Pre-loaded educational content

### 📸 **Document Scanner & OCR**
- **Gemma 3n Vision**: Advanced text extraction from images
- **Handwriting Recognition**: Digitize handwritten notes
- **Smart Organization**: AI categorizes and tags scanned content
- **Offline Processing**: No internet required for text extraction

### 📝 **Intelligent Note Management**
- **AI-Powered Organization**: Automatic categorization and tagging
- **Search & Filter**: Find notes instantly with smart search
- **Visual Learning**: Image-text association for better retention

### 🏆 **Achievement System**
- **Progress Tracking**: Monitor learning milestones
- **Motivational Rewards**: Celebrate educational achievements
- **Personalized Goals**: AI-suggested learning objectives

## 🚀 Technical Innovation

### **Gemma 3n Integration**
Noor showcases the full potential of Google's Gemma 3n model:

- **On-Device Performance**: Runs efficiently on mobile devices
- **Multimodal Capabilities**: Processes text, images, and voice
- **Privacy-First**: No data leaves the device
- **Offline-Ready**: Full functionality without internet

### **Architecture Highlights**
```
📱 Flutter Frontend
├── 🤖 Gemma 3n Native Service
├── 📸 OCR & Vision Processing
├── 📚 Course Content Generator
├── 💾 Local Data Storage
└── 🎯 Achievement Engine
```

## 📱 Screenshots & Demo

### Main Features
| AI Chat | Course Generation | Document Scanner |
|---------|------------------|------------------|
| ![Chat](docs/screenshots/chat.png) | ![Courses](docs/screenshots/courses.png) | ![Scanner](docs/screenshots/scanner.png) |

### Learning Experience
| Flashcards | Notes Management | Progress Tracking |
|------------|------------------|-------------------|
| ![Flashcards](docs/screenshots/flashcards.png) | ![Notes](docs/screenshots/notes.png) | ![Progress](docs/screenshots/progress.png) |

## 🛠️ Installation & Setup

### Prerequisites
- Flutter 3.8.1 or higher
- Android Studio / Xcode for mobile development
- Gemma 3n model files (automatically downloaded)

### Quick Start
```bash
# Clone the repository
git clone https://github.com/Rappid-exe/ProjectNoor.git
cd ProjectNoor/Noor

# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run -d android  # For Android
flutter run -d ios      # For iOS
flutter run -d chrome   # For Web (limited features)
```

### Model Setup
The app automatically downloads and configures the Gemma 3n model on first launch:
- **Model**: `gemma-3n-E2B-it-int4.task`
- **Size**: ~2.5GB (optimized with int4 quantization)
- **Storage**: Local device storage for privacy

## 🎥 Video Demo

**[Watch our 3-minute demo video](https://youtu.be/your-demo-video)**

See Noor in action as we demonstrate:
- Real-time AI conversations in multiple languages
- Document scanning and text extraction
- Course generation and flashcard creation
- Offline functionality and privacy features

## 🏗️ Project Structure

```
lib/
├── models/           # Data models (Course, Achievement, Note)
├── services/         # Core services (AI, OCR, Storage)
│   ├── gemma_native_service.dart
│   ├── ocr_service.dart
│   ├── course_service.dart
│   └── notes_service.dart
├── views/            # UI screens and components
│   └── student/      # Student-facing interfaces
└── main.dart         # App entry point
```

## 🌟 Impact & Vision

### **Immediate Impact**
- **Accessibility**: Enables learning for women without internet access
- **Privacy**: Protects user data with on-device processing
- **Flexibility**: Learn at your own pace, anytime, anywhere

### **Long-term Vision**
- **Educational Equity**: Bridge the education gap for marginalized communities
- **Cultural Preservation**: Support local languages and learning traditions
- **Scalable Solution**: Expand to other regions facing similar challenges

### **Real-World Applications**
- **Remote Learning**: Education in areas with limited connectivity
- **Adult Education**: Flexible learning for working women
- **Skill Development**: Professional and vocational training
- **Language Learning**: Multilingual support for diverse communities

## 🔧 Technical Deep Dive

### **Gemma 3n Features Utilized**
1. **Per-Layer Embeddings (PLE)**: Efficient memory usage
2. **Mix'n'Match Capability**: Dynamic model sizing
3. **Multimodal Understanding**: Text, image, and audio processing
4. **Multilingual Support**: Native support for multiple languages

### **Performance Optimizations**
- **Model Quantization**: int4 quantization for mobile efficiency
- **Lazy Loading**: Load model components as needed
- **Memory Management**: Efficient resource utilization
- **Battery Optimization**: Minimize power consumption

### **Privacy & Security**
- **Local Processing**: All AI operations on-device
- **No Data Collection**: Zero telemetry or user tracking
- **Encrypted Storage**: Secure local data storage
- **Offline-First**: No dependency on external services

## 🤝 Contributing

We welcome contributions from developers, educators, and advocates for women's education!

### **How to Contribute**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### **Areas for Contribution**
- **Localization**: Add support for more languages
- **Content**: Create educational materials and courses
- **Features**: Enhance AI capabilities and user experience
- **Testing**: Improve test coverage and quality assurance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google AI**: For the incredible Gemma 3n model and Impact Challenge
- **Flutter Team**: For the amazing cross-platform framework
- **Afghan Women**: The inspiration and driving force behind this project
- **Open Source Community**: For the tools and libraries that make this possible

## 📞 Contact & Support

- **Project Lead**: [Your Name](mailto:your.email@example.com)
- **GitHub Issues**: [Report bugs or request features](https://github.com/Rappid-exe/ProjectNoor/issues)
- **Discussions**: [Join our community discussions](https://github.com/Rappid-exe/ProjectNoor/discussions)

---

**Built with ❤️ for the Google Gemma 3n Impact Challenge**

*Noor represents more than just an app—it's a beacon of hope for educational equity and women's empowerment. Together, we can light the path to a more inclusive future.*
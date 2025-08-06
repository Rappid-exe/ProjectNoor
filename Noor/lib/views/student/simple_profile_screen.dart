import 'package:flutter/material.dart';

class SimpleProfileScreen extends StatelessWidget {
  const SimpleProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Profile Header
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Welcome to Noor',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Educational Platform for Students in Low Connectivity Areas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.indigo.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // App Information
                _buildInfoCard(
                  icon: Icons.school,
                  title: 'About Noor',
                  description: 'Noor is an educational platform designed to support students in low connectivity areas. Our AI-powered tutor provides personalized assistance across various subjects.',
                ),
                
                const SizedBox(height: 20),
                
                _buildInfoCard(
                  icon: Icons.smart_toy,
                  title: 'AI Tutor',
                  description: 'Chat with our AI tutor for help with mathematics, science, languages, and more. Get instant answers and explanations tailored to your learning level.',
                ),
                
                const SizedBox(height: 20),
                
                _buildInfoCard(
                  icon: Icons.book,
                  title: 'Courses',
                  description: 'Access structured courses in various subjects. Track your progress and complete lessons at your own pace.',
                ),
                
                const SizedBox(height: 20),
                
                _buildInfoCard(
                  icon: Icons.camera_alt,
                  title: 'Document Scanner',
                  description: 'Use the camera to scan documents, homework, or textbook pages for quick reference and AI assistance.',
                ),
                
                const SizedBox(height: 40),
                
                // Platform Features
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Platform Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStatusItem('🤖', 'AI Chat Tutor', 'Real-time conversations with Gemma 3'),
                      _buildStatusItem('📚', 'Interactive Courses', 'Flashcards and structured learning'),
                      _buildStatusItem('📸', 'OCR Scanner', 'Extract text from images with AI'),
                      _buildStatusItem('🌐', 'Offline Ready', 'Works without internet connection'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Version Info
                Text(
                  'Noor Educational Platform v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Empowering education for all students',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.indigo.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String icon, String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
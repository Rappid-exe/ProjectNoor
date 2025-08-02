package com.example.noor

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInference.LlmInferenceOptions
import kotlinx.coroutines.*
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.noor/gemma"
    private var llmInference: LlmInference? = null
    private lateinit var channel: MethodChannel
    private val mainScope = CoroutineScope(Dispatchers.Main + Job())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        initializeModel(modelPath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Model path is required", null)
                    }
                }

                "generateText" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    val maxTokens = call.argument<Int>("maxTokens") ?: 512
                    val temperature = call.argument<Double>("temperature") ?: 0.8
                    generateText(prompt, maxTokens, temperature.toFloat(), result)
                }

                "generateTextStream" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    val maxTokens = call.argument<Int>("maxTokens") ?: 512
                    val temperature = call.argument<Double>("temperature") ?: 0.8
                    // Use simulated streaming for now
                    generateTextSimulatedStream(prompt, maxTokens, temperature.toFloat(), result)
                }

                "dispose" -> {
                    dispose()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun initializeModel(modelPath: String, result: MethodChannel.Result) {
        mainScope.launch {
            try {
                // Verify model file exists
                val modelFile = File(modelPath)
                if (!modelFile.exists()) {
                    result.error("MODEL_NOT_FOUND", "Model file not found at: $modelPath", null)
                    return@launch
                }

                // Log file size for debugging
                val fileSizeMB = modelFile.length() / (1024 * 1024)
                println("Gemma: Loading model from $modelPath (${fileSizeMB}MB)")

                // Create options
                val options = LlmInferenceOptions.builder()
                    .setModelPath(modelPath)
                    .setMaxTopK(64)
                    .build()

                // Initialize LLM on IO thread
                withContext(Dispatchers.IO) {
                    llmInference = LlmInference.createFromOptions(context, options)
                }

                println("Gemma: Model loaded successfully")
                result.success(true)
            } catch (e: Exception) {
                e.printStackTrace()
                result.error("INIT_ERROR", "Failed to initialize model: ${e.message}", null)
            }
        }
    }

    private fun generateText(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        result: MethodChannel.Result
    ) {
        val inference = llmInference
        if (inference == null) {
            result.error("NOT_INITIALIZED", "Model not initialized", null)
            return
        }

        mainScope.launch {
            try {
                println("Gemma: Generating response for prompt: $prompt")

                val response = withContext(Dispatchers.IO) {
                    inference.generateResponse(prompt)
                }

                println("Gemma: Response generated successfully")
                result.success(response)
            } catch (e: Exception) {
                e.printStackTrace()
                result.error("GENERATION_ERROR", "Failed to generate text: ${e.message}", null)
            }
        }
    }

    // Simulated streaming - sends the response in chunks
    private fun generateTextSimulatedStream(
        prompt: String,
        maxTokens: Int,
        temperature: Float,
        result: MethodChannel.Result
    ) {
        val inference = llmInference
        if (inference == null) {
            result.error("NOT_INITIALIZED", "Model not initialized", null)
            return
        }

        mainScope.launch {
            try {
                // Send initial status
                channel.invokeMethod("onStreamChunk", "")

                // Generate the full response
                val fullResponse = withContext(Dispatchers.IO) {
                    inference.generateResponse(prompt)
                }

                // Simulate streaming by sending words progressively
                val words = fullResponse.split(" ")
                val chunkSize = maxOf(1, words.size / 10) // Send in ~10 chunks

                var currentText = ""
                for (i in words.indices step chunkSize) {
                    val endIndex = minOf(i + chunkSize, words.size)
                    val chunk = words.subList(i, endIndex).joinToString(" ")
                    currentText += if (currentText.isEmpty()) chunk else " $chunk"

                    channel.invokeMethod("onStreamChunk", currentText)

                    // Small delay to simulate streaming
                    delay(50)
                }

                // Ensure full response is sent
                channel.invokeMethod("onStreamChunk", fullResponse)
                channel.invokeMethod("onStreamComplete", null)
                result.success(null)

            } catch (e: Exception) {
                e.printStackTrace()
                channel.invokeMethod("onError", e.message)
                result.error("STREAM_ERROR", "Failed to generate text: ${e.message}", null)
            }
        }
    }

    private fun dispose() {
        llmInference?.close()
        llmInference = null
        mainScope.cancel()
    }

    override fun onDestroy() {
        dispose()
        super.onDestroy()
    }
}

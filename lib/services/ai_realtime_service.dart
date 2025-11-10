import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIRealtimeService {
  static const String baseUrl = 'https://api.a4f.co/v1';
  static const String model = 'provider-3/llama-3.3-70b';

  /// Streams AI response tokens in real-time from Llama 3.3 70B API
  Stream<String> streamResponse(String prompt, {List<Map<String, String>>? conversationHistory}) async* {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }

    // Build messages list with conversation history
    final List<Map<String, String>> messages = [];
    
    // Add conversation history if provided
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      messages.addAll(conversationHistory);
    }
    
    // Add current user message
    messages.add({
      'role': 'user',
      'content': prompt,
    });

    final requestBody = jsonEncode({
      'model': model,
      'stream': true,
      'messages': messages,
    });

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/chat/completions'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });

      request.body = requestBody;

      final streamedResponse = await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception(
          'API Error: ${streamedResponse.statusCode} - $errorBody',
        );
      }

      // Parse SSE stream
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6); // Remove 'data: ' prefix
            
            if (data.trim() == '[DONE]') {
              return; // Stream complete
            }

            try {
              final jsonData = jsonDecode(data);
              final choices = jsonData['choices'] as List?;
              
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } catch (e) {
              // Skip malformed JSON lines
              continue;
            }
          }
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to stream response: $e');
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return false;
      }
      
      // Try a simple test request
      final testStream = streamResponse('Hello');
      await testStream.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connection timeout'),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}


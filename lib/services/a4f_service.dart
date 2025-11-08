import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class A4FService {
  static const String baseUrl = 'https://api.a4f.co/v1';
  static const String model = 'provider-3/llama-3.3-70b';

  /// Sends a message to the A4F API and returns the response
  Future<String> sendMessage(String message, {List<Map<String, String>>? conversationHistory}) async {
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
      'content': message,
    });

    final requestBody = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': false, // Non-streaming for simpler implementation
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

      final jsonData = jsonDecode(response.body);
      final choices = jsonData['choices'] as List?;
      
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }

      throw Exception('No response content received from API');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to send message: $e');
    }
  }

  /// Streams AI response tokens in real-time (optional enhancement)
  Stream<String> streamResponse(String message, {List<Map<String, String>>? conversationHistory}) async* {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in environment variables');
    }

    // Build messages list with conversation history
    final List<Map<String, String>> messages = [];
    
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      messages.addAll(conversationHistory);
    }
    
    messages.add({
      'role': 'user',
      'content': message,
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
        throw Exception('API Error: ${streamedResponse.statusCode} - $errorBody');
      }

      // Parse SSE stream
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            
            if (data.trim() == '[DONE]') {
              return;
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
}


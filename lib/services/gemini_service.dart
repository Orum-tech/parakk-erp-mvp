import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyANrQENk_ta2CyhcPsbB4fz2vP77glrs2g';
  
  // Use gemini-2.5-flash directly
  String get _baseUrl => 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey';

  // Get response from Gemini API
  Future<String> getResponse(String prompt, {String context = ''}) async {
    try {
      // Prepare the prompt with context for academic assistance
      final fullPrompt = context.isNotEmpty
          ? '$context\n\nStudent Question: $prompt\n\nPlease provide a helpful, educational response suitable for a student.'
          : 'You are an AI tutor helping students with their academic questions. Provide clear, educational, and helpful responses.\n\nStudent Question: $prompt\n\nPlease provide a helpful, educational response suitable for a student.';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ?? 
                 'Sorry, I could not generate a response. Please try again.';
        } else {
          return 'Sorry, I could not generate a response. Please try again.';
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Invalid request. Please check your API key.';
          return 'Error: $errorMessage';
        } catch (e) {
          return 'Error: Invalid request. Please check your API key and model name.';
        }
      } else if (response.statusCode == 401) {
        return 'Error: Invalid API key. Please check your Gemini API key configuration.';
      } else {
        final errorBody = response.body.length > 200 
            ? '${response.body.substring(0, 200)}...' 
            : response.body;
        return 'Error: Failed to get response. Status code: ${response.statusCode}. Please check your API key and internet connection.';
      }
    } catch (e) {
      return 'Error: ${e.toString()}. Please check your internet connection and API key.';
    }
  }


  // Check if API key is configured
  bool isApiKeyConfigured() {
    return _apiKey != 'YOUR_GEMINI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}

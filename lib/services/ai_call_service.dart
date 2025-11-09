import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_call_state.dart';
import '../models/shopping_item.dart';
import '../models/meal.dart';
import '../models/pantry_item.dart';
import 'shopping_service.dart';
import 'meal_service.dart';
import 'pantry_service.dart';
import 'firestore_service.dart';

class AiCallResponse {
  final String text;
  final List<ToolCall>? toolCalls;
  final AiCallState? state;

  AiCallResponse({required this.text, this.toolCalls, this.state});
}

class ToolCall {
  final String name;
  final Map<String, dynamic> args;

  ToolCall({required this.name, required this.args});
}

class AiCallService {
  static const String _apiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _apiKey = 'AIzaSyCAJsOXK7cvsyqbk08L9Gvm-kkJ1AkHDgY';
  static const String _model =
      'gemini-2.5-flash'; // Gemini 2.5 Flash for fast, accurate image analysis

  /// Process user utterance with optional frame and ML Kit data
  Future<AiCallResponse> processUserInput({
    required String utterance,
    String? frameImagePath,
    Map<String, dynamic>? mlKitData,
    AiCallState? currentState,
  }) async {
    try {
      // Prepare request payload
      final payload = {
        'utterance': utterance,
        'frame':
            frameImagePath != null ? await _encodeImage(frameImagePath) : null,
        'ml_kit': mlKitData,
        'current_state': currentState?.toJson(),
      };

      // Call AI backend (stub implementation)
      final response = await _callAiBackend(payload);

      // Parse response
      return _parseAiResponse(response);
    } catch (e) {
      // Fallback response on error
      return AiCallResponse(
        text: "I'm having trouble processing that. Could you try again?",
      );
    }
  }

  /// Execute a tool call
  Future<Map<String, dynamic>> executeToolCall(ToolCall toolCall) async {
    print('🛠️ [TOOL] Executing tool call: ${toolCall.name}');
    print('🛠️ [TOOL] Tool args: ${toolCall.args}');

    try {
      Map<String, dynamic> result;

      switch (toolCall.name) {
        case 'start_frame_stream':
          result = {'success': true, 'message': 'Frame stream started'};
          break;

        case 'stop_frame_stream':
          result = {'success': true, 'message': 'Frame stream stopped'};
          break;

        case 'request_frame':
          result = {'success': true, 'message': 'Frame requested'};
          break;

        case 'set_timer':
          final seconds = toolCall.args['seconds'] as int? ?? 0;
          final label = toolCall.args['label'] as String? ?? '';
          result = {
            'success': true,
            'timer': {
              'label': label,
              'seconds': seconds,
              'ends_at':
                  DateTime.now()
                      .add(Duration(seconds: seconds))
                      .toIso8601String(),
            },
          };
          break;

        case 'advance_step':
          final by = toolCall.args['by'] as int? ?? 1;
          result = {'success': true, 'step_delta': by};
          break;

        case 'generate_recipe':
          result = await _generateRecipe(toolCall.args);
          break;

        case 'read_pantry':
          result = await _readPantry();
          break;

        case 'update_pantry_item':
          result = await _updatePantryItem(toolCall.args);
          break;

        case 'add_pantry_item':
          result = await _addPantryItem(toolCall.args);
          break;

        case 'remove_pantry_item':
          result = await _removePantryItem(toolCall.args);
          break;

        case 'add_to_shopping_list':
          result = await _addToShoppingList(toolCall.args);
          break;

        case 'nutrition_estimate':
          result = await _nutritionEstimate(toolCall.args);
          break;

        case 'log_meal':
          result = await _logMeal(toolCall.args);
          break;

        case 'summarize_photo':
          result = {'success': true, 'summary': 'Photo analyzed'};
          break;

        default:
          print('❌ [TOOL] Unknown tool: ${toolCall.name}');
          result = {
            'success': false,
            'error': 'Unknown tool: ${toolCall.name}',
          };
      }

      print('✅ [TOOL] Tool call result: $result');
      return result;
    } catch (e, stackTrace) {
      print('❌ [TOOL] Error executing tool call ${toolCall.name}: $e');
      print('❌ [TOOL] Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Private helper methods

  Future<String> _encodeImage(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<Map<String, dynamic>> _callAiBackend(
    Map<String, dynamic> payload,
  ) async {
    try {
      // Build the prompt for the AI
      final utterance = payload['utterance'] as String? ?? '';
      final frameBase64 = payload['frame'] as String?;
      final mlKitData = payload['ml_kit'] as Map<String, dynamic>?;
      final currentState = payload['current_state'] as Map<String, dynamic>?;

      // Construct the system prompt and user message
      final systemPrompt = _buildSystemPrompt(currentState);
      final userMessageText = _buildUserMessage(utterance, null, mlKitData);

      // Build Gemini API request format
      // Gemini uses 'contents' array with 'parts' containing text and/or inlineData
      // Note: Gemini doesn't have a separate system role, so we combine system prompt with user message
      final parts = <Map<String, dynamic>>[];

      // Add image first if available (Gemini docs recommend image before text for better analysis)
      if (frameBase64 != null) {
        parts.add({
          'inlineData': {'mimeType': 'image/jpeg', 'data': frameBase64},
        });
        print('📡 [GEMINI] Added image to request (base64 encoded JPEG)');
      }

      // Combine system prompt and user message (Gemini doesn't have separate system role)
      // Format: System instructions + User message
      final combinedPrompt = '''
$systemPrompt

---
USER REQUEST:
$userMessageText
''';

      // Add text prompt after image
      parts.add({'text': combinedPrompt});

      // Gemini API request format
      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
          'topP': 0.8,
          'topK': 40,
        },
      };

      // Make API call to Gemini
      print('📡 [GEMINI] Sending request to Gemini API...');
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📡 [GEMINI] Response status code: ${response.statusCode}');
      print('📡 [GEMINI] Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Gemini API response format: responseData['candidates'][0]['content']['parts'][0]['text']
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          final aiText =
              responseData['candidates'][0]['content']['parts'][0]['text']
                  as String;

          print(
            '✅ [GEMINI] AI response received: ${aiText.substring(0, aiText.length > 100 ? 100 : aiText.length)}...',
          );

          // Try to parse JSON from the response
          final parsed = _parseAiResponseText(aiText);
          print(
            '🔍 [GEMINI] Parsed tool calls: ${parsed['tool_calls']?.length ?? 0}',
          );
          return parsed;
        } else {
          print('❌ [GEMINI] Unexpected response format: ${response.body}');
          throw Exception('Gemini API returned unexpected response format');
        }
      } else {
        print('❌ [GEMINI] API call failed with status ${response.statusCode}');
        print('❌ [GEMINI] Response body: ${response.body}');
        throw Exception(
          'Gemini API call failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [GEMINI] Exception in _callAiBackend: $e');
      print('❌ [GEMINI] Stack trace: $stackTrace');
      // Fallback to mock response on error
      final utterance = payload['utterance'] as String? ?? '';
      final lowerUtterance = utterance.toLowerCase();

      if (lowerUtterance.contains('start') && lowerUtterance.contains('call')) {
        return {
          'text':
              "Got it—let's cook! I'll watch your workspace and guide step by step.",
          'tool_calls': [
            {
              'name': 'start_frame_stream',
              'args': {'interval_sec': 5},
            },
            {'name': 'read_pantry', 'args': {}},
          ],
          'state': {
            'mode': 'call',
            'recipe': {'id': '', 'title': '', 'servings': 2},
            'step_index': 0,
            'total_steps': 0,
            'timers': [],
            'prefs': {},
            'pantry_delta': [],
            'notes': 'Starting call mode',
          },
        };
      }

      return {
        'text': "I'm ready to help you cook. What would you like to make?",
        'state': {'mode': 'call', 'notes': 'Waiting for recipe'},
      };
    }
  }

  String _buildSystemPrompt(Map<String, dynamic>? currentState) {
    return '''You are Alfredo, a voice-first cooking & nutrition copilot running inside an Android Flutter app in Video Call Mode.

CONTEXT:
- The app provides: voice STT/TTS, camera frames (periodic snapshots with base64 encoding), ML Kit detection (objects/hazards/labels from image analysis), pantry data, recipe generator, nutrition tracking, shopping lists.
- You receive IMAGES directly and can analyze them visually. This is your PRIMARY source of information.
- ML Kit provides detection hints, but they are often inaccurate or include false positives. Use ML Kit only as a secondary reference.
- Treat this like a friendly call: short, clear, hands-free guidance, and safety-first.

CRITICAL RULE - PRIORITIZE DIRECT IMAGE ANALYSIS:
- You can SEE the image directly. Analyze it yourself - this is your PRIMARY source of truth.
- When an image is provided, look at it carefully and identify what you actually see:
  * Be SPECIFIC: "I see a red apple" (not just "I see food")
  * Be ACCURATE: Only mention what you can clearly see in the image
  * Be HONEST: If something is unclear, say so
- ML Kit detections are provided as hints, but they often include false positives (like detecting "wine" or "cake" when there's just an apple). 
- If ML Kit says "wine, cake, animal" but you see only an apple, say "I see an apple" and ignore the false ML Kit detections.
- Use ML Kit only to confirm what you see, not to invent things that aren't in the image.

IMAGE ANALYSIS - DIRECT VISUAL ANALYSIS:
- When you receive an image, analyze it directly:
  * FOOD ITEMS: Identify specific foods you see (e.g., "apple", "banana", "tomato", "chicken breast")
  * COOKING TOOLS: Identify kitchen tools (e.g., "cutting board", "knife", "pan")
  * FOOD STATE: Describe preparation state (e.g., "raw chicken", "chopped vegetables", "cooked pasta")
  * QUANTITIES: Estimate amounts when visible (e.g., "two tomatoes", "a bunch of grapes")
- Be SPECIFIC and ACCURATE:
  * GOOD: "I can see a red apple on a white surface"
  * GOOD: "I see raw chicken breast and chopped vegetables on a cutting board"
  * GOOD: "I see pasta in a pot of boiling water"
  * BAD: "I see food" (too vague)
  * BAD: Mentioning items from ML Kit that you don't actually see in the image
- If the image is blurry or unclear, say so: "The image is a bit blurry, but I can see [what's clear]"
- If ML Kit detected many things but you only see one clear item, focus on what you actually see
- Ignore ML Kit false positives - trust your visual analysis first

CORE BEHAVIOR:
- Keep every reply ≤120 words, speakable, no emojis.
- Always track and update: recipe {id,title,servings}, step_index, total_steps, active timers, user prefs (diet/allergies/spice), pantry changes.
- Be proactive with safety: hot oil, knives, steam, cross-contamination. Give ONE short reminder when needed.
- You do NOT have continuous video. You only see still frames and ML Kit summaries. If information is stale, politely ask for a fresh frame.

OUTPUT FORMAT:
- Normal, concise guidance text FIRST.
- If any app action or state update is needed, append EXACTLY ONE JSON object (no markdown fences) with this shape:
{
  "tool_calls": [
    { "name":"<tool_name>", "args":{ ... } }
  ],
  "state": {
    "mode": "call",
    "recipe": {"id":"", "title":"", "servings":2},
    "step_index": 0,
    "total_steps": 0,
    "timers": [ {"label":"", "seconds":0, "ends_at": null} ],
    "prefs": {"diet":"", "spice":"", "allergies":[]},
    "pantry_delta": [ {"item":"", "delta":0, "unit":""} ],
    "notes": "1 short status line"
  }
}
- Omit "tool_calls" if you're not requesting actions. Include "state" whenever it changes.

AVAILABLE TOOLS:
- start_frame_stream(interval_sec:number)
- stop_frame_stream()
- request_frame(note?:string)
- set_timer(seconds:number, label:string)
- advance_step(by:number)
- generate_recipe(goal:string, servings:number, constraints?:object)
- read_pantry() - Read all pantry items
- update_pantry_item(item_id:string, quantity?:number, name?:string) - Update existing pantry item
- add_pantry_item(name:string, quantity:number, unit?:string, category?:string, expiry_days?:number) - Add new pantry item
- remove_pantry_item(item_id?:string, name?:string) - Remove pantry item by ID or name
- add_to_shopping_list(items:[{name,qty,unit,reason}])
- nutrition_estimate(recipe_id|null, items:[{name,qty,unit}], servings:number)
- log_meal(recipe_id|null, serving_size:string, when:string)
- summarize_photo()

Current State: ${currentState != null ? jsonEncode(currentState) : 'none'}''';
  }

  String _buildUserMessage(
    String utterance,
    String? frameBase64,
    Map<String, dynamic>? mlKitData,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('User said: "$utterance"');

    if (mlKitData != null) {
      final objects = mlKitData['objects'] as List? ?? [];
      final labels = mlKitData['labels'] as List? ?? [];
      final hazards = mlKitData['hazards'] as List? ?? [];

      // Extract food-related items from all detections
      final allDetections = <String>{};
      allDetections.addAll(objects.map((e) => e.toString().toLowerCase()));
      allDetections.addAll(labels.map((e) => e.toString().toLowerCase()));

      // Categorize detections
      final foodItems = <String>[];
      final nonFoodItems = <String>[];
      final kitchenItems = <String>[];

      final foodKeywords = [
        // General food terms
        'food',
        'fruit',
        'vegetable',
        'meat',
        'poultry',
        'seafood',
        'grain',
        'dairy',
        'protein',
        // Specific fruits
        'apple',
        'banana',
        'orange',
        'grape',
        'strawberry',
        'berry',
        'mango',
        'pineapple',
        'watermelon',
        'lemon', 'lime', 'peach', 'pear', 'cherry', 'plum', 'kiwi', 'avocado',
        // Specific vegetables
        'tomato',
        'potato',
        'onion',
        'garlic',
        'carrot',
        'broccoli',
        'lettuce',
        'spinach',
        'cucumber',
        'pepper',
        'bell pepper',
        'mushroom',
        'celery',
        'cabbage',
        'corn',
        'pea',
        'bean',
        // Meat and protein
        'chicken',
        'beef',
        'pork',
        'fish',
        'salmon',
        'tuna',
        'turkey',
        'lamb',
        'bacon',
        'sausage',
        'egg', 'tofu', 'tempeh',
        // Grains and carbs
        'bread',
        'rice',
        'pasta',
        'noodle',
        'spaghetti',
        'wheat',
        'flour',
        'oats',
        'quinoa',
        'barley',
        // Dairy
        'cheese',
        'milk',
        'yogurt',
        'butter',
        'cream',
        'sour cream',
        'cottage cheese',
        // Beverages
        'wine', 'juice', 'cola', 'beverage', 'drink', 'alcohol',
        // Prepared foods
        'meal',
        'dish',
        'soup',
        'salad',
        'sandwich',
        'burger',
        'pizza',
        'stew',
        'curry',
        // Cooking terms
        'ingredient', 'recipe', 'cooking', 'flesh',
      ];
      final kitchenKeywords = [
        'cutting board',
        'knife',
        'pan',
        'pot',
        'bowl',
        'plate',
        'spoon',
        'fork',
        'tableware',
        'kitchen',
        'cookware',
        'cutlery',
      ];

      for (final item in allDetections) {
        if (foodKeywords.any((keyword) => item.contains(keyword))) {
          foodItems.add(item);
        } else if (kitchenKeywords.any((keyword) => item.contains(keyword))) {
          kitchenItems.add(item);
        } else {
          nonFoodItems.add(item);
        }
      }

      // Filter out common false positives from ML Kit
      final filteredFoodItems = _filterFalsePositives(foodItems);
      final filteredKitchenItems = _filterFalsePositives(kitchenItems);

      buffer.writeln(
        '\n=== ML KIT DETECTION RESULTS (REFERENCE ONLY - NOT AUTHORITATIVE) ===',
      );
      buffer.writeln(
        'NOTE: ML Kit often produces false positives. Analyze the image directly and only use ML Kit as a hint. If ML Kit says something that you don\'t see in the image, ignore it.',
      );

      if (filteredFoodItems.isNotEmpty) {
        buffer.writeln(
          '\nML KIT HINTS - FOOD ITEMS: ${filteredFoodItems.join(", ")}',
        );
        buffer.writeln(
          '→ Use these as hints, but trust your visual analysis of the image. If you see something different in the image, say what you actually see.',
        );
      }

      if (filteredKitchenItems.isNotEmpty) {
        buffer.writeln(
          '\nML KIT HINTS - KITCHEN ITEMS: ${filteredKitchenItems.join(", ")}',
        );
      }

      if (hazards.isNotEmpty) {
        buffer.writeln(
          '\nML KIT HINTS - POTENTIAL HAZARDS: ${hazards.join(", ")}',
        );
        buffer.writeln(
          '→ Always mention safety concerns if you see hazards in the image.',
        );
      }

      // Only show non-food items if there are few of them (likely relevant)
      if (nonFoodItems.length <= 3 && nonFoodItems.isNotEmpty) {
        buffer.writeln(
          '\nML KIT HINTS - OTHER ITEMS: ${nonFoodItems.join(", ")}',
        );
      } else if (nonFoodItems.length > 3) {
        buffer.writeln(
          '\nML KIT detected many items (${nonFoodItems.length}), likely including false positives. Focus on what you actually see in the image.',
        );
      }

      buffer.writeln('\n=== END ML KIT HINTS ===');
      buffer.writeln(
        'REMEMBER: The image is your PRIMARY source. Analyze it directly. ML Kit hints may be inaccurate.',
      );
    } else {
      buffer.writeln('\n⚠️ WARNING: No ML Kit detection data available.');
      buffer.writeln(
        '→ Say that you do not have image analysis data and ask the user to try again.',
      );
    }

    if (frameBase64 != null) {
      buffer.writeln('\n📸 An image is attached to this message.');
      buffer.writeln(
        'Please analyze this image directly and describe what you see. Be specific about food items, ingredients, and cooking tools.',
      );
      buffer.writeln(
        'ML Kit hints are provided above, but they may contain false positives. Trust your visual analysis of the image.',
      );
    }

    return buffer.toString();
  }

  /// Filter out common false positives from ML Kit detections
  List<String> _filterFalsePositives(List<String> items) {
    // Common false positives that ML Kit often detects incorrectly
    final falsePositives = {
      'wine',
      'cake',
      'animal',
      'pet',
      'dog',
      'cat',
      'bird',
      'flesh',
      'musical instrument',
      'piano',
      'guitar',
      'computer',
      'mobile phone',
      'television',
      'poster',
      'pattern',
      'love',
      'cuisine',
      'lipstick',
      'nail',
      'eyelash',
      'toy',
      'jacket',
      'jeans',
      'shoe',
      'sneakers',
      'shorts',
      'hat',
      'goggles',
      'sunglasses',
      'helmet',
      'tire',
      'wheel',
      'bicycle',
      'vehicle',
      'bumper',
      'roof',
      'building',
      'room',
      'desk',
      'chair',
      'sitting',
      'leisure',
      'race',
      'net',
      'bag',
      'handbag',
      'jersey',
      'tie',
      'paper',
      'plant',
      'flower',
      'cutlery',
      'cola',
    };

    return items.where((item) {
      final lowerItem = item.toLowerCase();
      // Keep items that are not in the false positives list
      return !falsePositives.contains(lowerItem) &&
          !falsePositives.any((fp) => lowerItem.contains(fp));
    }).toList();
  }

  Map<String, dynamic> _parseAiResponseText(String aiText) {
    print('🔍 [PARSE] Parsing AI response text (length: ${aiText.length})');

    // Try to extract JSON from the response
    // Look for JSON object in the text
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(aiText);

    if (jsonMatch != null) {
      try {
        final jsonStr = jsonMatch.group(0)!;
        print('🔍 [PARSE] Found JSON in response');
        final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final textBeforeJson = aiText.substring(0, jsonMatch.start).trim();

        final toolCalls = jsonData['tool_calls'];
        print(
          '🔍 [PARSE] Extracted ${toolCalls != null ? (toolCalls as List).length : 0} tool calls',
        );
        if (toolCalls != null && toolCalls.isNotEmpty) {
          for (var tc in toolCalls) {
            print('  - Tool: ${tc['name']}, args: ${tc['args']}');
          }
        }

        return {
          'text': textBeforeJson.isNotEmpty ? textBeforeJson : aiText,
          'tool_calls': toolCalls,
          'state': jsonData['state'],
        };
      } catch (e, stackTrace) {
        print('❌ [PARSE] JSON parsing failed: $e');
        print('❌ [PARSE] Stack trace: $stackTrace');
        // If JSON parsing fails, return just the text
        return {'text': aiText};
      }
    }

    print('⚠️ [PARSE] No JSON found in response - returning text only');
    // No JSON found, return just the text
    return {'text': aiText};
  }

  AiCallResponse _parseAiResponse(Map<String, dynamic> response) {
    final text = response['text'] as String? ?? '';
    final toolCallsJson = response['tool_calls'] as List?;
    final stateJson = response['state'] as Map<String, dynamic>?;

    List<ToolCall>? toolCalls;
    if (toolCallsJson != null) {
      toolCalls =
          toolCallsJson.map((tc) {
            final tcMap = tc as Map<String, dynamic>;
            return ToolCall(
              name: tcMap['name'] as String? ?? '',
              args: tcMap['args'] as Map<String, dynamic>? ?? {},
            );
          }).toList();
    }

    AiCallState? state;
    if (stateJson != null) {
      state = _parseState(stateJson);
    }

    return AiCallResponse(text: text, toolCalls: toolCalls, state: state);
  }

  AiCallState _parseState(Map<String, dynamic> json) {
    return AiCallState(
      mode: json['mode'] ?? 'idle',
      recipe:
          json['recipe'] != null
              ? RecipeInfo.fromJson(json['recipe'] as Map<String, dynamic>)
              : null,
      stepIndex: json['step_index'] ?? 0,
      totalSteps: json['total_steps'] ?? 0,
      timers:
          (json['timers'] as List?)
              ?.map((t) => TimerInfo.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      prefs:
          json['prefs'] != null
              ? UserPrefs.fromJson(json['prefs'] as Map<String, dynamic>)
              : UserPrefs(),
      pantryDelta:
          (json['pantry_delta'] as List?)
              ?.map((p) => PantryDelta.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] ?? '',
    );
  }

  Future<Map<String, dynamic>> _generateRecipe(
    Map<String, dynamic> args,
  ) async {
    final goal = args['goal'] as String? ?? '';
    final servings = args['servings'] as int? ?? 2;
    // final constraints = args['constraints'] as Map<String, dynamic>? ?? {};

    // Mock recipe generation - in real implementation, call recipe service
    return {
      'success': true,
      'recipe': {
        'id': 'generated_${DateTime.now().millisecondsSinceEpoch}',
        'title': goal.isNotEmpty ? goal : 'Custom Recipe',
        'servings': servings,
      },
    };
  }

  Future<Map<String, dynamic>> _readPantry() async {
    print('🔵 [PANTRY] _readPantry called');

    final userId = FirestoreService.currentUserId;
    if (userId == null) {
      print('❌ [PANTRY] User not authenticated');
      return {'success': false, 'error': 'User not authenticated'};
    }

    try {
      print(
        '🔍 [PANTRY] Reading pantry items from Firestore for user: $userId',
      );
      // Get pantry items (one-time read)
      final snapshot =
          await FirestoreService.firestore
              .collection('pantry_items')
              .where('userId', isEqualTo: userId)
              .get();

      final items =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'quantity': data['quantity'] ?? 0,
              'unit': data['unit'] ?? '',
              'category': data['category'],
            };
          }).toList();

      print('✅ [PANTRY] Found ${items.length} pantry items');
      for (var item in items) {
        print('  - ${item['name']}: ${item['quantity']} ${item['unit']}');
      }

      return {'success': true, 'items': items};
    } catch (e, stackTrace) {
      print('❌ [PANTRY] Error reading pantry: $e');
      print('❌ [PANTRY] Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _updatePantryItem(
    Map<String, dynamic> args,
  ) async {
    print('🔵 [PANTRY] _updatePantryItem called with args: $args');

    final userId = FirestoreService.currentUserId;
    if (userId == null) {
      print('❌ [PANTRY] User not authenticated');
      return {'success': false, 'error': 'User not authenticated'};
    }

    final itemId = args['item_id'] as String?;
    final quantity = args['quantity'] as double?;
    final name = args['name'] as String?;

    print(
      '📦 [PANTRY] Updating item - ID: $itemId, name: $name, quantity: $quantity',
    );

    if (itemId == null) {
      print('❌ [PANTRY] Item ID is required');
      return {'success': false, 'error': 'Item ID is required'};
    }

    try {
      // First get the existing item
      print('🔍 [PANTRY] Fetching existing item from Firestore...');
      final doc =
          await FirestoreService.firestore
              .collection('pantry_items')
              .doc(itemId)
              .get();

      if (!doc.exists) {
        print('❌ [PANTRY] Pantry item not found: $itemId');
        return {'success': false, 'error': 'Pantry item not found'};
      }

      final data = doc.data()!;
      final pantryItem = PantryItem(
        id: itemId,
        name: name ?? data['name'] ?? '',
        quantity: quantity ?? (data['quantity'] ?? 0).toDouble(),
        unit: data['unit'] ?? 'g',
        expiryDate:
            data['expiryDate'] != null
                ? (data['expiryDate'] as dynamic).toDate()
                : null,
        category: data['category'],
      );

      print('💾 [PANTRY] Updating pantry item in Firestore...');
      await PantryService.updatePantryItem(itemId, pantryItem);
      print('✅ [PANTRY] Pantry item updated successfully');

      return {
        'success': true,
        'message': 'Pantry item updated: ${pantryItem.name}',
      };
    } catch (e, stackTrace) {
      print('❌ [PANTRY] Error updating pantry item: $e');
      print('❌ [PANTRY] Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _addPantryItem(Map<String, dynamic> args) async {
    print('🔵 [PANTRY] _addPantryItem called with args: $args');

    // Check Firebase auth status
    final auth = FirestoreService.auth;
    final currentUser = auth.currentUser;
    print(
      '🔐 [PANTRY] Firebase auth current user: ${currentUser?.uid ?? "null"}',
    );
    print(
      '🔐 [PANTRY] Firebase auth state: ${auth.currentUser != null ? "authenticated" : "not authenticated"}',
    );

    final userId = FirestoreService.currentUserId;
    if (userId == null) {
      print('❌ [PANTRY] User not authenticated - cannot add pantry item');
      print('❌ [PANTRY] Please ensure user is logged in to Firebase');
      return {
        'success': false,
        'error': 'User not authenticated. Please log in.',
      };
    }

    print('✅ [PANTRY] User authenticated: $userId');

    final name = args['name'] as String? ?? '';
    final quantity = (args['quantity'] ?? 0).toDouble();
    final unit = args['unit'] as String? ?? 'g';
    final category = args['category'] as String?;
    final expiryDays = args['expiry_days'] as int?;

    print(
      '📦 [PANTRY] Parsed item - name: $name, quantity: $quantity, unit: $unit, category: $category',
    );

    if (name.isEmpty) {
      print('❌ [PANTRY] Item name is required');
      return {'success': false, 'error': 'Item name is required'};
    }

    try {
      final pantryItem = PantryItem(
        id: '',
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        expiryDate:
            expiryDays != null
                ? DateTime.now().add(Duration(days: expiryDays))
                : null,
      );

      print('💾 [PANTRY] Creating pantry item in Firestore...');
      final itemId = await PantryService.createPantryItem(pantryItem, userId);
      print('✅ [PANTRY] Pantry item added successfully with ID: $itemId');

      return {
        'success': true,
        'message': 'Pantry item added: $name ($quantity $unit)',
        'item_id': itemId,
      };
    } catch (e, stackTrace) {
      print('❌ [PANTRY] Error adding pantry item: $e');
      print('❌ [PANTRY] Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _removePantryItem(
    Map<String, dynamic> args,
  ) async {
    print('🔵 [PANTRY] _removePantryItem called with args: $args');

    final userId = FirestoreService.currentUserId;
    if (userId == null) {
      print('❌ [PANTRY] User not authenticated');
      return {'success': false, 'error': 'User not authenticated'};
    }

    print('✅ [PANTRY] User authenticated: $userId');

    final itemId = args['item_id'] as String?;
    final name = args['name'] as String?;

    if (itemId == null && name == null) {
      return {'success': false, 'error': 'Item ID or name is required'};
    }

    try {
      String? actualItemId = itemId;

      // If only name provided, find the item by name
      if (actualItemId == null && name != null) {
        final snapshot =
            await FirestoreService.firestore
                .collection('pantry_items')
                .where('userId', isEqualTo: userId)
                .where('name', isEqualTo: name)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          return {'success': false, 'error': 'Pantry item not found'};
        }

        actualItemId = snapshot.docs.first.id;
      }

      if (actualItemId == null) {
        return {'success': false, 'error': 'Could not find item'};
      }

      await PantryService.deletePantryItem(actualItemId);
      return {'success': true, 'message': 'Pantry item removed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _addToShoppingList(
    Map<String, dynamic> args,
  ) async {
    final userId = FirestoreService.currentUserId;
    if (userId == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    final items = args['items'] as List? ?? [];
    if (items.isEmpty) {
      return {'success': false, 'error': 'No items provided'};
    }

    try {
      for (final item in items) {
        final itemMap = item as Map<String, dynamic>;
        final shoppingItem = ShoppingItem(
          id: '', // Will be generated by Firestore
          name: itemMap['name'] ?? '',
          quantity: (itemMap['qty'] ?? 0).toDouble(),
          unit: itemMap['unit'] ?? '',
          category: itemMap['category'],
        );

        await ShoppingService.createShoppingItem(shoppingItem, userId);
      }

      return {'success': true, 'message': 'Items added to shopping list'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _nutritionEstimate(
    Map<String, dynamic> args,
  ) async {
    // Mock nutrition estimation
    final servings = args['servings'] as int? ?? 1;
    return {
      'success': true,
      'nutrition': {
        'calories': 300 * servings,
        'protein': 20 * servings,
        'carbs': 40 * servings,
        'fat': 10 * servings,
      },
      'note': 'Approximate values',
    };
  }

  Future<Map<String, dynamic>> _logMeal(Map<String, dynamic> args) async {
    final userId = FirestoreService.currentUserId;
    if (userId == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    try {
      // final recipeId = args['recipe_id'];
      // final servingSize = args['serving_size'] as String? ?? '1 serving';
      final when = args['when'] as String? ?? 'now';

      final meal = Meal(
        id: '',
        name: args['name'] ?? 'Meal',
        dateTime: DateTime.now(),
        calories: 300,
        protein: 20,
        carbs: 40,
        fat: 10,
        mealType: when,
      );

      await MealService.createMeal(meal, userId);
      return {'success': true, 'message': 'Meal logged'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

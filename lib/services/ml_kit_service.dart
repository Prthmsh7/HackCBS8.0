import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MlKitDetectionResult {
  final List<String> objects;
  final List<String> hazards;
  final List<String> labels;
  final String notes;

  MlKitDetectionResult({
    this.objects = const [],
    this.hazards = const [],
    this.labels = const [],
    this.notes = "",
  });

  Map<String, dynamic> toJson() => {
        "objects": objects,
        "hazards": hazards,
        "labels": labels,
        "notes": notes,
      };
}

class MlKitService {
  ObjectDetector? _objectDetector;
  ImageLabeler? _imageLabeler;
  bool _isInitialized = false;

  // Common kitchen objects and hazards
  static const List<String> kitchenObjects = [
    'pan',
    'pot',
    'knife',
    'cutting board',
    'bowl',
    'spoon',
    'fork',
    'plate',
    'garlic',
    'onion',
    'vegetable',
    'meat',
    'stove',
    'oven',
  ];

  static const List<String> hazards = [
    'knife',
    'steam',
    'smoke',
    'hot pan',
    'fire',
    'boiling water',
  ];

  Future<bool> initialize() async {
    if (_isInitialized) {
      print('✅ [ML KIT] Already initialized');
      return true;
    }

    try {
      print('🔍 [ML KIT] Initializing ML Kit object detector and image labeler...');
      
      // Create object detector options with better settings
      final objectOptions = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: objectOptions);
      
      // Create image labeler for better food/object recognition
      // Using higher confidence threshold to reduce false positives
      final labelerOptions = ImageLabelerOptions(
        confidenceThreshold: 0.5, // Higher threshold to reduce false positives (wine, cake, etc.)
      );
      _imageLabeler = ImageLabeler(options: labelerOptions);
      
      _isInitialized = true;
      print('✅ [ML KIT] ML Kit initialized successfully (Object Detection + Image Labeling)');
      return true;
    } catch (e, stackTrace) {
      print('❌ [ML KIT] Failed to initialize: $e');
      print('❌ [ML KIT] Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  Future<MlKitDetectionResult> detectObjects(String imagePath) async {
    print('🔍 [ML KIT] Starting object detection and labeling on: $imagePath');
    
    if (!_isInitialized || _objectDetector == null || _imageLabeler == null) {
      print('❌ [ML KIT] ML Kit not initialized');
      return MlKitDetectionResult(
        objects: [],
        hazards: [],
        labels: [],
        notes: "ML Kit not initialized - check initialization",
      );
    }

    try {
      print('🔍 [ML KIT] Creating InputImage from file path...');
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // Run both object detection and image labeling in parallel
      print('🔍 [ML KIT] Processing image with Object Detection and Image Labeling...');
      
      List<DetectedObject> objects = [];
      List<ImageLabel> labels = [];
      
      try {
        objects = await _objectDetector!.processImage(inputImage);
        print('✅ [ML KIT] Object detection completed');
      } catch (e) {
        print('⚠️ [ML KIT] Object detection failed: $e');
      }
      
      try {
        labels = await _imageLabeler!.processImage(inputImage);
        print('✅ [ML KIT] Image labeling completed');
      } catch (e) {
        print('⚠️ [ML KIT] Image labeling failed: $e');
      }
      
      print('🔍 [ML KIT] Object Detection returned ${objects.length} objects');
      print('🔍 [ML KIT] Image Labeling returned ${labels.length} labels');

      final detectedObjects = <String>[];
      final detectedLabels = <String>[];
      final detectedHazards = <String>[];

      // Process object detection results
      for (final object in objects) {
        print('🔍 [ML KIT] Object found with ${object.labels.length} labels');
        for (final label in object.labels) {
          final labelText = label.text.toLowerCase();
          final confidence = label.confidence;
          print('  - Object Label: $labelText (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
          
          // Higher threshold to reduce false positives
          if (confidence > 0.5) {
            detectedObjects.add(labelText);

            // Check if it's a hazard
            if (hazards.any((h) => labelText.contains(h.toLowerCase()))) {
              detectedHazards.add(labelText);
              print('⚠️ [ML KIT] Hazard detected: $labelText');
            }
          }
        }
      }

      // Process image labeling results (better for food detection)
      // Image labeling is much better at detecting food items than object detection
      for (final label in labels) {
        final labelText = label.label.toLowerCase();
        final confidence = label.confidence;
        print('  - Image Label: $labelText (confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
        
        // Higher threshold (0.5) to reduce false positives - only high-confidence detections
        if (confidence > 0.5) {
          // Add ALL labels to detectedLabels (not just food-related)
          if (!detectedLabels.contains(labelText)) {
            detectedLabels.add(labelText);
          }
          
          // Add to objects list for AI processing (prioritize food-related but include all)
          if (!detectedObjects.contains(labelText)) {
            detectedObjects.add(labelText);
          }
          
          // Check if it's a hazard
          if (hazards.any((h) => labelText.contains(h.toLowerCase()))) {
            detectedHazards.add(labelText);
            print('⚠️ [ML KIT] Hazard detected: $labelText');
          }
          
          // Log food-related items specifically
          if (_isFoodRelated(labelText)) {
            print('🍎 [ML KIT] Food item detected: $labelText');
          }
        } else {
          print('  - Skipping low confidence label: $labelText (${(confidence * 100).toStringAsFixed(1)}%)');
        }
      }

      // Combine all detections
      final allDetections = <String>{};
      allDetections.addAll(detectedObjects);
      allDetections.addAll(detectedLabels);
      
      String notes = "";
      if (detectedHazards.isNotEmpty) {
        notes = "Detected potential hazards: ${detectedHazards.join(', ')}. ";
      }
      
      if (allDetections.isNotEmpty) {
        notes += "Detected items: ${allDetections.join(', ')}";
        print('✅ [ML KIT] Detected ${allDetections.length} items: ${allDetections.join(", ")}');
      } else {
        notes = "No items detected with sufficient confidence. Image might be blurry, poorly lit, or items not clearly visible.";
        print('⚠️ [ML KIT] No items detected');
      }

      return MlKitDetectionResult(
        objects: allDetections.toList(),
        hazards: detectedHazards,
        labels: detectedLabels,
        notes: notes,
      );
    } catch (e, stackTrace) {
      print('❌ [ML KIT] Error processing image: $e');
      print('❌ [ML KIT] Stack trace: $stackTrace');
      return MlKitDetectionResult(
        objects: [],
        hazards: [],
        labels: [],
        notes: "Error processing image: $e",
      );
    }
  }
  
  // Check if a label is food-related
  bool _isFoodRelated(String label) {
    final foodKeywords = [
      // General food terms
      'food', 'fruit', 'vegetable', 'meat', 'poultry', 'seafood', 'grain', 'dairy', 'protein',
      // Specific fruits
      'apple', 'banana', 'orange', 'grape', 'strawberry', 'berry', 'mango', 'pineapple', 'watermelon',
      'lemon', 'lime', 'peach', 'pear', 'cherry', 'plum', 'kiwi', 'avocado',
      // Specific vegetables
      'tomato', 'potato', 'onion', 'garlic', 'carrot', 'broccoli', 'lettuce', 'spinach', 'cucumber',
      'pepper', 'bell pepper', 'mushroom', 'celery', 'cabbage', 'corn', 'pea', 'bean',
      // Meat and protein
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'tuna', 'turkey', 'lamb', 'bacon', 'sausage',
      'egg', 'tofu', 'tempeh',
      // Grains and carbs
      'bread', 'rice', 'pasta', 'noodle', 'spaghetti', 'wheat', 'flour', 'oats', 'quinoa', 'barley',
      // Dairy
      'cheese', 'milk', 'yogurt', 'butter', 'cream', 'sour cream', 'cottage cheese',
      // Cooking ingredients
      'oil', 'salt', 'pepper', 'sugar', 'honey', 'vinegar', 'soy sauce', 'sauce', 'spice', 'herb',
      'garlic', 'ginger', 'basil', 'oregano', 'thyme', 'rosemary', 'parsley', 'cilantro',
      // Prepared foods
      'soup', 'salad', 'sandwich', 'burger', 'pizza', 'pasta', 'stew', 'curry', 'stir fry',
      'sushi', 'taco', 'burrito', 'noodle soup', 'ramen',
      // Cooking and kitchen
      'ingredient', 'recipe', 'cooking', 'kitchen', 'dish', 'meal', 'breakfast', 'lunch', 'dinner', 'snack',
      'appetizer', 'dessert', 'beverage', 'drink',
      // Cooking states
      'raw', 'cooked', 'fried', 'baked', 'grilled', 'steamed', 'boiled', 'roasted',
    ];
    
    final lowerLabel = label.toLowerCase();
    return foodKeywords.any((keyword) => lowerLabel.contains(keyword.toLowerCase()));
  }

  // Placeholder method for when ML Kit is not available
  Future<MlKitDetectionResult> detectObjectsPlaceholder(String imagePath) async {
    // This is a placeholder that returns empty results
    // In a real implementation, you might use a simpler image analysis
    // or return mock data for testing
    return MlKitDetectionResult(
      objects: [],
      hazards: [],
      labels: [],
      notes: "Placeholder detection - ML Kit not available",
    );
  }

  Future<void> dispose() async {
    await _objectDetector?.close();
    await _imageLabeler?.close();
    _objectDetector = null;
    _imageLabeler = null;
    _isInitialized = false;
  }
}



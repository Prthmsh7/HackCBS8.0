import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import 'firestore_service.dart';

class RecipeService {
  static final CollectionReference _recipesCollection =
      FirestoreService.firestore.collection('recipes');

  /// Get all recipes (public - for community)
  static Stream<List<Recipe>> getAllRecipes() {
    return _recipesCollection
        .orderBy('calories', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  /// Get recipes by user
  static Stream<List<Recipe>> getUserRecipes(String userId) {
    return _recipesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('calories', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  /// Get a single recipe by ID
  static Future<Recipe?> getRecipeById(String recipeId) async {
    final doc = await _recipesCollection.doc(recipeId).get();
    if (doc.exists) {
      return Recipe.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    }
    return null;
  }

  /// Create a new recipe
  static Future<String> createRecipe(Recipe recipe, String userId) async {
    final recipeData = recipe.toJson();
    recipeData['userId'] = userId;
    recipeData['createdAt'] = FieldValue.serverTimestamp();
    
    final docRef = await _recipesCollection.add(recipeData);
    return docRef.id;
  }

  /// Update an existing recipe
  static Future<void> updateRecipe(String recipeId, Recipe recipe) async {
    final recipeData = recipe.toJson();
    recipeData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _recipesCollection.doc(recipeId).update(recipeData);
  }

  /// Delete a recipe
  static Future<void> deleteRecipe(String recipeId) async {
    await _recipesCollection.doc(recipeId).delete();
  }

  /// Search recipes by title or ingredients
  static Stream<List<Recipe>> searchRecipes(String query) {
    final lowerQuery = query.toLowerCase();
    return _recipesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Recipe.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .where((recipe) {
            final title = recipe.title.toLowerCase();
            final description = recipe.description.toLowerCase();
            final ingredients = recipe.ingredients
                .join(' ')
                .toLowerCase();
            return title.contains(lowerQuery) ||
                description.contains(lowerQuery) ||
                ingredients.contains(lowerQuery);
          })
          .toList();
    });
  }
}





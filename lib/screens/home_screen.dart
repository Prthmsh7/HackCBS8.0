import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/neomorphic_container.dart';
import '../widgets/voice_button.dart';
import '../widgets/search_bar.dart';
import '../models/recipe.dart';
import '../services/user_data_service.dart';
import '../controllers/voice_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final VoiceController _voiceController = VoiceController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _lastAlfredoResponse;

  final List<Recipe> _featuredRecipes = [
    Recipe(
      id: '1',
      title: 'Paneer Spinach Curry',
      description: 'A healthy, low-carb curry made with fresh spinach and paneer',
      ingredients: ['200g Spinach', '250g Paneer', '1 Onion', '2 Tomatoes', 'Spices'],
      instructions: [
        'Heat oil in a pan and sauté onions until golden',
        'Add tomatoes and cook until soft',
        'Add spices and spinach, cook for 5 minutes',
        'Add paneer cubes and simmer for 10 minutes',
        'Serve hot with roti or rice',
      ],
      calories: 320,
      protein: 18,
      carbs: 12,
      fat: 22,
      prepTime: 15,
      cookTime: 25,
    ),
    Recipe(
      id: '2',
      title: 'Banana Oats Smoothie',
      description: 'A nutritious breakfast smoothie with banana and oats',
      ingredients: ['2 Bananas', '50g Oats', '200ml Milk', '1 tbsp Honey', 'Ice cubes'],
      instructions: [
        'Blend oats until fine powder',
        'Add bananas, milk, and honey',
        'Blend until smooth',
        'Add ice and blend again',
        'Serve chilled',
      ],
      calories: 280,
      protein: 10,
      carbs: 45,
      fat: 8,
      prepTime: 5,
      cookTime: 0,
    ),
    Recipe(
      id: '3',
      title: 'Grilled Chicken Salad',
      description: 'Light and protein-rich salad perfect for lunch',
      ingredients: ['200g Chicken', 'Mixed Greens', 'Cherry Tomatoes', 'Cucumber', 'Dressing'],
      instructions: [
        'Marinate chicken with spices',
        'Grill chicken until cooked',
        'Slice and arrange on greens',
        'Add vegetables and dressing',
        'Serve immediately',
      ],
      calories: 350,
      protein: 35,
      carbs: 15,
      fat: 18,
      prepTime: 10,
      cookTime: 15,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _searchController.addListener(() {
      setState(() {});
    });
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceController.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice initialization failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleMicPress() async {
    try {
      // Toggle conversation on/off
      await _voiceController.toggleConversation();
      setState(() {}); // Update UI to reflect new state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getVoiceStatusText() {
    if (!_voiceController.isConversationActive) {
      return 'Tap to start conversation';
    }
    
    switch (_voiceController.state) {
      case VoiceState.idle:
        return 'Conversation active - Tap to stop';
      case VoiceState.listening:
        return 'Listening... (Tap to stop)';
      case VoiceState.processing:
        return 'Processing...';
      case VoiceState.speaking:
        return 'Alfredo is speaking...';
    }
  }

  Color _getVoiceStatusColor() {
    if (!_voiceController.isConversationActive) {
      return AppTheme.primaryOrange;
    }
    
    switch (_voiceController.state) {
      case VoiceState.idle:
        return Colors.green;
      case VoiceState.listening:
        return Colors.red;
      case VoiceState.processing:
        return Colors.blue;
      case VoiceState.speaking:
        return Colors.green;
    }
  }

  void _handleSearch() {
    if (_searchController.text.isNotEmpty) {
      // Handle search - can navigate to search results or filter recipes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: ${_searchController.text}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = UserDataService();
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Logo and Notification
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Alfredo Logo
                  Text(
                    'Alfredo',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                  // Notification Bell
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        color: AppTheme.gray700,
                        onPressed: () {
                          // Show notifications
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {});
                },
                color: AppTheme.primaryOrange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 250),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: NeomorphicContainer(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${userData.name.split(' ').first}! 👋',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ready to cook something amazing today?',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.gray600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Search Bar
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: SearchBarWidget(
                            controller: _searchController,
                            onTap: _handleSearch,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Voice Interface - Direct Voice Conversation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.7 + (0.3 * value),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Center(
                            child: Column(
                              children: [
                                VoiceButton(
                                  isListening: _voiceController.isListening,
                                  onTap: _handleMicPress,
                                  size: 100,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _getVoiceStatusText(),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: _getVoiceStatusColor(),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (_voiceController.state == VoiceState.idle)
                                  Text(
                                    'Voice-powered AI assistant',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.gray600,
                                        ),
                                  ),
                                // Visual indicator when Alfredo is speaking
                                if (_voiceController.isSpeaking)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.volume_up_rounded,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Alfredo is speaking...',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.green,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // AI Recipes Section
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 250),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'AI Recipes',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Generate new recipe
                                    },
                                    child: const Text('Generate New'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _featuredRecipes.length,
                                  itemBuilder: (context, index) {
                                    final recipe = _featuredRecipes[index];
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: Duration(milliseconds: 200 + (index * 50)),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.8 + (0.2 * value),
                                          child: Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 280,
                                        margin: const EdgeInsets.only(right: 16),
                                        child: NeomorphicContainer(
                                          padding: EdgeInsets.zero,
                                          onTap: () {
                                            _showRecipeDetails(recipe);
                                          },
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.restaurant_menu_rounded,
                                                    size: 48,
                                                    color: AppTheme.primaryOrange,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      recipe.title,
                                                      style: Theme.of(context).textTheme.titleMedium,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.local_fire_department_rounded,
                                                          size: 14,
                                                          color: AppTheme.primaryOrange,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${recipe.calories} cal',
                                                          style: Theme.of(context).textTheme.bodySmall,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Icon(
                                                          Icons.timer_rounded,
                                                          size: 14,
                                                          color: AppTheme.gray600,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${recipe.prepTime + recipe.cookTime} min',
                                                          style: Theme.of(context).textTheme.bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Quick Stats
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: NeomorphicContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${userData.calorieGoal}',
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                              color: AppTheme.primaryOrange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Cal Goal',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: NeomorphicContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        userData.bmi.toStringAsFixed(1),
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'BMI',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.gray600,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map((ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle_rounded,
                                size: 8,
                                color: AppTheme.primaryOrange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

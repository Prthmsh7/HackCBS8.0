import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/diet_nutrition_screen.dart';
import 'screens/community_screen.dart';
import 'screens/smart_pantry_screen.dart';
import 'screens/user_profile_screen.dart';

import 'screens/ai_call_screen.dart';
import 'providers/ai_call_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserDataService>(create: (_) => UserDataService()),
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()..initializeVoice()),
        ChangeNotifierProvider(create: (_) => AiCallProvider()),
      ],
      child: MaterialApp(
        title: 'Alfredo - AI Nutrition Assistant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DietNutritionScreen(),
    const CommunityScreen(),
    const SmartPantryScreen(),
    const UserProfileScreen(),
    const AiCallScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, -2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, Icons.home_rounded, 'Home', 0),
                _buildNavItem(context, Icons.analytics_rounded, 'Nutrition', 1),
                _buildNavItem(context, Icons.people_rounded, 'Community', 2),
                _buildNavItem(context, Icons.kitchen_rounded, 'Pantry', 3),
                _buildNavItem(context, Icons.person_rounded, 'Profile', 4),
                _buildNavItem(context, Icons.videocam_rounded, 'AI Call', 5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppTheme.primaryOrange.withValues(alpha: 0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryOrange : AppTheme.gray600,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? AppTheme.primaryOrange : AppTheme.gray600,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

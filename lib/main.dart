import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/shopkeeper/shopkeeper_dashboard_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/spring_auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/carbon_tracking_provider.dart';
import 'providers/store_provider.dart';
import 'providers/product_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/product_view_provider.dart';
import 'providers/eco_challenges_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/orders_provider.dart';
import 'config/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for web (Firestore only - no Auth)
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: FirebaseConfig.config['apiKey'] as String,
      authDomain: FirebaseConfig.config['authDomain'] as String,
      projectId: FirebaseConfig.config['projectId'] as String,
      storageBucket: FirebaseConfig.config['storageBucket'] as String,
      messagingSenderId: FirebaseConfig.config['messagingSenderId'] as String,
      appId: FirebaseConfig.config['appId'] as String,
      measurementId: FirebaseConfig.config['measurementId'] as String,
    ),
  );
  
  print('Firebase initialized for Firestore only (Auth disabled)');
  
  print('EcoBazaarX App starting with Spring Boot backend and Firebase...');
  
  runApp(const EcoBazaarXApp());
}

class EcoBazaarXApp extends StatelessWidget {
  const EcoBazaarXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
              providers: [
          ChangeNotifierProvider(create: (_) => SpringAuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CarbonTrackingProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ProductViewProvider()),
        ChangeNotifierProvider(create: (_) => EcoChallengesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: Consumer4<SettingsProvider, ProductProvider, StoreProvider, WishlistProvider>(
        builder: (context, settingsProvider, productProvider, storeProvider, wishlistProvider, child) {
          final isDarkMode = settingsProvider.darkModeEnabled;
          
          // Initialize products, stores, and wishlist when app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (productProvider.allProducts.isEmpty && !productProvider.isLoading) {
              productProvider.initializeProducts();
            }
            if (storeProvider.allStores.isEmpty && !storeProvider.isLoading) {
              storeProvider.initializeStores();
            }
            // Initialize wishlist for current user (if logged in)
            final authProvider = Provider.of<SpringAuthProvider>(context, listen: false);
            if (authProvider.isAuthenticated && authProvider.userId != null && wishlistProvider.wishlistItems.isEmpty && !wishlistProvider.isLoading) {
              wishlistProvider.initializeWishlist(authProvider.userId!);
            }
            // Initialize settings for current user (if logged in)
            if (authProvider.isAuthenticated && authProvider.userId != null) {
              settingsProvider.refreshSettings();
            }
          });
          
          return MaterialApp(
            title: 'EcoBazaarX',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              fontFamily: 'Roboto', // Use a standard font
              scaffoldBackgroundColor: isDarkMode 
                ? const Color(0xFF1A1A1A) 
                : const Color(0xFFF8FAFF),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2196F3),
                elevation: 0,
                centerTitle: true,
                systemOverlayStyle: null,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3).withOpacity(0.9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
                filled: true,
                fillColor: isDarkMode 
                  ? Colors.grey[800]!.withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600], 
                  fontSize: 14
                ),
              ),
              textTheme: TextTheme(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                ),
                headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                ),
                bodyLarge: TextStyle(
                  fontSize: 16, 
                  color: isDarkMode ? Colors.grey[300] : const Color(0xFF424242)
                ),
                bodyMedium: TextStyle(
                  fontSize: 14, 
                  color: isDarkMode ? Colors.grey[400] : const Color(0xFF757575)
                ),
              ),
              cardTheme: CardThemeData(
                color: isDarkMode 
                  ? Colors.grey[800]!.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const HomeScreen(),
              '/admin': (context) => const AdminDashboardScreen(),
              '/shopkeeper': (context) => const ShopkeeperDashboardScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

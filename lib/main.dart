// lib/main.dart - Version avec gestion du ThemeMode (Mode Sombre)

import 'package:flutter/material.dart';
// Note : J'ai retiré les imports non définis ici (AppConstants, AppColors, AppTheme, AppStrings)
// en supposant qu'ils sont définis dans les fichiers 'metric_card.dart' ou 'theme/app_theme.dart'

import 'pages/home_page.dart';
import 'pages/add_patient.dart';
import 'pages/statistics_page.dart';
import 'pages/SponsorPage.dart';
import 'pages/login_page.dart';
import 'pages/profil_page.dart'; // Import de la vraie page de profil
import 'services/auth_service.dart';
import 'services/settings_service.dart'; // ✅ Nécessaire pour charger/sauvegarder le thème
import 'widgets/metric_card.dart';

// ----------------------------------------------------------------------
// INITIALISATION ET WIDGET RACINE
// ----------------------------------------------------------------------

void main() async {
  // 1. Initialiser Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Charger les paramètres (pour restaurer le mode sombre si défini)
  // Assurez-vous que SettingsService a une méthode loadSettings() et getDarkMode()
  await SettingsService.instance.loadSettings();
  
  // 3. Le widget racine gère maintenant le thème
  runApp(const ThemeWrapper());
}

// ----------------------------------------------------------------------
// 💡 WIDGET DE GESTION DU THÈME (Remplace l'ancienne PlaidoyerSanteApp)
// ----------------------------------------------------------------------

class ThemeWrapper extends StatefulWidget {
  const ThemeWrapper({super.key});

  // Méthode statique pour obtenir l'état et déclencher la reconstruction (appelée par la ProfilePage)
  static _ThemeWrapperState of(BuildContext context) =>
      context.findAncestorStateOfType<_ThemeWrapperState>()!;

  @override
  State<ThemeWrapper> createState() => _ThemeWrapperState();
}

class _ThemeWrapperState extends State<ThemeWrapper> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  Future<void> _loadThemeSetting() async {
    // Supposons que SettingsService.getDarkMode() retourne un Future<bool>
    final bool isDarkMode = await SettingsService.instance.getDarkMode();
    if (mounted) {
      setState(() {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }
  
  // 🎯 Méthode publique pour changer le thème (utilisée dans ProfilePage)
  void setMode(bool isDarkMode) {
    // 1. Sauvegarde le paramètre
    SettingsService.instance.setDarkMode(isDarkMode); 
    
    // 2. Met à jour l'état et force la reconstruction
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Les classes AppConstants, AppTheme sont supposées accessibles.
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // ✅ Configuration Cruciale du Mode Sombre :
      theme: AppTheme.lightTheme, 
      darkTheme: AppTheme.darkTheme, 
      themeMode: _themeMode, // ⬅️ L'état du thème

      // L'écran de démarrage est la vérification d'authentification
      home: const AuthCheck(), 

      // Configuration des routes (inchangée)
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainNavigation(),
        '/add-patient': (context) => const AddPatientPage(),
        // '/ai-chat': (context) => const AIChatPage(),
      },
    );
  }
}

// ----------------------------------------------------------------------
// LOGIQUE D'AUTHENTIFICATION AU DÉMARRAGE (AuthCheck)
// ----------------------------------------------------------------------

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoggedIn = false;
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); 
  }

  Future<void> _checkLoginStatus() async {
    final authService = AuthService.instance;
    final isLoggedIn = authService.isLoggedIn(); 

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 IMPORTANT : Utiliser Theme.of(context) pour s'adapter au thème clair/sombre
    final theme = Theme.of(context);
    
    if (_isLoading) {
      // Écran de chargement avec le logo de l'app
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Adapté au thème
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo médical
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.primaryColor, // Adapté au thème
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 70,
                  color: theme.colorScheme.onPrimary, // Texte sur couleur primaire
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(color: theme.primaryColor), // Adapté au thème
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor, // Adapté au thème
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si connecté → App principale, sinon → Page de connexion
    return _isLoggedIn ? const MainNavigation() : const LoginPage();
  }
}

// ----------------------------------------------------------------------
// NAVIGATION PRINCIPALE (MainNavigation)
// ----------------------------------------------------------------------

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomePage(), 
    const StatisticsPage(),
    const SponsorPage(),
    const ProfilePage(), // ✅ Vraie page de profil
  ];

  @override
  Widget build(BuildContext context) {
    // Récupérer les couleurs du thème (qui incluent celles du BottomNavigationBar)
    final theme = Theme.of(context); 
    
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // 💡 CONSEIL : Laissez le thème global (AppTheme) gérer ces couleurs.
        // Si vous les laissez en AppColors.xxx en dur, elles ne changeront pas en mode sombre.
        // Si AppTheme est correctement configuré, vous pouvez souvent omettre ces lignes.
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor, // Utilisez le thème
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor, // Utilisez le thème
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor, // Utilisez le thème
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: AppStrings.statistics,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: AppStrings.sponsors,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
        ],
      ),

      // Bouton flottant (visible seulement sur la page d'accueil)
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPatientPage(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              backgroundColor: theme.primaryColor, // Adapté au thème
              foregroundColor: theme.colorScheme.onPrimary, // Adapté au thème
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
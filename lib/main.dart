// lib/main.dart

import 'package:flutter/material.dart';
// import 'utils/constants.dart';
import 'pages/home_page.dart';
// import 'theme/app_theme.dart';
// import 'theme/app_colors.dart';
import 'widgets/placeholder_page.dart'; // Nouveau widget
import 'widgets/metric_card.dart';
import 'pages/add_patient.dart';
import 'pages/statistics_page.dart';
import 'services/ai_chat_service.dart';
import 'pages/ai_chat_page.dart';

//  import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// You import sqflite_common_ffi to initialize the database engine for your platform.
//This is the part that fixes the Bad state: databaseFactory not initialized error.
// import 'package:sqflite/sqflite.dart';
// You import sqflite because that's where the actual database commands (openDatabase, etc.)
// are defined. Without it, your code won't recognize those functions.

void main() {
  // Add this line to initialize the database factory for ffi
  //  sqfliteFfiInit(); // This is the recommended way now

  // You can set the database factory globally
  //  databaseFactory = databaseFactoryFfi;

  // or, if you're using the older method:
  // databaseFactory = databaseFactoryFfi;
  runApp(const PlaidoyerSanteApp());
}

class PlaidoyerSanteApp extends StatelessWidget {
  const PlaidoyerSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Configuration de la navigation
      routes: {
        '/': (context) => const MainNavigation(),
        '/patients': (context) => PlaceholderPage(
          title: 'Détail du Patient',
          icon: Icons.medical_information_rounded,
          mainText: 'Détail du patient',
          subtitle: 'À développer avec SQLite',
        ),
        '/add-patient': (context) => const AddPatientPage(),
      },
    );
  }
}

// Classe pour la navigation bottom - SEULE RESPONSABLE DE LA NAVIGATION
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  // mémoriser quel onglet est actuellement sélectionné dans votre barre de navigation en bas.

  final List<Widget> _pages = [
    const HomePage(), // ← Plus de gestion de navigation ici
    const StatisticsPage(),
    const SponsorsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.home, // ✅ Corrigé
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

      // Bouton flottant global
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
                  setState(
                    () {},
                  ); // Force le rebuild, HomePage va recharger les données
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

//  MISE À JOUR DES PAGES : UTILISATION DE LA VRAIE PAGE
// // Renommée pour éviter le conflit avec la classe StatisticsPage de votre fichier statistics_page.dart
class ActualStatisticsPage extends StatelessWidget {
  const ActualStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Retourne la page implémentée dans lib/pages/statistics_page.dart
    return const StatisticsPage();
  }
}

class SponsorsPage extends StatelessWidget {
  const SponsorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: AppStrings.sponsors,
      icon: Icons.people_rounded,
      mainText: 'Page des Sponsors',
      subtitle: 'Partenaires et contributeurs',
      showAppBar: true,
      action: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalité bientôt disponible!')),
          );
        },
        child: const Text('Voir les sponsors'),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false, // Pas de bouton retour
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.person_rounded,
                size: 50,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              'Dr. Exemple',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Oncologue',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                // Action de déconnexion ou paramètres
              },
              icon: const Icon(Icons.settings),
              label: const Text('Paramètres'),
            ),
          ],
        ),
      ),
    );
  }
}

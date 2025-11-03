// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'register_page.dart';
import '../widgets/metric_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fonctions de validation (inchangées)
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    if (value.trim().length < 3) {
      return 'Au moins 3 caractères requis';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Au moins 6 caractères requis';
    }
    return null;
  }

  // Navigation vers l'inscription (inchangée)
  void _goToRegisterPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );

    if (mounted && result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Compte créé ! Veuillez vous connecter."),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Connexion (inchangée)
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService.instance;
      final result = await authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Récupération des couleurs de vos constantes pour uniformité
    const Color overlayColor = AppColors.background; 

    return Scaffold(
      // 🚀 NOUVEAU : Container pour l'image de fond et l'overlay
      body: Container(
        decoration: BoxDecoration(
          // 1. Image de fond
          image: DecorationImage(
            // ⚠️ Assurez-vous que le chemin est correct !
            image: const AssetImage('assets/images/marcelo-leal-k7ll1hpdhFA-unsplash.jpg'),
            fit: BoxFit.cover,
            // 2. Filtre de couleur pour l'éclaircir et le lier à votre thème
            colorFilter: ColorFilter.mode(
              overlayColor.withOpacity(0.85), // Utilise la couleur de fond de l'app
              BlendMode.screen, // 'screen' ou 'lighten' donne un bon effet
            ),
          ),
        ),
        // 3. Container pour l'overlay de dégradé (optionnel, pour plus de lisibilité)
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                overlayColor.withOpacity(0.9),
                Colors.white.withOpacity(0.95), // Rend le centre plus clair
                overlayColor.withOpacity(0.9),
              ],
            ),
          ),
          // 4. Contenu de la page
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingXL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Logo/Icône de l'app ---
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 60,
                          color: AppColors.textOnPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingXL),

                      // --- Titre ---
                      Text(
                        'Plaidoyer Santé', // Utiliser AppConstants.appName si vous l'avez
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingS),

                      // --- Sous-titre ---
                      Text(
                        'Ensemble, donnons espoir et santé', // Utiliser AppConstants.appSlogan si vous l'avez
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingXL * 2),

                      // --- Carte de connexion ---
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingXL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Connexion',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: AppSizes.paddingXL),

                              // Champ nom d'utilisateur
                              TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Nom d\'utilisateur',
                                  hintText: 'Entrez votre nom d\'utilisateur',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                validator: _validateUsername,
                                enabled: !_isLoading,
                              ),

                              const SizedBox(height: AppSizes.paddingL),

                              // Champ mot de passe
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  hintText: 'Entrez votre mot de passe',
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                validator: _validatePassword,
                                enabled: !_isLoading,
                                onFieldSubmitted: (_) => _login(),
                              ),

                              const SizedBox(height: AppSizes.paddingXL),

                              // Bouton de connexion
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.primary, // Couleur principale
                                  foregroundColor: AppColors.textOnPrimary, // Texte blanc/clair
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.textOnPrimary,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),

                              const SizedBox(height: AppSizes.paddingM),

                              // Bouton pour l'inscription
                              TextButton(
                                onPressed: _isLoading ? null : _goToRegisterPage,
                                child: Text(
                                  "Pas encore de compte ? S'enregistrer",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary, // Couleur principale
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSizes.paddingXL),

                      // Info compte par défaut (inchangé)
                      Container(
                        padding: const EdgeInsets.all(AppSizes.paddingL),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.info,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.paddingS),
                                Text(
                                  'Compte par défaut',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.paddingS),
                            Text(
                              'Utilisateur: admin\nMot de passe: admin123',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
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
        ),
      ),
    );
  }
}
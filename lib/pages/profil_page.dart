// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'dart:io'; // Nécessaire pour FileImage
import '../widgets/metric_card.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final user = authService.currentUser;

    // ... (Code de l'AppBar et de la vérification 'user == null' inchangé) ...
    // ...

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: user == null
          ? const Center(
              // ... (Contenu si aucun utilisateur connecté) ...
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text('Aucun utilisateur connecté'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // --- AVATAR AVEC IMAGE DE PROFIL OU INITIALES ---
                  Hero(
                    tag: 'user-avatar',
                    child: CircleAvatar( // Utilisation de CircleAvatar pour simplifier
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      
                      // LOGIQUE CLÉ : Vérifier si profileImageUrl existe
                      backgroundImage: user.profileImageUrl != null
                          // Si le chemin existe, utiliser FileImage (pour une image locale)
                          ? FileImage(File(user.profileImageUrl!))
                          : null,
                          
                      // Afficher les initiales UNIQUEMENT si l'image n'existe pas
                      child: user.profileImageUrl == null
                          ? Text(
                              user.initials,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // L'ancien Container avec la décoration BoxShadow et le LinearGradient
                  // est remplacé par un simple CircleAvatar pour mieux gérer l'image.
                  // Si vous souhaitez conserver la décoration complexe, 
                  // vous devrez l'appliquer au CircleAvatar lui-même ou le contenir.

                  const SizedBox(height: 16),

                  // ... (Le reste de votre code ProfilePage est inchangé) ...
                  // ... Nom complet, Badge de rôle, Carte informations, Actions ...
                ],
              ),
            ),
    );
  }

  // ... (Les autres méthodes _buildInfoTile, _formatDate, _getRoleIcon, _showLogoutDialog restent inchangées) ...

  // Widget pour afficher une ligne d'information
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    // ... (Implémentation de _buildInfoTile) ...
    throw UnimplementedError(); // Placeholder pour le reste du code
  }
  
  // Formater une date
  String _formatDate(DateTime date) {
    // ... (Implémentation de _formatDate) ...
    throw UnimplementedError();
  }

  // Obtenir l'icône du rôle
  IconData _getRoleIcon(String role) {
    // ... (Implémentation de _getRoleIcon) ...
    throw UnimplementedError();
  }

  // Dialogue de confirmation de déconnexion
// 🚨 CORRECTION À APPORTER À CETTE MÉTHODE :
  Future<void> _showLogoutDialog(BuildContext context) async {
    final authService = AuthService.instance;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Annuler
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirmer
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    // 1. L'utilisateur a confirmé la déconnexion
    if (shouldLogout == true) {
      // Afficher un indicateur de chargement (Optionnel mais recommandé)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 2. Appel de la fonction de déconnexion (qui doit nettoyer le token)
      await authService.logout();

      // S'assurer que le widget est toujours monté
      if (context.mounted) {
        // 3. Fermer l'indicateur de chargement
        Navigator.of(context).pop();

        // 4. Navigation vers la page de connexion
        // Ceci est la partie CRITIQUE : on utilise pushAndRemoveUntil
        // pour retirer toutes les pages (y compris le Home) de la pile.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // Retourne false pour toutes les routes
        );
      }
    }
  }
}
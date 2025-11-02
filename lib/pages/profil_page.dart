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
  Future<void> _showLogoutDialog(BuildContext context) async {
    // ... (Implémentation de _showLogoutDialog) ...
    throw UnimplementedError();
  }
}
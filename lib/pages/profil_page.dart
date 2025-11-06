// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import '../utils/constants.dart';
// import '../theme/app_colors.dart';
import '../widgets/metric_card.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Charger l'image de profil sauvegardée
  void _loadProfileImage() {
    final user = AuthService.instance.currentUser;
    if (user?.profileImageUrl != null) {
      setState(() {
        _profileImagePath = user!.profileImageUrl;
      });
    }
  }

  // Afficher le menu de sélection de photo
  Future<void> _showImageSourceMenu() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.info),
              ),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: AppColors.error),
                ),
                title: const Text('Supprimer la photo'),
                onTap: () {
                  Navigator.pop(context, null);
                  _deleteProfileImage();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      _pickImage(source);
    }
  }

  // Sélectionner une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });

        // TODO: Sauvegarder le chemin dans la base de données
        // await AuthService.instance.updateProfileImage(image.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Photo de profil mise à jour'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Supprimer la photo de profil
  Future<void> _deleteProfileImage() async {
    setState(() {
      _profileImagePath = null;
    });

    // TODO: Supprimer de la base de données
    // await AuthService.instance.deleteProfileImage();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Photo de profil supprimée'),
          backgroundColor: AppColors.info,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.logout_rounded),
          //   onPressed: () => _showLogoutDialog(context),
          //   tooltip: 'Se déconnecter',
          // ),
        ],
      ),
      body: user == null
          ? _buildNoUserView()
          : _buildProfileView(user),
    );
  }

  // ========================================================================
  // VUE : AUCUN UTILISATEUR CONNECTÉ
  // ========================================================================
  Widget _buildNoUserView() {
    return const Center(
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
    );
  }

  // ========================================================================
  // VUE : PROFIL DE L'UTILISATEUR
  // ========================================================================
  Widget _buildProfileView(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ============ SECTION AVATAR ============
          _buildAvatarSection(user),

          const SizedBox(height: 24),

          // ============ SECTION INFORMATIONS PERSONNELLES ============
          _buildPersonalInfoSection(user),

          const SizedBox(height: 16),

          // ============ SECTION DÉTAILS DU COMPTE ============
          _buildAccountDetailsSection(user),

          const SizedBox(height: 16),

          // ============ SECTION ACTIONS ============
          _buildActionsSection(),

          const SizedBox(height: 24),

          // ============ BOUTON DÉCONNEXION ============
          _buildLogoutButton(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ========================================================================
  // SECTION : AVATAR AVEC PHOTO DE PROFIL
  // ========================================================================
  Widget _buildAvatarSection(user) {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar principal
            Hero(
              tag: 'user-avatar',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _profileImagePath == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: _profileImagePath != null
                      ? DecorationImage(
                          image: FileImage(File(_profileImagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profileImagePath == null
                    ? Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),

            // Bouton pour modifier la photo
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImageSourceMenu,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================================
  // SECTION : INFORMATIONS PERSONNELLES
  // ========================================================================
  Widget _buildPersonalInfoSection(user) {
    return Column(
      children: [
        // Nom complet
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        // Badge de rôle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRoleIcon(user.role),
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                user.roleLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Spécialisation
        if (user.specialization != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.specialization!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ========================================================================
  // SECTION : DÉTAILS DU COMPTE
  // ========================================================================
  Widget _buildAccountDetailsSection(user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.account_circle_outlined,
            title: 'Nom d\'utilisateur',
            subtitle: user.username,
            color: AppColors.primary,
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.calendar_today_outlined,
            title: 'Membre depuis',
            subtitle: _formatDate(user.createdAt),
            color: AppColors.success,
          ),
          if (user.lastLogin != null) ...[
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.login_outlined,
              title: 'Dernière connexion',
              subtitle: _formatDate(user.lastLogin!),
              color: AppColors.info,
            ),
          ],
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.verified_user_outlined,
            title: 'Statut du compte',
            subtitle: user.isActive ? 'Actif' : 'Inactif',
            color: user.isActive ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SECTION : ACTIONS
  // ========================================================================
  Widget _buildActionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.edit_outlined,
            title: 'Modifier le profil',
            subtitle: 'Changer nom, spécialisation',
            color: AppColors.primary,
            onTap: () {
              // TODO: Navigation vers page d'édition
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Modification du profil - Bientôt disponible'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.lock_reset_rounded,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe',
            color: AppColors.warning,
            onTap: () {
              // TODO: Navigation vers changement de mot de passe
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Changement de mot de passe - Bientôt disponible'),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // _buildActionTile(
          //   icon: Icons.settings_outlined,
          //   title: 'Paramètres',
          //   subtitle: 'Configurer l\'application',
          //   color: AppColors.info,
          //   onTap: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //         content: Text('Paramètres - Bientôt disponible'),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  // ========================================================================
  // BOUTON : DÉCONNEXION
  // ========================================================================
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Se déconnecter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ========================================================================
  // WIDGETS UTILITAIRES
  // ========================================================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ========================================================================
  // FONCTIONS UTILITAIRES
  // ========================================================================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'nurse':
        return Icons.local_hospital_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  // ========================================================================
  // DIALOGUE : DÉCONNEXION
  // ========================================================================

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de l\'application ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Afficher le chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await AuthService.instance.logout();

      if (mounted) {
        Navigator.of(context).pop(); // Fermer le chargement
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}
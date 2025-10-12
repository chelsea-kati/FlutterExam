// lib/pages/patient_detail_page.dart

import 'package:flutter/material.dart';
import '../models/patient.dart'; // Assurez-vous d'importer votre modèle Patient
// import '../utils/constants.dart' as constants; // Pour les couleurs et tailles
import '../widgets/metric_card.dart';
import '../models/Conseil.dart'; // 1. Import du modèle Conseil
import '../services/db_service.dart'; // 2. Import du service DB

// Définition des constantes pour les couleurs et tailles (pour l'exemple)
// class AppColors {
//   static const Color primary = Colors.blue;
//   static const Color textPrimary = Colors.black;
//   static const Color textSecondary = Colors.grey;
//   static const Color background = Color(0xFFF5F5F5);
// }

// class AppSizes {
//   static const double paddingS = 8.0;
//   static const double paddingM = 12.0;
//   static const double paddingL = 16.0;
//   static const double paddingXL = 24.0;
// }

// 1. CHANGEMENT EN STATEFULWIDGET
// ----------------------------------------------------

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({Key? key, required this.patient}) : super(key: key);

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  Conseil? _conseil;
  bool _isLoadingAdvice = true;

  @override
  void initState() {
    super.initState();
    _loadConseil(); // 3. Lancer le chargement asynchrone
  }

  // 4. Méthode pour charger le conseil depuis la DB
  Future<void> _loadConseil() async {
    // Si l'état n'est pas monté, on arrête (sécurité)
    if (!mounted) return;

    setState(() {
      _isLoadingAdvice = true;
    });

    // Appel au service pour récupérer le conseil basé sur la maladie du patient
    final conseil = await DatabaseService.instance.getConseilByMaladie(
      widget.patient.maladie,
    );

    if (mounted) {
      setState(() {
        _conseil = conseil;
        _isLoadingAdvice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.patient.nomComplet),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSizes.paddingXL),
            _buildInfoCard(context),
            const SizedBox(height: AppSizes.paddingXL), // Espace augmenté
            // 5. Remplacement de l'ancienne section "Conseils Médicaux"
            _buildSectionTitle(context, 'Conseils Médicaux Spécifiques'),
            _buildConseilSection(context),

            const SizedBox(height: AppSizes.paddingL),
            // Remplacer l'ancienne section Notes (si elle existe toujours) par une section Visites/Notes
            _buildSectionTitle(context, 'Notes et Suivi (Visites)'),
            _buildNotesCard(
              context,
            ), // Garder cette carte pour les notes/conseils saisis par l'utilisateur
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // NOUVELLES ET MODIFIÉES SECTIONS
  // ----------------------------------------------------

  // 6. Nouvelle méthode pour afficher la logique de chargement/affichage du Conseil
  Widget _buildConseilSection(BuildContext context) {
    if (_isLoadingAdvice) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.paddingL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_conseil != null) {
      return AdviceCard(conseil: _conseil!);
    } else {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Text(
            'Aucun conseil général trouvé pour la maladie "${widget.patient.maladie}".',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
  }

  // Widget pour les notes (maintenant séparé des conseils médicaux)
  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Text(
          widget.patient.conseils ??
              "Aucune note de suivi (conseils manuels) disponible.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // WIDGETS HELPER (basés sur le code original, adaptés à l'état)
  // ----------------------------------------------------

  // Utilisation de widget.patient au lieu de patient
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.patient.nomComplet,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingS),
        Chip(
          label: Text(
            widget.patient.maladie,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ],
    );
  }

  // Utilisation de widget.patient au lieu de patient
  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              icon: Icons.cake_rounded,
              label: 'Âge',
              value: '${widget.patient.age} ans',
            ),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.location_on_rounded,
              label: 'Pays',
              value: widget.patient.pays,
            ),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Création du dossier',
              value: _formatDate(widget.patient.dateCreation),
            ),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.monitor_heart_rounded,
              label: 'Statut de suivi',
              value: widget.patient.statut,
              valueColor: _getStatusColor(widget.patient.statut),
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour construire une ligne d'information (inchangé)
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    // ... (Logique inchangée)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSizes.paddingM),
          Text(
            '$label:',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: valueColor ?? AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour les titres de section (inchangé)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // Helper pour formater la date (inchangé)
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Helper pour obtenir la couleur du statut (inchangé)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'nouveau':
      case 'récent':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      case 'a revoir':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ----------------------------------------------------
// NOUVEAU WIDGET : AdviceCard
// ----------------------------------------------------

class AdviceCard extends StatelessWidget {
  final Conseil conseil;
  const AdviceCard({super.key, required this.conseil});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      // Utilisation d'une couleur d'arrière-plan douce pour les conseils
      color: AppColors.tealCard.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: AppSizes.paddingL),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingS),
                Expanded(
                  child: Text(
                    conseil.titre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSizes.paddingL),
            Text(
              conseil.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (conseil.source != null && conseil.source!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.paddingM),
                child: Text(
                  'Source: ${conseil.source}',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

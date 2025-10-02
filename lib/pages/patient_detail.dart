// lib/pages/patient_detail_page.dart

import 'package:flutter/material.dart';
import '../models/patient.dart'; // Assurez-vous d'importer votre modèle Patient
// import '../utils/constants.dart' as constants; // Pour les couleurs et tailles
import '../widgets/metric_card.dart';

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

class PatientDetailPage extends StatelessWidget {
  final Patient patient;

  const PatientDetailPage({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(patient.nomComplet), // Utilisation de nomComplet
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
            const SizedBox(height: AppSizes.paddingL),
            _buildSectionTitle(context, 'Conseils Médicaux'),
            _buildNotesCard(context),
          ],
        ),
      ),
    );
  }

  // Widget pour l'en-tête avec le nom et la maladie
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient.nomComplet, // Correction : utilisation de nomComplet
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSizes.paddingS),
        Chip(
          label: Text(
            patient.maladie, // Correction : utilisation de maladie
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

  // Widget pour la carte d'informations générales
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
              value: '${patient.age} ans', // Correction : utilisation de l'âge
            ),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.location_on_rounded,
              label: 'Pays',
              value: patient.pays, // Correction : utilisation du pays
            ),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Création du dossier',
              value: _formatDate(patient.dateCreation), // Correction : utilisation de dateCreation
            ),
            const Divider(),
            _buildInfoRow(
              context,
              icon: Icons.monitor_heart_rounded,
              label: 'Statut de suivi',
              value: patient.statut, // Correction : utilisation de statut
              valueColor: _getStatusColor(patient.statut),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les notes
  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Text(
          patient.conseils ?? "Aucun conseil disponible pour ce patient.", // Correction : utilisation de conseils
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // Helper pour construire une ligne d'information
  Widget _buildInfoRow(BuildContext context, {required IconData icon, required String label, required String value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSizes.paddingM),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: valueColor ?? AppColors.textSecondary,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour les titres de section
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Helper pour formater la date
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Helper pour obtenir la couleur du statut
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
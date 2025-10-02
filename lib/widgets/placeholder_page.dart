// lib/widgets/placeholder_page.dart

import 'package:flutter/material.dart';
// import '../theme/app_colors.dart';
// import '../utils/constants.dart';
import '../widgets/metric_card.dart';


/// Widget réutilisable pour les pages temporaires/placeholder
/// Évite la duplication de code pour les pages en développement
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String mainText;
  final String? subtitle;
  final Widget? action;
  final bool showAppBar;
  final Color? iconColor;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.mainText,
    this.subtitle,
    this.action,
    this.showAppBar = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              automaticallyImplyLeading: Navigator.canPop(context),
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône principale
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppSizes.paddingL),
              
              // Titre principal
              Text(
                mainText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Sous-titre optionnel
              if (subtitle != null) ...[
                const SizedBox(height: AppSizes.paddingS),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              
              // Action optionnelle (bouton, etc.)
              if (action != null) ...[
                const SizedBox(height: AppSizes.paddingL),
                action!,
              ],
              
              // Message de développement
              const SizedBox(height: AppSizes.paddingXL),
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'En développement',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Variante spécialisée pour les pages de détail patient
class PatientDetailPlaceholder extends PlaceholderPage {
  const PatientDetailPlaceholder({super.key})
      : super(
          title: 'Détail du Patient',
          icon: Icons.medical_information_rounded,
          mainText: 'Fiche Patient Complète',
          subtitle: 'Historique, traitements, et suivi détaillé',
          iconColor: Colors.blue,
        );
}

/// Variante spécialisée pour l'ajout de patient
class AddPatientPlaceholder extends PlaceholderPage {
  AddPatientPlaceholder({super.key})
      : super(
          title: 'Ajouter un Patient',
          icon: Icons.person_add_rounded,
          mainText: 'Nouveau Patient',
          subtitle: 'Formulaire d\'inscription et dossier médical',
          iconColor: Colors.green,
          action: ElevatedButton.icon(
            onPressed: () {
              // TODO: Ouvrir le formulaire
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Commencer l\'ajout'),
          ),
        );
}
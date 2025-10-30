// lib/services/sponsor_service.dart (MISE À JOUR)

import '../models/sponsor.dart';

class SponsorService {
  SponsorService._privateConstructor();
  static final SponsorService instance = SponsorService._privateConstructor();

  final List<Sponsor> _mockSponsors = [
    Sponsor(
      id: 1,
      name: 'Santé Plus (Maladie A)',
      imageUrl: 'assets/images/logo_sante_plus.png',
      description: 'Leader en solutions de santé numérique pour l\'Afrique de l\'Est.',
      websiteUrl: 'https://santeplus.org',
      targetDisease: 'Paludisme', // AJOUTÉ
      targetCountry: 'Burundi',   // AJOUTÉ
    ),
    Sponsor(
      id: 2,
      name: 'Global Aid (Maladie B)',
      imageUrl: 'assets/images/logo_global_aid.png',
      description: 'Financement de projets humanitaires pour les régions touchées par les maladies.',
      websiteUrl: 'https://globalaid.org',
      targetDisease: 'Choléra',    // AJOUTÉ
      targetCountry: 'Rwanda',    // AJOUTÉ
    ),
    Sponsor(
      id: 3,
      name: 'Tech for Health (Maladie C)',
      imageUrl: 'assets/images/logo_tech_health.png',
      description: 'Fournisseur de solutions technologiques pour le suivi des patients.',
      websiteUrl: 'https://techforhealth.net',
      targetDisease: 'COVID-19', // AJOUTÉ
      targetCountry: 'RDC',      // AJOUTÉ
    ),
  ];

  Future<List<Sponsor>> getSponsors() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSponsors;
  }
}
// lib/models/sponsor.dart (MISE À JOUR)

class Sponsor {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final String websiteUrl;
  
  // ✅ NOUVEAUX CHAMPS POUR L'OBJECTIF
  final String targetDisease; 
  final String targetCountry; 

  Sponsor({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.websiteUrl,
    required this.targetDisease, // AJOUTÉ
    required this.targetCountry, // AJOUTÉ
  });

  // ... (Factory fromMap si nécessaire)
}
// lib/models/sponsor.dart (MISE À JOUR)

class Sponsor {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final String websiteUrl;
  
  final String targetDisease; 
  final String targetCountry; 

  Sponsor({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.websiteUrl,
    required this.targetDisease,
    required this.targetCountry,
  });

  // ------------------------------------------------------------------
  // ✅ CORRECTION : AJOUT OU MISE À JOUR DE LA FACTORY fromMap
  // ------------------------------------------------------------------
  factory Sponsor.fromMap(Map<String, dynamic> map) {
    // 💡 S'assurer que 'name' et tous les autres champs requis sont présents
    return Sponsor(
      id: map['id'] as int,
      name: map['name'] as String, // 👈 Le paramètre 'name' est maintenant fourni
      imageUrl: map['logoUrl'] as String, // Utilise le nom de colonne DB 'logoUrl'
      description: map['description'] as String? ?? '', // Gestion du null
      websiteUrl: map['siteWeb'] as String, // Utilise le nom de colonne DB 'siteWeb'
      targetDisease: map['targetDisease'] as String? ?? 'Inconnu',
      targetCountry: map['targetCountry'] as String? ?? 'Global',
    );
  }

  // ------------------------------------------------------------------
  // 💡 AJOUT : La méthode toMap (si vous utilisez le DB Service)
  // ------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': name, // Utilise le nom de colonne DB 'nom'
      'logoUrl': imageUrl,
      'description': description,
      'siteWeb': websiteUrl,
      'targetDisease': targetDisease,
      'targetCountry': targetCountry,
      // Note : La dateAdhesion n'est pas dans le modèle Sponsor fourni, 
      // mais elle est dans la DB. Si vous l'ajoutez, n'oubliez pas de la gérer.
    };
  }
}
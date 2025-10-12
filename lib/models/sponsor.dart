// lib/models/sponsor.dart

class Sponsor {
  final int? id;
  final String nom;
  final String type; // Ex: 'ONG', 'Gouvernement', 'Entreprise'
  final String? logoUrl;
  final String? siteWeb;
  final DateTime? dateAdhesion;

  Sponsor({
    this.id,
    required this.nom,
    required this.type,
    this.logoUrl,
    this.siteWeb,
    this.dateAdhesion,
  });

  // Convertir Sponsor vers Map (pour SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'logoUrl': logoUrl,
      'siteWeb': siteWeb,
      'dateAdhesion': dateAdhesion?.toIso8601String(),
    };
  }

  // Créer Sponsor depuis Map (depuis SQLite)
  factory Sponsor.fromMap(Map<String, dynamic> map) {
    return Sponsor(
      id: map['id']?.toInt(),
      nom: map['nom'] ?? '',
      type: map['type'] ?? '',
      logoUrl: map['logoUrl'],
      siteWeb: map['siteWeb'],
      dateAdhesion: map['dateAdhesion'] != null
          ? DateTime.parse(map['dateAdhesion'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Sponsor{id: $id, nom: $nom, type: $type}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sponsor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
// lib /models/patient.dart

class Patient {
  final int? id;
  final String nom;
  final String prenom;
  final int age;
  final String pays;
  final String maladie;
  final String? conseils;
  final DateTime dateCreation;
  final DateTime? derniereVisite;

  Patient({
    this.id,
    required this.nom,
    required this.prenom,
    required this.age,
    required this.pays,
    required this.maladie,
    this.conseils,
    DateTime? dateCreation,
    this.derniereVisite,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // convertir Patient vers Map (pour SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'age': age,
      'pays': pays,
      'maladie': maladie,
      'conseils': conseils,
      'dateCreation': dateCreation.toIso8601String(),
      'derniereVisite': derniereVisite?.toIso8601String(),
    };
  }

  // créé Patient depuis Map (depuis SQLite)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id']?.toInt(),
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      age: map['age']?.toInt() ?? 0,
      pays: map['pays'] ?? '',
      maladie: map['maladie'] ?? '',
      conseils: map['conseils'] ?? '',
      dateCreation: map['dateCreation'] != null
          ? DateTime.parse(map['dateCreation'])
          : DateTime.now(),
      derniereVisite: map['derniereVisite'] != null
          ? DateTime.parse(map['derniereVisite'])
          : null,
    );
  }
  //  créé une copie avec des modifications
  Patient copyWith({
    int? id,
    String? nom,
    String? prenom,
    int? age,
    String? pays,
    String? maladie,
    String? conseils,
    DateTime? dateCreation,
    DateTime? derniereVisite,
  }) {
    return Patient(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      age: age ?? this.age,
      pays: pays ?? this.pays,
      maladie: maladie ?? this.maladie,
      conseils: conseils ?? this.conseils,
      dateCreation: dateCreation ?? this.dateCreation,
      derniereVisite: derniereVisite ?? this.derniereVisite,
    );
  }

  // Nom complet pour l'affichage
  String get nomComplet => '$prenom $nom';
  // statut basé sur la dernière visite
  String get statut {
    if (derniereVisite == null) return 'Nouveau';

    final joursDepuisVisite = DateTime.now().difference(derniereVisite!).inDays;

    if (joursDepuisVisite <= 7) return 'Récent';
    if (joursDepuisVisite <= 30) return 'Stable';
    return 'A revoir';
  }

  @override
  String toString() {
    return 'Patient{id: $id, nom: $nomComplet, pays: $pays, maladie: $maladie}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

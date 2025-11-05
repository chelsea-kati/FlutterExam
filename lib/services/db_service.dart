// lib/services/db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/country_stats.dart';
import '../models/Sponsor.dart';
import '../models/Conseil.dart'; // Renommé 'advice.dart' pour le modèle Conseil dans les étapes précédentes
// import '../services/sponsor_service.dart'; // Importer le service des sponsors

class DatabaseService {
  static Database? _database;
  static const String tableName = 'Patients';
  // 🔥 MODE DEBUG : Change à true SEULEMENT pour réinitialiser la DB
  // ⚠️ ATTENTION : Mets à false avant de publier l'app !
  // static const bool FORCE_RESET_DB =true; //pour insérer les patients de test (une seule fois).
  static const bool FORCE_RESET_DB = false;

  //🎯 MODE AUTO : Insère les données de test si la DB est vide
  static const bool AUTO_INSERT_TEST_DATA = true;

  // Singleton pattern
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  // Getter pour la database
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialisation de la database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'patients.db');

    // 🔥 SI MODE DEBUG, supprimer l'ancienne base
    if (FORCE_RESET_DB) {
      print('⚠️ MODE DEBUG : Suppression de l\'ancienne base de données...');
      await deleteDatabase(path);
    }

    print('📂 Chemin de la base de données : $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onOpen: (db) async {
        print('✅ Base de données ouverte avec succès');
        // Vérifier le nombre de patients au démarrage
        final count = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
        print(
          '📊 Nombre de patients dans la DB : ${Sqflite.firstIntValue(count)}',
        );
      },
    );
  }

  // Créer les tables
  Future<void> _createDatabase(Database db, int version) async {
    print('📅 Création de la base de données...');

    // Table des patients
    await db.execute('''
 CREATE TABLE $tableName (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 nom TEXT NOT NULL,
 prenom TEXT NOT NULL,
 age INTEGER NOT NULL,
 pays TEXT NOT NULL,
 dateCreation TEXT NOT NULL,
 maladie TEXT NOT NULL,
 conseils TEXT,
 derniereVisite TEXT
 )
 ''');
    print('✅ Table Patients créée');
    // 💡 AJOUT : Index pour accélérer la recherche par nom, prénom et maladie
    await db.execute('''
  CREATE INDEX idx_patient_search ON $tableName (nom, prenom, maladie);
''');
    print('✅ Index de recherche Patients créé');

    // Table pour les statistiques WHO
    await db.execute('''
 CREATE TABLE country_stats (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 countryCode TEXT NOT NULL,
 countryName TEXT NOT NULL,
 value REAL NOT NULL,
 year INTEGER NOT NULL,
 indicator TEXT NOT NULL,
 lastUpdated TEXT NOT NULL,
 UNIQUE(countryCode, year, indicator)
 )
 ''');
    print('✅ Table country_stats créée');
    // Insérer les données de test
    await _insertTestData(db);
    // ✨ NOUVEAU : Table des conseils
    await db.execute('''
 CREATE TABLE conseils (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 titre TEXT,
 maladieCible TEXT,
 description TEXT,
 source TEXT
 )
''');
    print('✅ Table Conseils créée');

    // 💡 APPEL DE LA FONCTION : Insérer les conseils par défaut juste après la création de la table
    await insertInitialConseils(db);

    // ✨ NOUVEAU : Table des sponsors
    await db.execute('''
CREATE TABLE sponsors (
 id INTEGER PRIMARY KEY,
 nom TEXT NOT NULL, 
 logoUrl TEXT,
 siteWeb TEXT,
 description TEXT, 
 targetDisease TEXT, 
 targetCountry TEXT 
 )
 ''');
    print('✅ Table Sponsors créée');
    // 💡 NOUVEL APPEL : Insérer les sponsors par défaut juste après la création de la table
    await insertInitialSponsors(db);
  }

  // Données de test
  Future<void> _insertTestData(Database db) async {
    print('🔄 Insertion des données de test...');

    final testPatients = [
      Patient(
        nom: 'Doe',
        prenom: 'John',
        age: 45,
        pays: 'Burundi',
        maladie: 'Cancer du poumon',
        conseils:
            'Manger équilibré, faire de l\'exercice, suivre le traitement',
        derniereVisite: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Patient(
        nom: 'Uwimana',
        prenom: 'Marie',
        age: 28,
        pays: 'Burundi',
        maladie: 'Cancer du sein',
        conseils: 'Chimiothérapie, repos, soutien familial',
        derniereVisite: DateTime.now().subtract(const Duration(days: 15)),
      ),
      // Ajout de patients pour faire fonctionner les stats/conseils
      Patient(
        nom: 'Ndayishimiye',
        prenom: 'Alex',
        age: 60,
        pays: 'Burundi',
        maladie: 'Cancer de la prostate',
        conseils: 'Suivi régulier.',
        derniereVisite: DateTime.now(),
      ),
      Patient(
        nom: 'Mugisha',
        prenom: 'Fanny',
        age: 70,
        pays: 'Rwanda',
        maladie: 'Cancer colorectal',
        conseils: 'Alimentation riche en fibres.',
        derniereVisite: DateTime.now(),
      ),

    ];

    for (final patient in testPatients) {
      print('➕ Insertion patient: ${patient.nomComplet}');
      final result = await db.insert(
        tableName,
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('  ✓ Patient inséré avec ID: $result');
    }

    // Vérifier l'insertion
    final count = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    print(
      '✅ Données de test insérées : ${Sqflite.firstIntValue(count)} patients',
    );
  }

  // ------------------------------------------------------------------
  // 💡 NOUVELLE FONCTION : Insère les conseils par défaut
  // ------------------------------------------------------------------
  Future<void> insertInitialConseils(Database db) async {
    print('🔄 Insertion des conseils médicaux par défaut...');

    final initialConseils = [
      Conseil(
        titre: 'Dépistage Régulier et Autopalpation',
        maladieCible: 'Cancer du sein',
        description:
            'L\'autopalpation mensuelle et la mammographie régulière (selon l\'âge) sont cruciales pour une détection précoce, augmentant considérablement les chances de succès du traitement.',
        source: 'OMS/Santé Nationale',
      ).toMap(),
      Conseil(
        titre: 'Arrêt du Tabac Immédiat',
        maladieCible: 'Cancer du poumon',
        description:
            'Le sevrage tabagique est la mesure la plus importante. Il ralentit la progression et réduit le risque de récidive.',
        source: 'Ligue contre le Cancer',
      ).toMap(),
      Conseil(
        titre: 'Coloscopie et Alimentation Saine',
        maladieCible: 'Cancer colorectal',
        description:
            'Maintenez une alimentation riche en fibres (fruits, légumes) et réduisez la consommation de viandes rouges transformées. Le dépistage par coloscopie est recommandé à partir de 50 ans.',
        source: 'Société de Gastro-entérologie',
      ).toMap(),
      Conseil(
        titre: 'Suivi PSA et Examen Rectal',
        maladieCible: 'Cancer de la prostate',
        description:
            'Discutez avec votre médecin d\'un dépistage régulier par dosage de l\'antigène prostatique spécifique (PSA) et examen rectal, surtout après 50 ans.',
        source: 'Urologie Afrique',
      ).toMap(),
      Conseil(
        titre: 'Gestion des Infections et Surveillance',
        maladieCible: 'Leucémie',
        description:
            'Les patients sous traitement sont vulnérables aux infections. Une hygiène stricte et la notification immédiate de la fièvre sont vitales.',
        source: 'Hématologie Clinic',
      ).toMap(),
      Conseil(
        titre: 'Protection Immunitaire',
        maladieCible: 'Lymphome',
        description:
            'Évitez les foules et les environnements à haut risque d\'infection pendant les phases de traitement qui compromettent le système immunitaire.',
        source: 'Manuel de Soins',
      ).toMap(),
      Conseil(
        titre: 'Protection Solaire Maximale',
        maladieCible: 'Mélanome',
        description:
            'Éviter l\'exposition au soleil entre 10h et 16h, utiliser une crème solaire à indice élevé (SPF 30+) et porter des vêtements protecteurs. Surveillez tout changement de grains de beauté.',
        source: 'Dermatologie',
      ).toMap(),
      Conseil(
        titre: 'Réduction du Sel et des Aliments Fumés',
        maladieCible: 'Cancer de l\'estomac',
        description:
            'Réduisez la consommation d\'aliments fortement salés, marinés ou fumés, qui sont liés à un risque accru de cancer gastrique. Traitez l\'infection à H. pylori si présente.',
        source: 'IARC',
      ).toMap(),
      Conseil(
        titre: 'Limitation de l\'Alcool et Traitement de l\'Hépatite',
        maladieCible: 'Cancer du foie',
        description:
            'L\'abus d\'alcool et l\'hépatite B/C sont les principaux facteurs de risque. La vaccination contre l\'hépatite B et le traitement des infections chroniques sont essentiels.',
        source: 'Hépato-Gastro',
      ).toMap(),
    ];

    for (var conseilMap in initialConseils) {
      await db.insert(
        'conseils',
        conseilMap,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    print('✅ ${initialConseils.length} conseils insérés (si non existants).');
  }
  // ------------------------------------------------------------------
Future<void> insertInitialSponsors(Database db) async {
  print('🔄 Insertion des données de sponsors par défaut...');

  final initialSponsors = [
    Sponsor(
    id: 1,
    name: 'Santé Plus (Maladie A)', // 👈 'name' au lieu de 'nom'
    imageUrl: 'assets/images/logo_sante_plus.png',
    websiteUrl: 'https://santeplus.org',
    // ✅ AJOUT DES CHAMPS OBLIGATOIRES par le constructeur du modèle :
    description: 'Leader en solutions de santé numérique.', 
    targetDisease: 'Paludisme',
    targetCountry: 'Burundi'
  ).toMap(),
Sponsor(
    id: 2,
    name: 'Global Aid (Maladie B)', // 👈 Utiliser 'name' au lieu de 'nom'
    imageUrl: 'assets/images/logo_global_aid.png',
    websiteUrl: 'https://globalaid.org',    
    description: 'Financement de projets humanitaires pour les régions touchées par les maladies.', 
    targetDisease: 'Choléra',
    targetCountry: 'Rwanda',
  ).toMap(),

    Sponsor(
    id: 3,
    name: 'Tech for Health (Maladie C)', // 👈 Utiliser 'name' au lieu de 'nom'
    imageUrl: 'assets/images/logo_tech_health.png',
    websiteUrl: 'https://techforhealth.net',    
    description: 'Fournisseur de solutions technologiques pour le suivi des patients.',
    targetDisease: 'COVID-19',
    targetCountry: 'RDC',
  ).toMap(),
  ];

  for (var sponsorMap in initialSponsors) {
    // ⚠️ Note : Nous utilisons la colonne 'sponsors' et non 'Sponsors'
    await db.insert(
      'sponsors', 
      sponsorMap,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  print('✅ ${initialSponsors.length} sponsors insérés (si non existants).');
}
  // CREATE - Ajouter un nouveau patient
  Future<int> insertPatient(Patient patient) async {
    // ... (Logique inchangée)
    final db = await database;
    final id = await db.insert(
      tableName,
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ Patient ajouté avec ID: $id');
    return id;
  }

  // READ - Récupérer tous les patients
  Future<List<Patient>> getAllPatients() async {
    // ... (Logique inchangée)
    print('📖 Récupération de tous les patients...');
    final db = await database;
    final maps = await db.query(tableName, orderBy: 'dateCreation DESC');

    print('📊 Nombre de patients trouvés: ${maps.length}');

    if (maps.isEmpty) {
      print('⚠️ Aucun patient dans la base !');
      return [];
    }

    return List.generate(maps.length, (i) {
      print('   Patient ${i + 1}: ${maps[i]['nom']} ${maps[i]['prenom']}');
      return Patient.fromMap(maps[i]);
    });
  }
  // 2. READ (Récupérer les 5 patients les plus récents) 💡 NOUVELLE MÉTHODE
Future<List<Patient>> getRecentPatients(int limit) async {
  print('📖 Récupération des $limit patients les plus récents...');
  final db = await database;
  
  // Utilise ORDER BY et LIMIT pour n'obtenir que les N plus récents
  final List<Map<String, dynamic>> maps = await db.query(
    tableName, // Remplacez par votre nom de table si différent
    orderBy: 'dateCreation DESC', // Utilisez votre champ de tri récent
    limit: limit, // La limite passée en paramètre (sera 5)
  );

  print('📊 Nombre de patients récents trouvés: ${maps.length}');

  if (maps.isEmpty) {
    print('⚠️ Aucun patient récent trouvé !');
    return [];
  }

  return List.generate(maps.length, (i) {
    return Patient.fromMap(maps[i]);
  });
}

  // READ - Récupérer un patient par ID
  Future<Patient?> getPatientById(int id) async {
    // ... (Logique inchangée)
    final db = await database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  // READ - Rechercher des patients
  Future<List<Patient>> searchPatients(String query) async {
    // ... (Logique inchangée)
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'nom LIKE ? OR prenom LIKE ? OR maladie LIKE ? OR pays LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'dateCreation DESC',
    );

    return List.generate(maps.length, (i) {
      return Patient.fromMap(maps[i]);
    });
  }

  // UPDATE - Modifier un patient
  Future<int> updatePatient(Patient patient) async {
    // ... (Logique inchangée)
    final db = await database;
    return await db.update(
      tableName,
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  // DELETE - Supprimer un patient
  Future<int> deletePatient(int id) async {
    // ... (Logique inchangée)
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ========== STATISTIQUES PATIENTS ==========

  // Compter les patients
  Future<int> getPatientCount() async {
    // ... (Logique inchangée)
    print('🔢 Comptage des patients...');
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    final count = Sqflite.firstIntValue(result) ?? 0;
    print('📊 Nombre total de patients: $count');
    return count;
  }

  // Patients par pays
  Future<List<Map<String, dynamic>>> getPatientsByCountry() async {
    // ... (Logique inchangée)
    final db = await database;
    final result = await db.rawQuery('''
      SELECT pays, COUNT(id) AS count
      FROM patients
      GROUP BY pays
      ORDER BY count DESC
    ''');
    return result;
  }

  // Patients par maladie
  Future<List<Map<String, dynamic>>> getPatientsByDisease() async {
    // ... (Logique inchangée)
    final db = await database;
    final result = await db.rawQuery('''
      SELECT maladie, COUNT(id) as count
      FROM patients
      GROUP BY maladie
      ORDER BY count DESC
    ''');
    return result;
  }

  // ========== STATISTIQUES WHO ==========

  Future<void> saveCountryStats(List<CountryStats> stats) async {
    // ... (Logique inchangée)
    final db = await database;
    for (final stat in stats) {
      await db.insert(
        'country_stats',
        stat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<CountryStats>> getCountryStats({String? countryCode}) async {
    // ... (Logique inchangée)
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'country_stats',
      where: countryCode != null ? 'countryCode = ?' : null,
      whereArgs: countryCode != null ? [countryCode] : null,
      orderBy: 'year DESC',
    );
    return List.generate(maps.length, (i) => CountryStats.fromMap(maps[i]));
  }

  Future<bool> areStatsOutdated() async {
    // ... (Logique inchangée)
    final db = await database;
    final result = await db.query(
      'country_stats',
      columns: ['lastUpdated'],
      orderBy: 'lastUpdated DESC',
      limit: 1,
    );
    if (result.isEmpty) return true;
    final lastUpdate = DateTime.parse(result.first['lastUpdated'] as String);
    return DateTime.now().difference(lastUpdate).inDays > 7;
  }

  Future<void> clearOldStats() async {
    // ... (Logique inchangée)
    final db = await database;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    await db.delete(
      'country_stats',
      where: 'lastUpdated < ?',
      whereArgs: [oneWeekAgo.toIso8601String()],
    );
  }

  // 2. Pour la PatientDetailPage (Conseils)
  Future<Conseil?> getConseilByMaladie(String maladieCible) async {
    // ... (Logique inchangée)
    final db = await database;
    final maps = await db.query(
      'conseils',
      where: 'maladieCible = ?',
      whereArgs: [maladieCible],
      limit: 1, // On ne veut qu'un seul conseil pertinent
    );

    if (maps.isNotEmpty) {
      return Conseil.fromMap(maps.first);
    }
    return null;
  }

  // 3. Exemple pour insérer des conseils pré-enregistrés (utile pour le démarrage)
  Future<int> insertConseil(Conseil conseil) async {
    // ... (Logique inchangée)
    final db = await database;
    return await db.insert(
      'conseils',
      conseil.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fermer la database
  Future<void> close() async {
    // ... (Logique inchangée)
    final db = await database;
    await db.close();
  }

  // 🛠️ MÉTHODE DEBUG : Afficher toutes les données
  Future<void> debugPrintAllData() async {
    // ... (Logique inchangée)
    print('\n========== DEBUG DATABASE ==========');
    final db = await database;

    // Compter les patients
    final count = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    print('Total patients: ${Sqflite.firstIntValue(count)}');

    // Lister tous les patients
    final patients = await db.query(tableName);
    print('\nListe des patients:');
    for (var patient in patients) {
      print(
        ' - ID: ${patient['id']}, Nom: ${patient['nom']} ${patient['prenom']}',
      );
    }
    print('====================================\n');
  }
}

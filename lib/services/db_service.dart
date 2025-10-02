// lib/services/db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/country_stats.dart';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'Patients';

  // 🔥 MODE DEBUG : Change à true SEULEMENT pour réinitialiser la DB
  // ⚠️ ATTENTION : Mets à false avant de publier l'app !
  // static const bool FORCE_RESET_DB = true;//pour insérer les patients de test (une seule fois).
  static const bool FORCE_RESET_DB = false;

  // 🎯 MODE AUTO : Insère les données de test si la DB est vide
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
        nom: 'Smith',
        prenom: 'Jane',
        age: 32,
        pays: 'Rwanda',
        maladie: 'VIH',
        conseils: 'Prendre les ARV régulièrement, manger sainement',
        derniereVisite: DateTime.now().subtract(const Duration(days: 7)),
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
    ];

    for (final patient in testPatients) {
      print('➕ Insertion patient: ${patient.nomComplet}');
      final result = await db.insert(
        tableName,
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('   ✓ Patient inséré avec ID: $result');
    }

    // Vérifier l'insertion
    final count = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    print(
      '✅ Données de test insérées : ${Sqflite.firstIntValue(count)} patients',
    );
  }

  // CREATE - Ajouter un nouveau patient
  Future<int> insertPatient(Patient patient) async {
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
    print('📖 Récupération de tous les patients...');
    final db = await database;
    final maps = await db.query(tableName, orderBy: 'dateCreation DESC');

    print('📊 Nombre de patients trouvés: ${maps.length}');

    if (maps.isEmpty) {
      print('⚠️ Aucun patient dans la base !');
      return [];
    }

    return List.generate(maps.length, (i) {
      print('   Patient ${i + 1}: ${maps[i]['nom']} ${maps[i]['prenom']}');
      return Patient.fromMap(maps[i]);
    });
  }

  // READ - Récupérer un patient par ID
  Future<Patient?> getPatientById(int id) async {
    final db = await database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  // READ - Rechercher des patients
  Future<List<Patient>> searchPatients(String query) async {
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
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // ========== STATISTIQUES PATIENTS ==========

  // Compter les patients
  Future<int> getPatientCount() async {
    print('🔢 Comptage des patients...');
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    final count = Sqflite.firstIntValue(result) ?? 0;
    print('📊 Nombre total de patients: $count');
    return count;
  }

  // Patients par pays
  Future<Map<String, int>> getPatientsByCountry() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT pays, COUNT(*) as count FROM $tableName GROUP BY pays',
    );

    Map<String, int> countryStats = {};
    for (var row in result) {
      countryStats[row['pays'] as String] = row['count'] as int;
    }
    return countryStats;
  }

  // Patients par maladie
  Future<Map<String, int>> getPatientsByDisease() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT maladie, COUNT(*) as count FROM $tableName GROUP BY maladie',
    );

    Map<String, int> diseaseStats = {};
    for (var row in result) {
      diseaseStats[row['maladie'] as String] = row['count'] as int;
    }
    return diseaseStats;
  }

  // ========== STATISTIQUES WHO ==========

  Future<void> saveCountryStats(List<CountryStats> stats) async {
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
    final db = await database;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    await db.delete(
      'country_stats',
      where: 'lastUpdated < ?',
      whereArgs: [oneWeekAgo.toIso8601String()],
    );
  }

  // Fermer la database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // 🛠️ MÉTHODE DEBUG : Afficher toutes les données
  Future<void> debugPrintAllData() async {
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
        '  - ID: ${patient['id']}, Nom: ${patient['nom']} ${patient['prenom']}',
      );
    }
    print('====================================\n');
  }
}

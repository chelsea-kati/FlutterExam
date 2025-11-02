// lib/services/auth_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  static Database? _authDatabase;
  static const String usersTable = 'users';

  // Singleton
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  // User actuel connecté
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Getter pour la database
  Future<Database> get database async {
    _authDatabase ??= await _initAuthDatabase();
    return _authDatabase!;
  }

  // Initialiser la base d'authentification
  Future<Database> _initAuthDatabase() async {
    String path = join(await getDatabasesPath(), 'auth.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createAuthDatabase,
    );
  }

  // Créer la table users
  Future<void> _createAuthDatabase(Database db, int version) async {
    print('📅 Création de la table d\'authentification...');
    
    await db.execute('''
      CREATE TABLE $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        role TEXT NOT NULL,
        specialization TEXT,
        profileImageUrl TEXT,
        createdAt TEXT NOT NULL,
        lastLogin TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Créer un utilisateur admin par défaut
    await _createDefaultAdmin(db);
    print('✅ Table users créée avec admin par défaut');
  }

  // Créer un compte admin par défaut
  Future<void> _createDefaultAdmin(Database db) async {
    final hashedPassword = _hashPassword('admin123');
    
    await db.insert(usersTable, {
      'username': 'admin',
      'password': hashedPassword,
      'fullName': 'Administrateur',
      'role': 'admin',
      'specialization': 'Administration',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': 1,
    });
    
    print('👤 Compte admin créé : admin / admin123');
  }

  // Hasher le mot de passe
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // INSCRIPTION - Créer un nouveau compte
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String role,
    String? specialization,
    String? profileImageUrl,
  }) async {
    try {
      // Validation
      if (username.length < 3) {
        return {
          'success': false,
          'message': 'Le nom d\'utilisateur doit contenir au moins 3 caractères'
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Le mot de passe doit contenir au moins 6 caractères'
        };
      }

      final db = await database;

      // Vérifier si l'utilisateur existe déjà
      final existing = await db.query(
        usersTable,
        where: 'username = ?',
        whereArgs: [username.toLowerCase()],
      );

      if (existing.isNotEmpty) {
        return {
          'success': false,
          'message': 'Ce nom d\'utilisateur existe déjà'
        };
      }

      // Créer le nouvel utilisateur
      final hashedPassword = _hashPassword(password);
      final userId = await db.insert(usersTable, {
        'username': username.toLowerCase(),
        'password': hashedPassword,
        'fullName': fullName,
        'role': role,
        'specialization': specialization,
        'profileImageUrl': profileImageUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'isActive': 1,
      });

      print('✅ Utilisateur créé avec ID: $userId');

      return {
        'success': true,
        'message': 'Compte créé avec succès',
        'userId': userId,
      };
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la création du compte: $e'
      };
    }
  }

  // CONNEXION - Login
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final db = await database;

      // Rechercher l'utilisateur
      final users = await db.query(
        usersTable,
        where: 'username = ? AND isActive = 1',
        whereArgs: [username.toLowerCase()],
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'message': 'Nom d\'utilisateur ou mot de passe incorrect'
        };
      }

      final userData = users.first;
      final hashedPassword = _hashPassword(password);

      // Vérifier le mot de passe
      if (userData['password'] != hashedPassword) {
        return {
          'success': false,
          'message': 'Nom d\'utilisateur ou mot de passe incorrect'
        };
      }

      // Mettre à jour la dernière connexion
      await db.update(
        usersTable,
        {'lastLogin': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userData['id']],
      );

      // Créer l'objet User
      _currentUser = User.fromMap(userData);

      print('✅ Connexion réussie: ${_currentUser!.fullName}');

      return {
        'success': true,
        'message': 'Connexion réussie',
        'user': _currentUser,
      };
    } catch (e) {
      print('❌ Erreur lors de la connexion: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la connexion: $e'
      };
    }
  }

  // DÉCONNEXION
  Future<void> logout() async {
    _currentUser = null;
    print('👋 Déconnexion effectuée');
  }

  // Vérifier si un utilisateur est connecté
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // Obtenir tous les utilisateurs (admin seulement)
  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query(usersTable, orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Désactiver un utilisateur (admin)
  Future<bool> deactivateUser(int userId) async {
    try {
      final db = await database;
      await db.update(
        usersTable,
        {'isActive': 0},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('❌ Erreur lors de la désactivation: $e');
      return false;
    }
  }

  // Activer un utilisateur (admin)
  Future<bool> activateUser(int userId) async {
    try {
      final db = await database;
      await db.update(
        usersTable,
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'activation: $e');
      return false;
    }
  }

  // Changer le mot de passe
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return {
        'success': false,
        'message': 'Aucun utilisateur connecté'
      };
    }

    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'Le nouveau mot de passe doit contenir au moins 6 caractères'
      };
    }

    try {
      final db = await database;

      // Vérifier l'ancien mot de passe
      final hashedCurrent = _hashPassword(currentPassword);
      final users = await db.query(
        usersTable,
        where: 'id = ? AND password = ?',
        whereArgs: [_currentUser!.id, hashedCurrent],
      );

      if (users.isEmpty) {
        return {
          'success': false,
          'message': 'Mot de passe actuel incorrect'
        };
      }

      // Mettre à jour avec le nouveau mot de passe
      final hashedNew = _hashPassword(newPassword);
      await db.update(
        usersTable,
        {'password': hashedNew},
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      return {
        'success': true,
        'message': 'Mot de passe modifié avec succès'
      };
    } catch (e) {
      print('❌ Erreur lors du changement de mot de passe: $e');
      return {
        'success': false,
        'message': 'Erreur: $e'
      };
    }
  }

  // Réinitialiser le mot de passe (admin uniquement)
  Future<Map<String, dynamic>> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    if (_currentUser == null || _currentUser!.role != 'admin') {
      return {
        'success': false,
        'message': 'Action réservée aux administrateurs'
      };
    }

    try {
      final db = await database;
      final hashedPassword = _hashPassword(newPassword);
      
      await db.update(
        usersTable,
        {'password': hashedPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );

      return {
        'success': true,
        'message': 'Mot de passe réinitialisé avec succès'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e'
      };
    }
  }

  // Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? specialization,
  }) async {
    if (_currentUser == null) {
      return {
        'success': false,
        'message': 'Aucun utilisateur connecté'
      };
    }

    try {
      final db = await database;
      
      await db.update(
        usersTable,
        {
          'fullName': fullName,
          if (specialization != null) 'specialization': specialization,
        },
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      // Mettre à jour l'utilisateur actuel
      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        specialization: specialization,
      );

      return {
        'success': true,
        'message': 'Profil mis à jour avec succès'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: $e'
      };
    }
  }
}
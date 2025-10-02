// lib/services/sync_service.dart

import '../services/who_api_service.dart';
import '../services/db_service.dart';
import '../pages/stats_page.dart';
import '../models/country_stats.dart';
// import '../services/sync_service.dart';



class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final WHOApiService _whoApi = WHOApiService.instance;
  final DatabaseService _dbService = DatabaseService.instance;

  // Synchroniser les statistiques WHO
  Future<SyncResult> syncWHOData() async {
    try {
      // 1. Vérifier la connexion internet
      final hasInternet = await _whoApi.hasInternetConnection();
      
      if (!hasInternet) {
        return SyncResult(
          success: false,
          message: 'Pas de connexion internet. Utilisation des données locales.',
          dataSource: DataSource.local,
        );
      }

      // 2. Vérifier si les données locales sont obsolètes
      final isOutdated = await _dbService.areStatsOutdated();
      
      if (!isOutdated) {
        return SyncResult(
          success: true,
          message: 'Données à jour. Utilisation des données locales.',
          dataSource: DataSource.local,
        );
      }

      // 3. Récupérer les nouvelles données WHO
      print('Récupération des données WHO...');
      final stats = await _whoApi.getCancerStatsByCountry(
        countries: ['BURUNDI', 'RWANDA', 'KENYA', 'UGANDA', 'TANZANIE'], // Afrique de l'Est
      );

      if (stats.isEmpty) {
        return SyncResult(
          success: false,
          message: 'Aucune donnée reçue de l\'API WHO',
          dataSource: DataSource.api,
        );
      }

      // 4. Sauvegarder en local
      await _dbService.saveCountryStats(stats);
      
      // 5. Nettoyer les anciennes données
      await _dbService.clearOldStats();

      return SyncResult(
        success: true,
        message: 'Données WHO mises à jour (${stats.length} entrées)',
        dataSource: DataSource.api,
        dataCount: stats.length,
      );

    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
      return SyncResult(
        success: false,
        message: 'Erreur: $e',
        dataSource: DataSource.error,
      );
    }
  }

  // Récupérer les statistiques (local d'abord, puis API si nécessaire)
  Future<List<CountryStats>> getStats({bool forceRefresh = false}) async {
    try {
      // Force refresh ou pas de données locales
      if (forceRefresh || await _dbService.areStatsOutdated()) {
        final syncResult = await syncWHOData();
        print('Sync result: ${syncResult.message}');
      }

      // Récupérer les données locales
      final stats = await _dbService.getCountryStats();
      
      if (stats.isEmpty) {
        // Fallback: données de test si tout échoue
        return _getFallbackStats();
      }
      
      return stats;
    } catch (e) {
      print('Erreur lors de la récupération des stats: $e');
      return _getFallbackStats();
    }
  }

  // Données de fallback en cas d'échec
  List<CountryStats> _getFallbackStats() {
    return [
      CountryStats(
        countryCode: 'BDI',
        countryName: 'Burundi',
        value: 150.5,
        year: 2024,
        indicator: 'Cancer mortality',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'RWA',
        countryName: 'Rwanda',
        value: 120.3,
        year: 2024,
        indicator: 'Cancer mortality',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'KEN',
        countryName: 'Kenya',
        value: 180.7,
        year: 2024,
        indicator: 'Cancer mortality',
        lastUpdated: DateTime.now(),
      ),
    ];
  }
}

// Résultat de synchronisation
class SyncResult {
  final bool success;
  final String message;
  final DataSource dataSource;
  final int dataCount;

  SyncResult({
    required this.success,
    required this.message,
    required this.dataSource,
    this.dataCount = 0,
  });

  @override
  String toString() {
    return 'SyncResult{success: $success, message: $message, source: $dataSource}';
  }
}

enum DataSource {
  local,    // Données depuis SQLite
  api,      // Données depuis API WHO
  error,    // Erreur de récupération
}
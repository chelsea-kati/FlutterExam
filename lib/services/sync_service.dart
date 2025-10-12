// lib/services/sync_service.dart

import '../services/who_api_service.dart';
import '../services/db_service.dart';
import '../models/country_stats.dart';

class SyncService {
  static final SyncService instance = SyncService._internal();
  SyncService._internal();

  final WHOApiService _whoApi = WHOApiService.instance;
  final DatabaseService _dbService = DatabaseService.instance;

  // Synchroniser les statistiques WHO
  Future<SyncResult> syncWHOData() async {
    try {
      print('🔄 Début synchronisation WHO...');
      
      final hasInternet = await _whoApi.hasInternetConnection();

      if (!hasInternet) {
        print('⚠️ Pas de connexion internet');
        return SyncResult(
          success: false,
          message: 'Pas de connexion internet.',
          dataSource: DataSource.local,
        );
      }

      final isOutdated = await _dbService.areStatsOutdated();

      if (!isOutdated) {
        print('✅ Données locales à jour');
        return SyncResult(
          success: true,
          message: 'Données à jour.',
          dataSource: DataSource.local,
        );
      }

      print('📡 Récupération depuis API WHO...');
      final stats = await _whoApi.getCancerStatsByCountry(
        countries: [
          'BDI', 'RWA', 'KEN', 'UGA', 'TZA',
          'ETH', 'SOM', 'SSD', 'COD', 'MOZ',
        ],
      );

      if (stats.isEmpty) {
        print('⚠️ API retourne liste vide');
        return SyncResult(
          success: false,
          message: 'Aucune donnée reçue',
          dataSource: DataSource.api,
        );
      }

      print('💾 Sauvegarde de ${stats.length} statistiques...');
      await _dbService.saveCountryStats(stats);
      await _dbService.clearOldStats();

      print('✅ Synchronisation réussie');
      return SyncResult(
        success: true,
        message: 'Données mises à jour (${stats.length} entrées)',
        dataSource: DataSource.api,
        dataCount: stats.length,
      );
    } catch (e) {
      print('❌ Erreur synchronisation: $e');
      return SyncResult(
        success: false,
        message: 'Erreur: $e',
        dataSource: DataSource.error,
      );
    }
  }

  // Récupérer les statistiques
  Future<List<CountryStats>> getStats({bool forceRefresh = false}) async {
    try {
      print('📊 Récupération des statistiques...');
      
      if (forceRefresh || await _dbService.areStatsOutdated()) {
        print('🔄 Synchronisation nécessaire');
        await syncWHOData();
      }

      final stats = await _dbService.getCountryStats();
      print('📈 ${stats.length} statistiques en local');

      if (stats.isEmpty) {
        print('⚠️ DB vide - appel direct à WHOApiService');
        // Au lieu de _getFallbackStats(), appel direct
        return await _whoApi.getCancerStatsByCountry();
      }

      return stats;
    } catch (e) {
      print('❌ Erreur récupération: $e');
      // En cas d'erreur, appel direct à WHOApiService
      return await _whoApi.getCancerStatsByCountry();
    }
  }

  // _getFallbackStats() SUPPRIMÉE - plus de duplication!
}

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
    return 'SyncResult{success: $success, message: $message, source: $dataSource, count: $dataCount}';
  }
}

enum DataSource {
  local,
  api,
  error,
}
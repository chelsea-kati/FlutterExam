// lib/services/who_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/country_stats.dart';
import '../models/patient.dart';
import 'db_service.dart'; // 💡 AJOUTEZ CET IMPORT

class WHOApiService {
  static const String _baseUrl = 'https://ghoapi.azureedge.net/api';
  static final WHOApiService instance = WHOApiService._internal();

  WHOApiService._internal();

  // Map pour convertir codes ISO -> noms lisibles
  static const Map<String, String> _countryNames = {
    'BDI': 'Burundi',
    'RWA': 'Rwanda',
    'KEN': 'Kenya',
    'TZA': 'Tanzania',
    'UGA': 'Uganda',
    'ETH': 'Ethiopia',
    'SOM': 'Somalia',
    'SSD': 'South Sudan',
    'COD': 'DR Congo',
    'MOZ': 'Mozambique',
  };

  // Méthode fictive pour récupérer des patients depuis l'API WHO
  Future<List<Patient>> getPatients() async {
    // ... (Logique inchangée)
    await Future.delayed(const Duration(seconds: 1));
    return [
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
  }

  // Vérifier la connexion internet
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      // Augmentez le timeout
      final response = await http
          .get(Uri.parse('$_baseUrl'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur de connexion: $e');
      return false;
    }
  }

  // Récupérer statistiques cancer par pays
  Future<List<CountryStats>> getCancerStatsByCountry({
    List<String> countries = const [
      'BDI', // Burundi
      'RWA', // Rwanda
      'KEN', // Kenya
      'TZA', // Tanzania
      'UGA', // Uganda
      'ETH', // Ethiopia
      'SOM', // Somalia 'SSD', // South Sudan
      'COD', // DR Congo
      'MOZ', // Mozambique
    ],
  }) async {
    try {
      if (!await hasInternetConnection()) {
        print('Pas de connexion internet - retour de données de test');
        return _getTestData();
      }

      final countryFilter = countries
          .map((c) => "SpatialDim eq '$c'")
          .join(' or ');

      // 🎯 MODIFICATION 1 : Utiliser l'indicateur plus fiable NCD_MORT_CANCER
      //  final url = '$_baseUrl/NCD_MORT_CANCER?\$filter=($countryFilter)';
      
          final url = '$_baseUrl/NCDMORT3070?\$filter=($countryFilter)';
      print('Requête API WHO: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'PlaidoyerSanteApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['value'] ?? [];

        print('Nombre de résultats bruts: ${values.length}');

        if (values.isEmpty) {
          print('Aucune donnée retournée - utilisation de données de test');
          return _getTestData();
        }

        // Conversion de toutes les données en objets CountryStats
        List<CountryStats> allStats = [];
        for (var item in values) {
          try {
            final stat = CountryStats.fromWHOJson(item);
            // Convertir le code pays en nom lisible
            final readableName =
                _countryNames[stat.countryCode] ?? stat.countryCode;
            allStats.add(
              CountryStats(
                countryCode: stat.countryCode,
                countryName: readableName,
                value: stat.value,
                year: stat.year,
                indicator: stat.indicator,
                lastUpdated: stat.lastUpdated,
              ),
            );
          } catch (e) {
            print('Erreur parsing item: $e');
          }
        }

        // 🎯 MODIFICATION 2 : Logique de FILTRAGE PAR ANNÉE (Année la plus récente)

        // Trouver l'année maximale parmi les résultats
        int maxYear = allStats.fold(
          0,
          (currentMax, stat) =>
              (stat.year ?? 0) > currentMax ? (stat.year ?? 0) : currentMax,
        );

        // Si l'année la plus récente est trouvée (et que ce n'est pas 0)
        List<CountryStats> filteredStats;
        if (maxYear > 0) {
          // Filtrer pour ne garder que cette année
          filteredStats = allStats
              .where((stat) => stat.year == maxYear)
              .toList();
          print(
            '✅ Filtrage appliqué : ${filteredStats.length} données de l\'année $maxYear conservées.',
          );
        } else {
          // Si aucune année n'est trouvée, utiliser toutes les données converties
          filteredStats = allStats;
          print(
            '⚠️ Aucune année trouvée pour le filtrage, ${filteredStats.length} données conservées.',
          );
        }

        // 🎯 MODIFICATION 3 : Retourner les données FILTRÉES
        return filteredStats.isEmpty ? _getTestData() : filteredStats;
      } else {
        print('Erreur API WHO: ${response.statusCode}');
        return _getTestData();
      }
    } catch (e) {
      print('Exception lors de la récupération des données WHO: $e');
      return _getTestData();
    }
  }

  // Données de test pour le développement/offline
  List<CountryStats> _getTestData() {
    // ... (Logique inchangée)
    return [
      CountryStats(
        countryCode: 'BDI',
        countryName: 'Burundi',
        value: 145.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'RWA',
        countryName: 'Rwanda',
        value: 178.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'KEN',
        countryName: 'Kenya',
        value: 234.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'TZA',
        countryName: 'Tanzania',
        value: 189.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'UGA',
        countryName: 'Uganda',
        value: 167.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'ETH',
        countryName: 'Ethiopia',
        value: 156.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'SOM',
        countryName: 'Somalia',
        value: 198.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'SSD',
        countryName: 'South Sudan',
        value: 212.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'COD',
        countryName: 'DR Congo',
        value: 176.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
      CountryStats(
        countryCode: 'MOZ',
        countryName: 'Mozambique',
        value: 203.0,
        year: 2025,
        indicator: 'NCDMORT3070',
        lastUpdated: DateTime.now(),
      ),
    ];
  }

  // Récupérer tous les indicateurs de santé disponibles
  Future<List<HealthIndicator>> getAvailableIndicators() async {
    // ... (Logique inchangée)
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/Indicator'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> indicators = data['value'] ?? [];

        return indicators
            .map((item) => HealthIndicator.fromJson(item))
            .where(
              (indicator) =>
                  indicator.title.toLowerCase().contains('cancer') ||
                  indicator.title.toLowerCase().contains('mortality'),
            )
            .toList();
      } else {
        throw Exception(
          'Erreur récupération indicateurs: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur indicateurs: $e');
      return [];
    }
  }

  // 💡 NOUVELLE MÉTHODE : Synchronisation et Sauvegarde Centralisée
  /// Télécharge les stats de l'OMS (WHO) et les sauvegarde dans la DB locale.
  /// Cette méthode est appelée par StatisticsPageState.
  Future<void> syncAndSaveCancerStats() async {
    print('🔄 WHOApiService: Démarrage de la synchronisation...');

    try {
      // 1. Récupération des données (téléchargement ou données de test)
      final List<CountryStats> retrievedStats = await getCancerStatsByCountry();
      if (retrievedStats.isNotEmpty) {
        // 2. Sauvegarde des données via le DatabaseService
        await DatabaseService.instance.saveCountryStats(retrievedStats);
        print(
          '✅ WHOApiService: ${retrievedStats.length} statistiques sauvegardées localement.',
        );
      } else {
        print(
          '⚠️ WHOApiService: Aucune statistique récupérée pour la sauvegarde.',
        );
      }
    } catch (e) {
      print('❌ WHOApiService: Erreur fatale lors de la synchronisation: $e');
      // On peut choisir d'ignorer ou de relancer une erreur plus tard
    }
  }
}

// Modèle pour les indicateurs de santé
class HealthIndicator {
  // ... (Logique inchangée)
  final String code;
  final String title;
  final String definition;

  HealthIndicator({
    required this.code,
    required this.title,
    required this.definition,
  });

  factory HealthIndicator.fromJson(Map<String, dynamic> json) {
    return HealthIndicator(
      code: json['IndicatorCode'] ?? '',
      title: json['IndicatorName'] ?? '',
      definition: json['Definition'] ?? '',
    );
  }

  @override
  String toString() => '$code: $title';
}

// lib/services/who_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/country_stats.dart';
import '../models/patient.dart';

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

  // // Vérifier la connexion internet
  // Future<bool> hasInternetConnection() async {
  //   try {
  //     final connectivityResult = await Connectivity().checkConnectivity();
  //     if (connectivityResult == ConnectivityResult.none) {
  //       return false;
  //     }
  //     // Augmentez le timeout
  //     final response = await http
  //         .get(Uri.parse('$_baseUrl'), headers: {'Accept': 'application/json'})
  //         .timeout(const Duration(seconds: 15));

  //     return response.statusCode == 200;
  //   } catch (e) {
  //     print('Erreur de connexion: $e');
  //     return false;
  //   }
  // }
  Future<bool> hasInternetConnection() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('❌ Pas de connectivité réseau');
      return false;
    }

    // Test avec Google au lieu de l'API WHO
    final response = await http
        .get(Uri.parse('https://www.google.com'))
        .timeout(const Duration(seconds: 10));

    print('✅ Connexion internet OK (status: ${response.statusCode})');
    return response.statusCode == 200;
  } catch (e) {
    print('❌ Pas d\'internet: $e');
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
      'SOM', // Somalia
      'SSD', // South Sudan
      'COD', // DR Congo
      'MOZ', // Mozambique
    ],
  }) async {
    try {
      if (!await hasInternetConnection()) {
        print('Pas de connexion internet - retour de données de test');
        return _getTestData();
      }

      // URL corrigée avec codes ISO-3
      final url =
          '$_baseUrl/NCDMORT3070?\$filter=SpatialDim in (${countries.map((c) => "'$c'").join(',')}) and Dim1 eq "TOTL" and Dim2 eq "TOTL"';

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

        print('Nombre de résultats: ${values.length}');

        if (values.isEmpty) {
          print('Aucune donnée retournée - utilisation de données de test');
          return _getTestData();
        }

        List<CountryStats> stats = [];
        for (var item in values) {
          try {
            final stat = CountryStats.fromWHOJson(item);
            // Convertir le code pays en nom lisible
            final readableName =
                _countryNames[stat.countryCode] ?? stat.countryCode;
            stats.add(
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

        print('${stats.length} statistiques chargées');
        return stats.isEmpty ? _getTestData() : stats;
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
}

// Modèle pour les indicateurs de santé
class HealthIndicator {
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

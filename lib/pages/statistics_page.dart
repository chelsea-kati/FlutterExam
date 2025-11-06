// lib/pages/statistics_page.dart

import 'package:flutter/material.dart';
import '../services/db_service.dart'; // Pour récupérer les données agrégées
// import 'package:fl_chart/fl_chart.dart'; // Décommenter si vous utilisez fl_chart
import '../widgets/metric_card.dart';
import '../models/country_stats.dart';
import '../widgets/bar_chart_card.dart';
import '../services/who_api_service.dart'; // 💡 AJOUTEZ CET IMPORT
import 'package:intl/intl.dart'; // 👈 Pour formater la date

// --- DEFINITIONS TEMPORAIRES POUR ÉVITER LES ERREURS ---
// ⚠️ À remplacer par vos classes AppColors et AppSizes si elles existent ailleurs
// class AppColors {
//   static const Color primary = Colors.blue;
//   static const Color background = Color(0xFFF5F5F5);
//   static const Color accent = Colors.orange;
// }

// class AppSizes {
//   static const double paddingS = 8.0; // AJOUTÉ
//   static const double paddingL = 16.0;
//   static const double paddingXL = 24.0;
// }
// --- FIN DES DEFINITIONS TEMPORAIRES ---

// 🎯 NOUVEAU : Définir les dimensions OMS possibles pour le filtre (Code: Nom lisible)
const Map<String, String> whoDimensionOptions = {
  'ALL': 'Tous les Cancers (Moyenne/Agrégat)',
  'BREAST': 'Cancer du Sein',
  'LUNG': 'Cancer du Poumon',
  'COLORECTAL': 'Cancer Colorectal',
  'PROSTATE': 'Cancer de la Prostate',
};


class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Stockage des résultats des requêtes DB
  List<Map<String, dynamic>> patientsByCountry = [];
  List<Map<String, dynamic>> patientsByDisease = [];
  // NOUVEAU : Variable pour stocker toutes les statistiques WHO
  List<CountryStats> whoStats = [];

  // 🎯 NOUVEL ÉTAT : Filtre de dimension OMS sélectionné (valeur par défaut)
  String _selectedWhoDimension = 'ALL';

  /// Fusionne les données locales des patients avec les statistiques OMS.
  List<Map<String, dynamic>> _getMergedCountryData() {
    // Créer un Map pour un accès rapide aux stats WHO par code pays
    final Map<String, CountryStats> whoStatsMap = {};
    for (var stat in whoStats) {
      // Utiliser le code pays (si unique ou prendre la dernière entrée)
      // Puisque whoStats est censé être filtré par dimension ici, le code pays suffit
      whoStatsMap[stat.countryCode] = stat;
    }
    final List<Map<String, dynamic>> mergedData = [];

    // Parcourir les données locales des patients (patientsByCountry)
    for (var patientData in patientsByCountry) {
      // NOTE: Votre modèle patientData ne contient pas de 'code', on utilise 'pays'
      final String countryName = patientData['pays'] as String? ?? 'Pays Inconnu';
      // Il vous faudrait une méthode pour mapper le nom du pays au code pays (ex: 'Burundi' -> 'BDI') pour faire un vrai match avec whoStats
      // Pour le test, nous utilisons le nom du pays pour la fusion (ce qui est faible, mais permet de voir la logique)
      final String countryCode = countryName; // Placeholder: Utiliser le nom du pays comme clé temporaire pour les stats locales
      final int patientCount = patientData['count'] as int? ?? 0;

      // Initialiser les valeurs WHO à zéro ou null
      double whoValue = 0.0;
      String whoIndicator = '';

      // Tenter de trouver la stat WHO correspondante.
      // Si whoStats utilise le Code Pays (ex: BDI), il faut que patientData ait ce code.
      // ACTUELLEMENT: On utilise le code pays de whoStats pour l'index, mais l'API peut renvoyer plus que les pays de nos patients.
      final CountryStats? whoStat = whoStats.firstWhere(
            (stat) => stat.countryName == countryName,
        orElse: () => CountryStats(
          countryCode: '',
          countryName: '',
          value: 0.0,
          year: 0,
          indicator: '',
          indicatorDimension: '',
          lastUpdated: DateTime.now(),
        ), // Fournit un objet par défaut si non trouvé
      );

      if (whoStat != null && whoStat.countryCode.isNotEmpty) {
        whoValue = whoStat.value;
        whoIndicator = whoStat.indicator;
      }

      // Ajouter les données fusionnées
      mergedData.add({
        'country': countryName, // Nom du pays
        'local_count': patientCount, // Nombre de patients locaux
        'who_value': whoValue, // Taux de mortalité WHO
        'who_indicator': whoIndicator, // Indicateur WHO
      });
    }

    // Trier par nombre de patients locaux
    mergedData.sort((a, b) => (b['local_count'] as int).compareTo(a['local_count'] as int));

    return mergedData;
  }


  DateTime? _lastWhoSyncDate;
  int _uniqueCountryStatsCount = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Charge toutes les données statistiques depuis le service de base de données.
  Future<void> _loadStatistics() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Déclencher la synchronisation externe et la sauvegarde locale
      // Le service se charge de vérifier l'internet et de sauvegarder dans la DB.
      // ✅ Utilise le filtre actuel
      await _syncWhoData(_selectedWhoDimension);

      // 2. Récupération des stats patient locales
      final List<Map<String, dynamic>> countryData = await DatabaseService
          .instance
          .getPatientsByCountry();
      final List<Map<String, dynamic>> diseaseData = await DatabaseService
          .instance
          .getPatientsByDisease();
      // 💡 NOUVEAU : Récupérer les stats de l'OMS MAJ (après la synchro)
      // On récupère TOUTES les stats, mais la liste affichée sera filtrée par la logique ci-dessous,
      // ou idéalement, la requête SQL dans getCountryStats devrait filtrer sur `indicatorDimension`
      final List<CountryStats> allWhoStats = await DatabaseService.instance.getCountryStats();

      // Filtrer la liste whoStats en mémoire par la dimension sélectionnée
      final List<CountryStats> filteredWhoStats = allWhoStats.where((stat) =>
      _selectedWhoDimension == 'ALL' || stat.indicatorDimension == _selectedWhoDimension
      ).toList();

      if (mounted) {
        setState(() {
          patientsByCountry = countryData;
          patientsByDisease = diseaseData;
          whoStats = filteredWhoStats; // ⬅️ On utilise la liste FILTRÉE

          // Calculer les métadonnées WHO
          if (whoStats.isNotEmpty) {
            final lastUpdatedStat = whoStats.reduce(
                  (a, b) => a.lastUpdated.isAfter(b.lastUpdated) ? a : b,
            );

            _lastWhoSyncDate = lastUpdatedStat.lastUpdated;

            // Compter le nombre de codes pays uniques pour la dimension filtrée
            _uniqueCountryStatsCount = whoStats
                .map((s) => s.countryCode)
                .toSet()
                .length;
          } else {
            _lastWhoSyncDate = null;
            _uniqueCountryStatsCount = 0;
          }

          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des statistiques: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 💡 MODIFIÉ : Accepte un filtre de dimension
  Future<void> _syncWhoData(String dimensionFilter) async {
    print('🔄 Démarrage de la synchronisation des données WHO pour dimension: $dimensionFilter...');

    // 1. Appeler le service API pour récupérer les données (avec internet ou test data)
    // 🎯 Passe le filtre à l'appel API
    final List<CountryStats> newStats = await WHOApiService.instance
        .getCancerStatsByCountry(whoDimensionFilter: dimensionFilter);

    if (newStats.isNotEmpty) {
      // 2. Sauvegarder les données récupérées dans la DB locale
      await DatabaseService.instance.saveCountryStats(newStats);
      print('✅ ${newStats.length} statistiques WHO sauvegardées localement.');
    } else {
      print('⚠️ Aucune nouvelle statistique WHO récupérée.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mergedCountryData = _getMergedCountryData(); // ⬅️ NOUVEL APPEL
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistiques du Suivi'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())

          : RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingL),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSyncStatusCard(), // Statut des patients (Total)
                  const SizedBox(height: AppSizes.paddingXL),

                  // Graphique 1 : Patients par Maladie
                  _buildSectionTitle('Patients par Maladie'),
                  patientsByDisease.isEmpty
                      ? const Center(
                    child: Text('Aucune donnée maladie disponible.'),
                  )
                  // REMPLACER PAR LE BAR CHART
                      : BarChartCard(
                    labelKey: 'maladie',
                    data: patientsByDisease,
                  ),
                  const SizedBox(height: AppSizes.paddingXL),

                  // Graphique 2 : Patients par Pays

                  _buildSectionTitle('Patients (Local) vs Taux Mortalité (OMS)'),
                  mergedCountryData.isEmpty
                      ? const Text('Aucune donnée pays/OMS disponible.')
                      : BarChartCard(
                    // La nouvelle clé pour le nom du pays est 'country'
                    labelKey: 'country',
                    data: mergedCountryData,
                  ),

                  const SizedBox(height: AppSizes.paddingXL),
                  // 3. STATUT DE SYNCHRONISATION WHO (Carte Verte/Rouge)
                  _buildWhoSyncStatusCard(),
                  const SizedBox(height: AppSizes.paddingXL),

                  // 🎯 NOUVEAU WIDGET : Le sélecteur de dimension
                  _buildWhoDimensionFilter(),
                  const SizedBox(height: AppSizes.paddingL),

                  // 4. 💡 DÉTAILS DES STATISTIQUES WHO (LISTE PAYS PAR PAYS)
                  // N'affiche la liste que si des données ont été synchronisées (whoStats n'est pas vide)
                  if (_uniqueCountryStatsCount > 0)
                    _buildWhoMortalityDetails(),
                  const SizedBox(height: AppSizes.paddingXL),
                ],
              ),
            ),
          ),
    );
  }

// --- WIDGETS DE CONSTRUCTION MODIFIÉS/AJOUTÉS ---

  // 🎯 NOUVEAU WIDGET : SÉLECTEUR DE DIMENSION WHO
  Widget _buildWhoDimensionFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer les Statistiques OMS par Type de Cancer :',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSizes.paddingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedWhoDimension,
                items: whoDimensionOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key, // La valeur du filtre API (ex: 'BREAST')
                    child: Text(entry.value), // Le nom affiché (ex: 'Cancer du Sein')
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedWhoDimension) {
                    setState(() {
                      _selectedWhoDimension = newValue;
                    });
                    // Recharger les données WHO avec le nouveau filtre
                    _loadStatistics();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSizes.paddingL,
        top: AppSizes.paddingS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Placeholder pour un graphique
  Widget _buildChartCard(
      BuildContext context,
      String labelKey,
      List<Map<String, dynamic>> data,
      ) {
    if (data.isEmpty) {
      return const Center(child: Text('Aucune donnée à afficher.'));
    }

    // Dans l'attente d'une librairie de chartes, affichons la liste brute
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder de Graphique
            Container(
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
              ),
              child: const Text(
                'GRAPHIQUE EN COURS D\'IMPLÉMENTATION',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Affichage des données brutes (pour vérification)
            Text(
              'Répartition (Top 5):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...data
                .take(5)
                .map(
                  (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e[labelKey] ?? 'Inconnu'),
                    Text('${e['count']} patients'),
                  ],
                ),
              ),
            )
                .toList(),
          ],
        ),
      ),
    );
  }

  /// Construit la liste détaillée des taux de mortalité de l'OMS par pays.
  Widget _buildWhoMortalityDetails() {
    if (whoStats.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher si aucune donnée WHO
    }

    // Trier les statistiques par pays pour une meilleure lisibilité
    whoStats.sort((a, b) => a.countryName.compareTo(b.countryName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 💡 Le titre reflète maintenant le filtre actuel
        _buildSectionTitle(
          'Taux de Mortalité OMS: ${whoDimensionOptions[_selectedWhoDimension]}',
        ),
        const SizedBox(height: 10),

        // Liste des détails par pays
        ...whoStats.map((stat) {
          final formattedValue = NumberFormat.decimalPattern().format(
            stat.value,
          );
          // 💡 Déterminer le nom lisible de la dimension
          final readableDimension = whoDimensionOptions.containsKey(stat.indicatorDimension)
              ? whoDimensionOptions[stat.indicatorDimension]
              : stat.indicatorDimension;


          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              elevation: 1,
              child: ListTile(
                title: Text(
                  // Affiche l'année si elle est pertinente
                  '${stat.countryName} (${stat.year})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '$formattedValue',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                // 💡 Affiche la dimension de la stat (utile en mode 'ALL')
                subtitle: Text('Type de Cancer: $readableDimension'),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Placeholder pour le Statut de Sync WHO (utilise la table country_stats)
  Widget _buildWhoSyncStatusCard() {
    // Simulez le statut à partir des variables d'état
    final String syncDateText = _lastWhoSyncDate != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(_lastWhoSyncDate!)
        : 'Jamais synchronisé';

    final bool isSynced = _uniqueCountryStatsCount > 0;

    // Définir les couleurs et icônes
    final Color color = isSynced ? Colors.green.shade700 : Colors.red.shade700;
    final Color bgColor = isSynced
        ? Colors.lightGreen.shade50
        : Colors.red.shade50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: bgColor,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12.0),
          leading: Icon(
            isSynced ? Icons.sync_alt : Icons.warning_amber,
            color: color,
            size: 30,
          ),
          title: Text(
            'Statut de Synchronisation OMS',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          subtitle: Text(
            isSynced
                ? 'Dernière synchronisation réussie le $syncDateText. Données de mortalité à jour pour $_uniqueCountryStatsCount pays.'
                : 'Données WHO non disponibles ou synchronisation requise. Vérifiez votre connexion.',
            style: TextStyle(color: color.withOpacity(0.9)),
          ),
          trailing: Icon(
            isSynced ? Icons.check_circle : Icons.error,
            color: color,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    // C'est un widget générique, peut être combiné avec _buildWhoStats
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Row(
          children: [
            const Icon(Icons.people_alt, color: AppColors.primary, size: 30),
            const SizedBox(width: AppSizes.paddingL),
            Text(
              'Total Patients : ${patientsByDisease.fold<int>(0, (sum, item) => sum + (item['count'] as int))}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
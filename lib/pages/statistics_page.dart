// lib/pages/statistics_page.dart

import 'package:flutter/material.dart';
import '../services/db_service.dart'; // Pour récupérer les données agrégées
// import 'package:fl_chart/fl_chart.dart'; // Décommenter si vous utilisez fl_chart
import '../widgets/metric_card.dart';
import '../models/country_stats.dart';
import '../widgets/bar_chart_card.dart';
import '../services/who_api_service.dart'; // 💡 AJOUTEZ CET IMPORT
import 'package:intl/intl.dart'; // 👈 NOUVEAU : Pour formater la date

// Assurez-vous d'avoir les constantes AppColors et AppSizes
// class AppColors {
//   static const Color primary = Colors.blue;
//   static const Color background = Color(0xFFF5F5F5);
//   static const Color accent = Colors.orange;
// }

// class AppSizes {
//   static const double paddingL = 16.0;
//   static const double paddingXL = 24.0;
// }

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
  /// Fusionne les données locales des patients avec les statistiques OMS.
List<Map<String, dynamic>> _getMergedCountryData() {
  // Créer un Map pour un accès rapide aux stats WHO par code pays
  final Map<String, CountryStats> whoStatsMap = {};
  for (var stat in whoStats) {
    // Utiliser le code pays (si unique ou prendre la dernière entrée)
    // Ici, nous supposons que whoStats a déjà été filtré ou trié pour la pertinence
    whoStatsMap[stat.countryCode] = stat;
  }
  final List<Map<String, dynamic>> mergedData = [];

  // Parcourir les données locales des patients (patientsByCountry)
  for (var patientData in patientsByCountry) {
    final String countryCode = patientData['code'] as String? ?? '??'; // Code pays par défaut
    final int patientCount = patientData['count'] as int? ?? 0;        // 0 patient par défaut
    final String countryName = patientData['pays'] as String? ?? 'Pays Inconnu'; // Nom du pays
    
    // Initialiser les valeurs WHO à zéro ou null
    double whoValue = 0.0;
    String whoIndicator = '';

    // Tenter de trouver la stat WHO correspondante
    final CountryStats? whoStat = whoStatsMap[countryCode];

    if (whoStat != null) {
      whoValue = whoStat.value;
      whoIndicator = whoStat.indicator;
    }

    // Ajouter les données fusionnées
    mergedData.add({
      'country': patientData['pays'], // Nom du pays
      'local_count': patientCount,   // Nombre de patients locaux
      'who_value': whoValue,         // Taux de mortalité WHO
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
      await _syncWhoData();
      // 2. Récupération des stats patient locales
      final List<Map<String, dynamic>> countryData = await DatabaseService
          .instance
          .getPatientsByCountry();
      final List<Map<String, dynamic>> diseaseData = await DatabaseService
          .instance
          .getPatientsByDisease();
      // 💡 NOUVEAU : Récupérer les stats de l'OMS MAJ (après la synchro)
      final List<CountryStats> newWhoStats = await DatabaseService.instance
          .getCountryStats();
      // await _syncWhoData();

      if (mounted) {
        setState(() {
          patientsByCountry = countryData;
          patientsByDisease = diseaseData;
          whoStats = newWhoStats; // ⬅️ ASSUREZ-VOUS QUE C'EST BIEN FAIT
          // Calculer les métadonnées WHO
          if (whoStats.isNotEmpty) {
            // Trouver la date de mise à jour la plus récente (s'assurer qu'elle est un DateTime)
            final lastUpdatedStat = whoStats.reduce(
              (a, b) => a.lastUpdated.isAfter(b.lastUpdated) ? a : b,
            );

            _lastWhoSyncDate = lastUpdatedStat.lastUpdated;

            // Compter le nombre de codes pays uniques mis à jour
            _uniqueCountryStatsCount = whoStats
                .map((s) => s.countryCode)
                .toSet()
                .length;
          } else {
            // Si whoStats est vide après la synchro, s'assurer que l'état reflète cela.
            _lastWhoSyncDate = null;
            _uniqueCountryStatsCount = 0;
          }

          isLoading = false;
        });
      }
    } catch (e) {
      // Gérer l'erreur (e.g., afficher un message d'erreur à l'utilisateur)
      print("Erreur lors du chargement des statistiques: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 💡 NOUVELLE FONCTION : Logique de Synchronisation Externe
  // ----------------------------------------------------
  Future<void> _syncWhoData() async {
    print('🔄 Démarrage de la synchronisation des données WHO...');
    // ✅ LA PAGE N'APPELLE QU'UNE SEULE MÉTHODE DE SYNCHRO
    await WHOApiService.instance.syncAndSaveCancerStats();
    // 1. Appeler le service API pour récupérer les données (avec internet ou test data)
    final List<CountryStats> newStats = await WHOApiService.instance
        .getCancerStatsByCountry();
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

  // ----------------------------------------------------
  // WIDGETS DE CONSTRUCTION
  // ----------------------------------------------------

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

  /// Placeholder pour un graphique (sera remplacé par un BarChart, PieChart, etc.)
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
    // Assurez-vous que la variable whoStats est bien peuplée dans _loadStatistics()
    if (whoStats.isEmpty) {
      return const SizedBox.shrink(); // Ne rien afficher si aucune donnée WHO
    }

    // Trier les statistiques par pays pour une meilleure lisibilité
    whoStats.sort((a, b) => a.countryName.compareTo(b.countryName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Taux de Mortalité OMS par Pays'),
        const SizedBox(height: 10),

        // Liste des détails par pays
        ...whoStats.map((stat) {
          // Formate la valeur du taux de mortalité
          final formattedValue = NumberFormat.decimalPattern().format(
            stat.value,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Card(
              elevation: 1,
              child: ListTile(
                title: Text(
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
                subtitle: Text('Indicateur: ${stat.indicator}'),
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

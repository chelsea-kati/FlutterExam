import 'package:flutter/material.dart';
import '../utils/constants.dart' as constants;
import '../widgets/metric_card.dart';
import '../widgets/patient_card.dart';
import '../models/patient.dart';
import '../services/db_service.dart';
import '../pages/patient_detail.dart';
import '../services/sync_service.dart';
import '../models/country_stats.dart';
import '../services/who_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Variables pour les données dynamiques
  List<Patient> _patients = [];
  int _patientCount = 0;
  bool _isLoading = true;
  List<CountryStats> _whoStats = [];
  bool _isOnline = true;
  DateTime? _lastSyncDate;

  // Map des drapeaux pour chaque pays
  final Map<String, String> _countryFlags = {
    'Burundi': '🇧🇮',
    'Rwanda': '🇷🇼',
    'Kenya': '🇰🇪',
    'Tanzania': '🇹🇿',
    'Uganda': '🇺🇬',
    'Ethiopia': '🇪🇹',
    'Somalia': '🇸🇴',
    'South Sudan': '🇸🇸',
    'DR Congo': '🇨🇩',
    'Mozambique': '🇲🇿',
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Méthode centralisée pour initialiser toutes les données
  Future<void> _initializeData() async {
    await _checkConnectionAndLoad();
    await _loadWhoStats(); // Maintenant avec await
    DatabaseService.instance.debugPrintAllData();
  }

  Future<void> _checkConnectionAndLoad() async {
    try {
      final hasInternet = await WHOApiService.instance.hasInternetConnection();
      setState(() {
        _isOnline = hasInternet;
      });
      
      if (hasInternet) {
        final apiPatients = await WHOApiService.instance.getPatients();
        setState(() {
          _patients = apiPatients;
          _patientCount = apiPatients.length;
          _isLoading = false;
          _lastSyncDate = DateTime.now();
        });
      } else {
        await _loadData();
        if (_patients.isNotEmpty) {
          setState(() {
            _lastSyncDate = _patients.first.dateCreation;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur de connexion ou chargement: $e');
      await _loadData();
    }
  }

  Future<void> _loadWhoStats() async {
    try {
      print('🔄 Début chargement statistiques WHO...');
      final syncService = SyncService.instance;
      final stats = await syncService.getStats();
      
      print('📊 Statistiques brutes reçues: ${stats.length}');
      for (var stat in stats) {
        print('  - ${stat.countryName}: ${stat.value}');
      }

      setState(() {
        _whoStats = stats.take(10).toList();
      });
      
      print('✅ ${_whoStats.length} statistiques affichées');
    } catch (e) {
      print('❌ Erreur chargement stats WHO: $e');
      setState(() {
        _whoStats = [];
      });
    }
  }

  // Charger les données depuis SQLite
  Future<void> _loadData() async {
    try {
      final dbService = DatabaseService.instance;
      final patients = await dbService.getAllPatients();
      final count = await dbService.getPatientCount();
      print('DEBUG: Nombre de patients lu depuis la DB: $count');

      setState(() {
        _patients = patients;
        _patientCount = count;
        _isLoading = false;
      });
      
      for (final patient in _patients) {
        print('Patient: ${patient.nomComplet}, Maladie: ${patient.maladie}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              AppConstants.appSlogan,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
            ),
            if (!_isOnline && _lastSyncDate != null)
              Text(
                'Données du ${_lastSyncDate!.toLocal().toString().split(' ')[0]} (hors-ligne)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFEAF4F4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _initializeData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bannière de bienvenue
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Bienvenue ! Suivi personnalisé pour vos patients",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Aperçu
                      Text(
                        'Aperçu Général',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      // Grille des métriques
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSizes.paddingM,
                        mainAxisSpacing: AppSizes.paddingM,
                        childAspectRatio: 1.1,
                        children: [
                          MetricCard(
                            title: 'Patients Actifs',
                            value: '$_patientCount',
                            subtitle: 'Total enregistrés',
                            color: AppColors.tealCard,
                            icon: Icons.people_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$_patientCount patients enregistrés',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          MetricCard(
                            title: 'Consultations',
                            value: '$_patientCount',
                            subtitle: 'Total enregistrés',
                            color: AppColors.purpleCard,
                            icon: Icons.medical_services_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Consultations du jour - En développement!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          MetricCard(
                            title: 'Suivi Mental',
                            value: '$_patientCount',
                            subtitle: 'Total enregistrés',
                            color: AppColors.greenCard,
                            icon: Icons.psychology_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Suivi mental - Fonctionnalité bientôt disponible!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          MetricCard(
                            title: 'Urgences',
                            value: '$_patientCount',
                            subtitle: 'Total enregistrés',
                            color: AppColors.orangeCard,
                            icon: Icons.emergency_rounded,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Gestion des urgences - En cours de développement!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.paddingXL),

                      // Section Patients récents
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Patients Récents',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/patients');
                            },
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      // Liste des patients récents
                      _patients.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'Aucun patient trouvé. Ajoutez-en un !',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _patients.length > 5
                                  ? 5
                                  : _patients.length,
                              itemBuilder: (context, index) {
                                final patient = _patients[index];
                                return PatientCard(
                                  name: patient.nomComplet,
                                  condition: patient.maladie,
                                  lastVisit: patient.derniereVisite != null
                                      ? '${DateTime.now().difference(patient.derniereVisite!).inDays} jour(s)'
                                      : 'Première visite',
                                  status: patient.statut,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PatientDetailPage(patient: patient),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                      const SizedBox(height: AppSizes.paddingXL),

                      // Section Statistiques par pays avec drapeaux
                      Text(
                        'Statistiques par Pays',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSizes.paddingM),

                      // Affichage des statistiques WHO avec drapeaux
                      _whoStats.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.signal_wifi_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Aucune statistique WHO disponible.',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (!_isOnline)
                                      Text(
                                        'Mode hors-ligne',
                                        style: TextStyle(
                                          color: Colors.red[400],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: _whoStats.map((stat) {
                                final flag = _countryFlags[stat.countryName] ?? '🌍';
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSizes.paddingL,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                // Drapeau du pays
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      flag,
                                                      style: const TextStyle(
                                                        fontSize: 28,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      stat.countryName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Année: ${stat.year}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${stat.value.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Barre de progression
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: (stat.value / 300).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            backgroundColor:
                                                AppColors.surfaceVariant,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                      // Espacement pour le FAB
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  final String name;
  final String condition;
  final String lastVisit;
  final String status;
  final VoidCallback onTap;

  const PatientCard({
    Key? key,
    required this.name,
    required this.condition,
    required this.lastVisit,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        onTap: onTap,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Condition: $condition'),
            Text('Dernière visite: $lastVisit'),
          ],
        ),
        trailing: Text(
          status,
          style: TextStyle(
            color: status == 'Critique'
                ? Colors.red
                : status == 'Stable'
                    ? Colors.orange
                    : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
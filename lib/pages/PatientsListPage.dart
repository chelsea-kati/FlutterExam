import 'package:flutter/material.dart';
import '../models/patient.dart'; // Assurez-vous d'avoir ce modèle
import '../services/db_service.dart'; // Pour interagir avec SQLite
import '../pages/patient_detail.dart'; // Pour l'édition (supposé être la page de détail/édition)
//import '../utils/constants.dart'; // Pour les couleurs (AppColors, à adapter)
import '../widgets/metric_card.dart'; // Pour l'édition (supposé être la page de détail/édition)

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  static const String routeName = '/patients';

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  List<Patient> _allPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPatients();
  }

  // Fonction pour charger TOUS les patients
  Future<void> _loadAllPatients() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Utilise la méthode qui récupère TOUS les patients (triés par date, du plus récent au plus ancien)
      final patients = await DatabaseService.instance.getAllPatients();
      
      if (mounted) {
        setState(() {
          _allPatients = patients;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de tous les patients: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 💡 Gestion de la suppression d'un patient
  Future<void> _deletePatient(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation de suppression'),
        content: Text('Voulez-vous vraiment supprimer le patient $name ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final rows = await DatabaseService.instance.deletePatient(id);
      if (rows > 0) {
        // Recharge la liste et affiche un message de succès
        _loadAllPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🗑️ Patient $name supprimé avec succès!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Erreur lors de la suppression.')),
        );
      }
    }
  }

  // 💡 Navigation vers la page de détail/édition (Update)
  void _navigateToEditPatient(Patient patient) async {
    // Navigue vers la page de détail. On attend le résultat.
    // Si la page de détail renvoie 'true' (par exemple, après une sauvegarde/édition), on rafraîchit la liste.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailPage(patient: patient),
      ),
    );
    
    // Si le résultat est un booléen et qu'il est 'true' (édition effectuée)
    if (result == true) {
      _loadAllPatients(); 
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les Patients'),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllPatients,
              child: _allPatients.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Aucun patient trouvé. Enregistrez un nouveau patient pour commencer.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _allPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _allPatients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                patient.prenom[0], // Initiale du prénom
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              '${patient.nom} ${patient.prenom}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Maladie: ${patient.maladie} | Âge: ${patient.age} ans'),
                            
                            // 💡 Boutons d'action dans le trailing
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton Modifier (Update)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  tooltip: 'Modifier',
                                  onPressed: () => _navigateToEditPatient(patient),
                                ),
                                // Bouton Supprimer (Delete)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _deletePatient(
                                    patient.id!,
                                    '${patient.prenom} ${patient.nom}',
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _navigateToEditPatient(patient),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// ------------------------------------------------------------------------
// IMPORTANT : N'oubliez pas de mettre à jour la navigation dans home_page.dart
// ------------------------------------------------------------------------
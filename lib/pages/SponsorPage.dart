// lib/pages/sponsor_page.dart

import 'package:flutter/material.dart';
import '../models/sponsor.dart';
import '../services/sponsor_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/metric_card.dart';

class SponsorPage extends StatefulWidget {
  const SponsorPage({super.key});

  @override
  State<SponsorPage> createState() => _SponsorPageState();
}

class _SponsorPageState extends State<SponsorPage> {
  // Référence au service Singleton
  late Future<List<Sponsor>> _sponsorsFuture;

  @override
  void initState() {
    super.initState();
    // Initialiser le chargement des sponsors
    _sponsorsFuture = SponsorService.instance.getSponsors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Sponsors'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Sponsor>>(
        future: _sponsorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Afficher un indicateur pendant le chargement
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Afficher une erreur
            return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Aucune donnée
            return const Center(child: Text('Aucun sponsor trouvé pour le moment.'));
          } else {
            // Afficher la liste des sponsors
            final sponsors = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sponsors.length,
              itemBuilder: (context, index) {
                return SponsorCard(sponsor: sponsors[index]);
              },
            );
          }
        },
      ),
    );
  }
}

// Widget pour afficher un sponsor individuel
class SponsorCard extends StatelessWidget {
  final Sponsor sponsor;

  const SponsorCard({super.key, required this.sponsor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo et Nom
            Row(
              children: [
                // Simuler l'image du logo (utilisez Image.asset si vous ajoutez des assets)
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight, // Couleur de fond si l'image n'est pas chargée
                  child: ClipOval( // Pour s'assurer que l'image est bien coupée en cercle
                  child: Image.asset(
                    sponsor.imageUrl, // C'est ici que le chemin 'assets/images/logo_*.png' est utilisé
                    width: 60,  // 2 * radius
                    height: 60, // 2 * radius
                    fit: BoxFit.cover,// Assure que l'image couvre l'espace
                    // Gestion d'erreur (si l'asset n'est pas trouvé)
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.people_rounded,
                        size: 30,
                        color: Colors.grey[400]);
                    },
                  ),
                      ),
                ),
                const SizedBox(width: 16),         
                Expanded(
                 child: Text(
                  sponsor.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                  maxLines:2,
                  overflow: TextOverflow.ellipsis,
                ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Description
            Text(
              sponsor.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            // Lien vers le site web
            InkWell(
              // TODO: Implémenter le lancement d'URL (package url_launcher)
              onTap: ()  async{
                // La fonction pour lancer l'URL
                final Uri url = Uri.parse(sponsor.websiteUrl);
                // Vérifiez si l'URL peut être lancée sur la plateforme actuelle
                if (await canLaunchUrl(url)) {
                  // await launchUrl(url); si oui, lancez-la
                } else {
                  // Sinon, affichez une erreur (Snack Bar)
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Impossible d\'ouvrir le lien: ${sponsor.websiteUrl}')),
                    );
                  }
                }
              },
              child: Text(
                'Visiter le site',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
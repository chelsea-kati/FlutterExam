// lib/services/ai_chat_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/patient.dart';
import '../services/db_service.dart'; // <--- CETTE LIGNE EST ESSENTIELLE

class AIChatService {
  static final AIChatService instance = AIChatService._internal();
  AIChatService._internal();

  // 🔑 MÊME CLÉ QUE AI_SERVICE
  static const String _apiKey = 'AIzaSyA9KlGdCICCiPJS9YAHu_8P2JXXix_vUQw';

  // late final GenerativeModel _model;
  GenerativeModel? _model; // MODIFIÉ : Rendu optionnel
  // late final ChatSession _chatSession;
  ChatSession? _chatSession; // MODIFIÉ : Rendu optionnel
  Patient? _currentPatient;

  // Initialiser le chat pour un patient spécifique
  void initializeChat(Patient patient) {
    // _currentPatient = patient;

    // _model = GenerativeModel(
    //   model: 'gemini-pro',
    //   apiKey: _apiKey,
    //   generationConfig: GenerationConfig(
    //     temperature: 0.7,
    //     topK: 40,
    //     topP: 0.95,
    //     maxOutputTokens: 1024,
    //   ),
    // );
    // Vérifie si la session est déjà initialisée pour ce patient
    if (_currentPatient != null &&
        _currentPatient!.id == patient.id &&
        _chatSession != null) {
      return; // Ne fait rien si c'est le même patient et la session est active
    }

    _currentPatient = patient;

    // 💡 S'assurer que _model est initialisé une seule fois pour tous les patients
    if (_model == null) {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );
    }

    // Contexte initial du patient pour l'IA
    final systemPrompt =
        '''
Tu es un assistant médical virtuel expert et bienveillant.

Informations du patient actuel :
- Nom : ${patient.nomComplet}
- Âge : ${patient.age} ans
- Pays : ${patient.pays}
- Diagnostic : ${patient.maladie}
- Conseils actuels : ${patient.conseils ?? 'Aucun'}

Consignes IMPORTANTES :
1. Réponds TOUJOURS en français simple
2. Sois empathique et rassurant
3. Adapte tes réponses à ${patient.maladie}
4. Considère le contexte africain (${patient.pays})
5. Pour les médicaments, donne des conseils généraux mais rappelle de consulter le médecin
6. Si question dangereuse/urgente, recommande immédiatement de consulter
7. Reste dans ton domaine médical, ne réponds pas aux questions hors sujet
8. Limite tes réponses à 3-4 phrases maximum

Tu es prêt à répondre aux questions du patient.
''';

    _chatSession = _model!.startChat(
      history: [
        Content.text(systemPrompt),
        Content.model([
          TextPart(
            'Je comprends. Je suis prêt à aider ${patient.prenom} avec des conseils médicaux adaptés à ${patient.maladie}.',
          ),
        ]),
      ],
    );
  }

  // Envoyer un message au chatbot
  Future<ChatResponse> sendMessage(String userMessage) async {
    if (_currentPatient == null) {
      throw Exception(
        'Chat non initialisé. Appelez initializeChat() d\'abord.',
      );
    }

    if (_apiKey == 'AIzaSyA9KlGdCICCiPJS9YAHu_8P2JXXix_vUQw') {
      // Mode offline - réponses prédéfinies
      return _getOfflineResponse(userMessage);
    }

    try {
      print('👤 User: $userMessage');

      final content = Content.text(userMessage);
      final response = await _chatSession!.sendMessage(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Réponse vide de l\'IA');
      }

      print('🤖 AI: ${response.text}');

      return ChatResponse(
        message: response.text!,
        isFromUser: false,
        timestamp: DateTime.now(),
        source: MessageSource.ai,
      );
    } catch (e) {
      print('❌ Erreur chat IA: $e');
      return _getOfflineResponse(userMessage);
    }
  }

  // Réponses offline basées sur mots-clés
  ChatResponse _getOfflineResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    String response;

    // Détection par mots-clés (votre code original, inchangé)
    if (lowerMessage.contains('médicament') ||
        lowerMessage.contains('medicament') ||
        lowerMessage.contains('traitement') ||
        lowerMessage.contains('pilule')) {
      response =
          'Pour les médicaments de ${_currentPatient!.maladie}, il est essentiel de les prendre régulièrement aux heures prescrites. Ne jamais arrêter sans avis médical. En cas d\'oubli, consultez la notice ou votre médecin.';
    } else if (lowerMessage.contains('manger') ||
        lowerMessage.contains('aliment') ||
        lowerMessage.contains('nutrition') ||
        lowerMessage.contains('nourriture')) {
      response =
          'Pour ${_currentPatient!.maladie}, privilégiez les fruits frais, légumes, et évitez les aliments transformés. Buvez beaucoup d\'eau. Une alimentation équilibrée aide au traitement.';
    } else {
      response =
          'Je peux vous aider avec des questions sur les médicaments, l\'alimentation, l\'exercice, ou la gestion de ${_currentPatient!.maladie}. N\'hésitez pas à me poser une question précise.';
    }

    return ChatResponse(
      message: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      source: MessageSource.local,
    );
  }

  // =======================================================================
  // NOUVELLE MÉTHODE POUR GÉNÉRER LES CONSEILS (REMPLACE L'ANCIENNE)
  // =======================================================================
  Future<AdviceResponse> generateAdvice(Patient patient) async {
    if (_apiKey == 'AIzaSyA9KlGdCICCiPJS9YAHu_8P2JXXix_vUQw') {
      print('🔧 Mode offline : Utilisation des conseils locaux.');
      return _getLocalAdviceFallback(patient); // Appel de la méthode renommée
    }

    final model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);

    final prompt =
        '''
      Génère une liste de 4 conseils de santé courts, pratiques et faciles à suivre pour un patient avec le profil suivant :
      - Diagnostic : ${patient.maladie}
      - Âge : ${patient.age} ans
      - Pays : ${patient.pays}
      Instructions :
      1. Les conseils doivent être directement applicables dans un contexte africain (${patient.pays}).
      2. Formule chaque conseil en une seule phrase simple.
      3. Retourne UNIQUEMENT la liste des conseils, sans introduction ni conclusion.
      4. Sépare chaque conseil par un retour à la ligne.
      ''';

    try {
      print('✨ Envoi de la requête de conseils à l\'IA...');
      final content = Content.text(prompt);
      final response = await model.generateContent([content]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Réponse vide de l\'IA');
      }

      final adviceList = response.text!
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.startsWith('- ') ? s.substring(2) : s)
          .toList();

      print('✅ Conseils IA reçus : ${adviceList.length} éléments');

      patient.conseils = adviceList.join('\n');
      await DatabaseService.instance.updatePatient(patient);

      // Ici, on appelle le constructeur de la classe AdviceResponse, c'est correct
      return AdviceResponse(advice: adviceList, source: MessageSource.ai);
    } catch (e) {
      print('❌ Erreur lors de la génération de conseils IA: $e');
      return _getLocalAdviceFallback(patient); // Appel de la méthode renommée
    }
  }

  // =======================================================================
  // MÉTHODE RENOMMÉE POUR ÉVITER LE CONFLIT (REMPLACE _getOfflineAdvice)
  // =======================================================================
  AdviceResponse _getLocalAdviceFallback(Patient patient) {
    List<String> advice;
    final lowerDisease = patient.maladie.toLowerCase();

    if (lowerDisease.contains('diabète')) {
      advice = [
        'Contrôlez votre glycémie chaque jour avant le petit-déjeuner.',
        'Marchez 30 minutes au moins 5 fois par semaine.',
        'Privilégiez les aliments locaux riches en fibres comme le manioc ou l\'igname.',
        'Buvez beaucoup d\'eau pure et évitez les boissons sucrées.',
      ];
    } else if (lowerDisease.contains('hypertension')) {
      advice = [
        'Réduisez votre consommation de sel et de cubes de bouillon.',
        'Consommez des fruits comme la banane, riche en potassium.',
        'Essayez de vous détendre quelques minutes chaque jour par la respiration.',
        'Prenez votre traitement chaque jour à la même heure, même si vous vous sentez bien.',
      ];
    } else {
      advice = [
        'Buvez au moins 1.5 litre d\'eau par jour pour rester hydraté.',
        'Assurez-vous de bien dormir entre 7 et 8 heures par nuit.',
        'Mangez des repas équilibrés avec des légumes et des fruits locaux.',
        'Parlez à un professionnel de santé avant de prendre un nouveau médicament.',
      ];
    }

    patient.conseils = advice.join('\n');
    DatabaseService.instance.updatePatient(patient);

    // Ici, on appelle le constructeur de la classe AdviceResponse, c'est correct
    return AdviceResponse(advice: advice, source: MessageSource.local);
  }

  // Suggestions de questions
  List<String> getSuggestedQuestions() {
    if (_currentPatient == null) return [];
    return [
      'Comment prendre mes médicaments ?',
      'Quels aliments sont bons pour moi ?',
      'Que faire en cas de douleur ?',
      'Quels exercices puis-je faire ?',
      'Comment gérer la fatigue ?',
      'Que faire en cas d\'urgence ?',
    ];
  }

  // Obtenir l'historique du chat
  int getMessageCount() {
    return 0; // Placeholder
  }

  // Réinitialiser le chat
  void resetChat() {
    if (_currentPatient != null) {
      initializeChat(_currentPatient!);
    }
  }
}

// Modèle pour les réponses du chat
class ChatResponse {
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageSource source;

  ChatResponse({
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    required this.source,
  });
}

// Modèle pour le retour des conseils (correspond à 'result')
class AdviceResponse {
  final List<String> advice;
  final MessageSource source;

  AdviceResponse({required this.advice, required this.source});
}

enum MessageSource {
  ai, // Réponse de l'IA Gemini
  local, // Réponse locale prédéfinie
  user, // Message de l'utilisateur
}

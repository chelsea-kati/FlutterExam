// lib/pages/ai_chat_page.dart

import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/ai_chat_service.dart';


class AIChatPage extends StatefulWidget {
  final Patient patient;

  const AIChatPage({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    AIChatService.instance.initializeChat(widget.patient);

    // Message de bienvenue
    _messages.add(ChatMessage(
      text: 'Bonjour ${widget.patient.prenom} 👋\n\nJe suis votre assistant médical virtuel. Je peux répondre à vos questions sur ${widget.patient.maladie}, les médicaments, l\'alimentation et plus encore.\n\nComment puis-je vous aider aujourd\'hui ?',
      isFromUser: false,
      timestamp: DateTime.now(),
      source: MessageSource.ai,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getPatientColor() {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    final index = widget.patient.nom.hashCode % colors.length;
    return colors[index.abs()];
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isFromUser: true,
        timestamp: DateTime.now(),
        source: MessageSource.user,
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await AIChatService.instance.sendMessage(userMessage);

      setState(() {
        _messages.add(ChatMessage(
          text: response.message,
          isFromUser: false,
          timestamp: response.timestamp,
          source: response.source,
        ));
        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Désolé, une erreur est survenue. Réessayez.',
          isFromUser: false,
          timestamp: DateTime.now(),
          source: MessageSource.local,
        ));
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendSuggestedQuestion(String question) {
    _messageController.text = question;
    _sendMessage(question);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = AIChatService.instance.getSuggestedQuestions();
    final patientColor = _getPatientColor();

    return Scaffold(
      body: Column(
        children: [
          // En-tête personnalisé avec photo du patient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [patientColor, patientColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: patientColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Bouton retour
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),

                    // Photo du patient
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.patient.prenom[0].toUpperCase() +
                              widget.patient.nom[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: patientColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Infos patient
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.nomComplet,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Assistant IA en ligne',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bouton options
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Options du chat'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.refresh),
                                  title: const Text('Réinitialiser'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _messages.clear();
                                      AIChatService.instance.resetChat();
                                      _messages.add(ChatMessage(
                                        text: 'Conversation réinitialisée.',
                                        isFromUser: false,
                                        timestamp: DateTime.now(),
                                        source: MessageSource.ai,
                                      ));
                                    });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.info_outline),
                                  title: const Text('À propos'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Assistant IA propulsé par Gemini',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(message: message, patientColor: patientColor);
                },
              ),
            ),
          ),

          // Indicateur de frappe
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: patientColor.withOpacity(0.1),
                    child: Icon(Icons.smart_toy, size: 16, color: patientColor),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(delay: 0, color: patientColor),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 200, color: patientColor),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 400, color: patientColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Questions suggérées
          if (_messages.length == 1 && suggestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Questions suggérées',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((question) {
                      return InkWell(
                        onTap: () => _sendSuggestedQuestion(question),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: patientColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: patientColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            question,
                            style: TextStyle(
                              fontSize: 12,
                              color: patientColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Bouton emoji/options
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.emoji_emotions_outlined,
                          color: Colors.grey.shade600),
                      onPressed: () {
                        // TODO: Afficher sélecteur emoji
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Champ de texte
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Posez votre question...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Bouton envoyer
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [patientColor, patientColor.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: patientColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour une bulle de message
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Color patientColor;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.patientColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.source == MessageSource.ai
                  ? patientColor.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              child: Icon(
                message.source == MessageSource.ai
                    ? Icons.smart_toy
                    : Icons.lightbulb,
                size: 16,
                color: message.source == MessageSource.ai
                    ? patientColor
                    : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isFromUser
                    ? patientColor
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isFromUser ? 20 : 4),
                  topRight: Radius.circular(message.isFromUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          message.isFromUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: message.isFromUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.withOpacity(0.1),
              child: const Icon(Icons.person, size: 16, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget pour l'animation de frappe
class _TypingDot extends StatefulWidget {
  final int delay;
  final Color color;

  const _TypingDot({required this.delay, required this.color});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// Modèle pour un message de chat
class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageSource source;

  ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.source,
  });
}
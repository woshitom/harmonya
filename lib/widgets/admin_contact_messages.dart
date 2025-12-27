import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';

class AdminContactMessages extends StatelessWidget {
  const AdminContactMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebaseService.getContactMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(child: Text('Aucun message'));
        }

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isRead = message['read'] as bool? ?? false;
            final isAnswered = message['answered'] as bool? ?? false;
            final name = message['name'] as String? ?? 'Sans nom';
            final messageText = message['message'] as String? ?? '';
            final contactMethod = message['contactMethod'] as String? ?? '';
            final email = message['email'] as String?;
            final phone = message['phone'] as String?;
            final createdAt = message['createdAt'];
            final messageId = message['id'] as String? ?? '';

            String formattedDate = '';
            if (createdAt != null) {
              try {
                final timestamp = createdAt;
                DateTime dateTime;
                if (timestamp is DateTime) {
                  dateTime = timestamp;
                } else {
                  dateTime = timestamp.toDate();
                }
                formattedDate = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                    .format(dateTime);
              } catch (e) {
                formattedDate = 'Date inconnue';
              }
            }

            String contactInfo = '';
            if (contactMethod == 'email' && email != null) {
              contactInfo = 'Email: $email';
            } else if (contactMethod == 'phone' && phone != null) {
              contactInfo = 'Téléphone: $phone';
            } else if (contactMethod == 'no_answer') {
              contactInfo = 'Pas de réponse nécessaire';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isRead ? 1 : 3,
              color: isRead ? Colors.white : Colors.blue.shade50,
              child: InkWell(
                onTap: () {
                  if (!isRead) {
                    firebaseService.markContactMessageAsRead(messageId);
                  }
                  _showMessageDetails(context, message);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isRead ? Colors.grey : Colors.black,
                                  ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Nouveau',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isAnswered)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Répondu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                      if (contactInfo.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              contactMethod == 'email'
                                  ? Icons.email
                                  : contactMethod == 'phone'
                                      ? Icons.phone
                                      : Icons.info_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              contactInfo,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        messageText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isRead ? Colors.grey.shade700 : Colors.black87,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMessageDetails(BuildContext context, Map<String, dynamic> message) {
    final firebaseService = FirebaseService();
    final name = message['name'] as String? ?? 'Sans nom';
    final messageText = message['message'] as String? ?? '';
    final contactMethod = message['contactMethod'] as String? ?? '';
    final email = message['email'] as String?;
    final phone = message['phone'] as String?;
    final createdAt = message['createdAt'];
    final isAnswered = message['answered'] as bool? ?? false;
    final answer = message['answer'] as String?;
    final messageId = message['id'] as String? ?? '';

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final timestamp = createdAt;
        DateTime dateTime;
        if (timestamp is DateTime) {
          dateTime = timestamp;
        } else {
          dateTime = timestamp.toDate();
        }
        formattedDate =
            DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(dateTime);
      } catch (e) {
        formattedDate = 'Date inconnue';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (formattedDate.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (contactMethod == 'email' && email != null) ...[
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (contactMethod == 'phone' && phone != null) ...[
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (contactMethod == 'no_answer') ...[
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Pas de réponse nécessaire',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Message:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                messageText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isAnswered && answer != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.reply, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Réponse:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    answer,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (contactMethod == 'email' && !isAnswered)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showReplyDialog(context, messageId, email ?? '', name);
              },
              icon: const Icon(Icons.reply),
              label: const Text('Répondre'),
            ),
          if (contactMethod == 'phone' && !isAnswered)
            TextButton.icon(
              onPressed: () async {
                try {
                  await firebaseService.markContactMessageAsAnswered(messageId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message marqué comme répondu'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Marquer comme répondu'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, String messageId, String email, String name) {
    final answerController = TextEditingController();
    final firebaseService = FirebaseService();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async {
              answerController.dispose();
              return true;
            },
            child: AlertDialog(
              title: const Text('Répondre au message'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('À: $email'),
                    Text('De: $name'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answerController,
                      decoration: const InputDecoration(
                        labelText: 'Votre réponse *',
                        hintText: 'Entrez votre réponse...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                      minLines: 5,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          answerController.dispose();
                          Navigator.of(context).pop();
                        },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (answerController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez entrer une réponse'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSubmitting = true;
                          });

                          try {
                            await firebaseService.answerContactMessage(
                              messageId,
                              answerController.text.trim(),
                            );

                            answerController.dispose();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Réponse envoyée avec succès'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Envoyer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


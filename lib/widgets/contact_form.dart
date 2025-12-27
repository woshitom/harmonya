import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ContactForm extends StatefulWidget {
  final bool isSmallScreen;

  const ContactForm({super.key, required this.isSmallScreen});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firebaseService = FirebaseService();
  
  String? _contactMethod; // 'email', 'phone', 'no_answer'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firebaseService.createContactMessage(
        name: _nameController.text.trim(),
        message: _messageController.text.trim(),
        contactMethod: _contactMethod,
        email: _contactMethod == 'email' ? _emailController.text.trim() : null,
        phone: _contactMethod == 'phone' ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text('Message envoyé'),
              ],
            ),
            content: const Text('Votre message a été envoyé avec succès. Nous vous répondrons dans les plus brefs délais.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Reset form
                  _formKey.currentState!.reset();
                  _nameController.clear();
                  _messageController.clear();
                  _emailController.clear();
                  _phoneController.clear();
                  setState(() {
                    _contactMethod = null;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message *',
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre message';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _contactMethod,
            decoration: const InputDecoration(
              labelText: 'Comment souhaitez-vous être contacté ?',
              prefixIcon: Icon(Icons.contact_mail),
            ),
            items: const [
              DropdownMenuItem(
                value: 'email',
                child: Text('Par email'),
              ),
              DropdownMenuItem(
                value: 'phone',
                child: Text('Par téléphone'),
              ),
              DropdownMenuItem(
                value: 'no_answer',
                child: Text('Je n\'ai pas besoin de réponse'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _contactMethod = value;
                // Clear the other field when switching methods
                if (value == 'email') {
                  _phoneController.clear();
                } else if (value == 'phone') {
                  _emailController.clear();
                } else {
                  _emailController.clear();
                  _phoneController.clear();
                }
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner une option';
              }
              return null;
            },
          ),
          // Show email field if "Par email" is selected
          if (_contactMethod == 'email') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!value.contains('@')) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
          ],
          // Show phone field if "Par téléphone" is selected
          if (_contactMethod == 'phone') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitContact,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: widget.isSmallScreen ? 14 : 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Envoyer',
                      style: TextStyle(
                        fontSize: widget.isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


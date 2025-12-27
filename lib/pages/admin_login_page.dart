import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Pop back to root route (AuthWrapper) which will automatically show admin panel
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        // Log detailed error information to console for debugging
        final errorString = e.toString();
        debugPrint('❌ Login error: $errorString');
        debugPrint('   Current URL: ${Uri.base}');
        debugPrint('   Host: ${Uri.base.host}');
        debugPrint('   Port: ${Uri.base.port}');
        
        // Extract user-friendly error message
        String errorMessage = 'Erreur de connexion';
        if (errorString.contains('user-not-found')) {
          errorMessage = 'Aucun compte trouvé avec cet email';
        } else if (errorString.contains('wrong-password')) {
          errorMessage = 'Mot de passe incorrect';
        } else if (errorString.contains('invalid-email')) {
          errorMessage = 'Email invalide';
        } else if (errorString.contains('network-request-failed')) {
          errorMessage = 'Erreur de connexion réseau. Vérifiez votre connexion internet.';
        } else if (errorString.contains('requests-from-referer') || 
                   errorString.contains('are-blocked') ||
                   errorString.contains('403 (Forbidden)')) {
          errorMessage = '⚠️ Localhost bloqué: Les requêtes depuis localhost sont bloquées.\n\n'
                        'Causes possibles:\n'
                        '1. Restrictions de clé API (Google Cloud Console)\n'
                        '   → Ajoutez "http://localhost:*/*" aux restrictions HTTP referrer\n\n'
                        '2. Domaines autorisés (Firebase Console)\n'
                        '   → Ajoutez "localhost" aux domaines autorisés\n\n'
                        'Voir FIREBASE_LOCALHOST_SETUP.md pour les instructions détaillées.';
        } else if (errorString.contains('auth/unauthorized-domain') || 
                   errorString.contains('unauthorized-domain')) {
          errorMessage = 'Domaine non autorisé: ${Uri.base.host} (port ${Uri.base.port}). '
                        'Vérifiez que "localhost" et "127.0.0.1" sont dans les domaines autorisés Firebase.';
        } else {
          errorMessage = 'Erreur de connexion: $errorString';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      // Show dialog to enter email
      final emailController = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Réinitialiser le mot de passe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Entrez votre adresse email pour recevoir un lien de réinitialisation :',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (emailController.text.trim().isNotEmpty) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Envoyer'),
                ),
              ],
            ),
          ),
        ),
      );

      if (result == true && emailController.text.trim().isNotEmpty) {
        await _sendPasswordReset(emailController.text.trim());
      }
    } else {
      // Use email from form
      await _sendPasswordReset(email);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Email envoyé',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Un email de réinitialisation de mot de passe a été envoyé à $email. '
                  'Veuillez vérifier votre boîte de réception et suivre les instructions.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion Admin')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connexion Admin',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _signIn();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

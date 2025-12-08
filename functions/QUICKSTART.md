# Guide de Démarrage Rapide - Python

## Prérequis

- Python 3.11 ou supérieur
- Firebase CLI installé (`npm install -g firebase-tools`)
- Compte Resend (gratuit: https://resend.com)

## Installation en 5 minutes

### 1. Installer les dépendances

```bash
cd functions
pip3 install -r requirements.txt
```

### 2. Configurer Resend

1. Créer un compte sur https://resend.com
2. Obtenir votre API Key depuis le dashboard
3. Configurer la clé :

```bash
firebase functions:config:set resend.api_key="votre-api-key-resend"
```

### 3. Modifier la configuration dans `main.py`

Ouvrez `functions/main.py` et modifiez :

```python
ADMIN_EMAIL = "votre-email@example.com"  # Votre email
FROM_EMAIL = "Harmonya <noreply@votre-domaine.com>"  # Votre domaine vérifié
```

**Note** : Pour les tests, vous pouvez utiliser `onboarding@resend.dev` comme FROM_EMAIL sans vérifier de domaine.

### 4. Déployer

```bash
firebase deploy --only functions
```

### 5. Tester

1. Créer une nouvelle réservation via votre application Flutter
2. Vérifier les logs : `firebase functions:log`
3. Vérifier votre boîte email

## Utilisation du script de configuration

Pour une configuration automatique :

```bash
cd functions
./setup.sh
```

## Structure du code

- `main.py` : Fonction Cloud Function principale
- `send_booking_email()` : Fonction déclenchée automatiquement
- Envoie 2 emails :
  1. **Admin** : Notification avec détails complets
  2. **Client** : Confirmation de réception

## Dépannage

### Erreur "RESEND_API_KEY non configurée"

Vérifiez que la clé est bien configurée :
```bash
firebase functions:config:get
```

### Les emails ne sont pas envoyés

1. Vérifiez les logs : `firebase functions:log`
2. Vérifiez que votre domaine est vérifié dans Resend (ou utilisez `onboarding@resend.dev` pour les tests)
3. Vérifiez que `ADMIN_EMAIL` et `FROM_EMAIL` sont corrects dans `main.py`

### Erreur lors du déploiement

Assurez-vous que :
- Python 3.11+ est installé
- Toutes les dépendances sont installées : `pip3 install -r requirements.txt`
- Vous êtes connecté à Firebase : `firebase login`

## Variables d'environnement

Vous pouvez aussi définir les variables via les secrets Firebase (recommandé pour la production) :

```bash
firebase functions:secrets:set RESEND_API_KEY
firebase functions:secrets:set ADMIN_EMAIL
firebase functions:secrets:set FROM_EMAIL
```

Puis dans `main.py`, les variables seront automatiquement disponibles via `os.environ.get()`.

## Support

- [Documentation Resend](https://resend.com/docs)
- [Documentation Firebase Functions Python](https://firebase.google.com/docs/functions/get-started-2nd-gen)
- [Documentation Firebase Functions](https://firebase.google.com/docs/functions)


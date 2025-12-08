# Firebase Cloud Functions - Harmonya

Ce dossier contient les Cloud Functions Firebase pour envoyer automatiquement des emails lors de nouvelles réservations.

## Langage : Python

## Installation

1. **Installer les dépendances** :
   ```bash
   cd functions
   pip install -r requirements.txt
   ```

2. **Configurer les variables d'environnement** :
   ```bash
   firebase functions:config:set resend.api_key="votre-api-key-resend"
   ```

   Ou modifier directement dans `main.py` :
   ```python
   ADMIN_EMAIL = "votre-email@example.com"
   FROM_EMAIL = "Harmonya <noreply@votre-domaine.com>"
   ```

3. **Déployer** :
   ```bash
   firebase deploy --only functions
   ```

## Structure

- `main.py` : Code principal de la fonction Cloud Function
- `requirements.txt` : Dépendances Python nécessaires
- `.python-version` : Version Python requise (3.11)
- `.gcloudignore` : Fichiers ignorés lors du déploiement

## Fonctionnalités

La fonction `send_booking_email` se déclenche automatiquement lorsqu'un nouveau document est créé dans la collection `bookings` de Firestore.

Elle envoie :
1. **Email à l'administrateur** : Notification avec tous les détails de la réservation
2. **Email au client** : Confirmation de réception de la demande de réservation

## Configuration Resend

1. Créer un compte sur https://resend.com
2. Obtenir votre API Key
3. Vérifier votre domaine (ou utiliser `onboarding@resend.dev` pour les tests)
4. Configurer la clé API dans Firebase

## Test Local

Pour tester localement avant de déployer :

```bash
firebase emulators:start --only functions
```

Puis créer une réservation via l'application Flutter pour déclencher la fonction.

## Logs

Voir les logs dans Firebase Console > Functions > Logs ou via :

```bash
firebase functions:log
```


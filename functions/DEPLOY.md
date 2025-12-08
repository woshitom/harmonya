# Guide de Déploiement - Firebase Functions Python

## Configuration du Trigger Firestore

Pour que la fonction se déclenche automatiquement lors de la création d'un document dans Firestore, vous devez configurer le trigger lors du déploiement.

### Option 1 : Via Firebase CLI (Recommandé)

Lors de l'initialisation avec `firebase init functions`, sélectionnez Python et configurez le trigger Firestore.

### Option 2 : Configuration manuelle dans firebase.json

Créez ou modifiez `firebase.json` à la racine du projet :

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "runtime": "python311",
      "ignore": [
        "*.pyc",
        "__pycache__"
      ]
    }
  ],
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

### Option 3 : Déploiement avec spécification du trigger

```bash
firebase deploy --only functions:send_booking_email
```

## Déploiement

1. **Vérifier la configuration** :
   ```bash
   cd functions
   python3 -c "import firebase_admin; import resend; print('OK')"
   ```

2. **Déployer** :
   ```bash
   firebase deploy --only functions
   ```

3. **Vérifier les logs** :
   ```bash
   firebase functions:log
   ```

## Format de la fonction

La fonction `send_booking_email` utilise le format Firebase Functions 1st gen :

```python
def send_booking_email(event, context):
    # event contient les données Firestore
    # context contient les métadonnées
```

Le format de `event` pour un trigger Firestore :
```python
{
    "value": {
        "name": "projects/.../databases/(default)/documents/bookings/{bookingId}",
        "fields": {
            "name": {"stringValue": "..."},
            "email": {"stringValue": "..."},
            "date": {"timestampValue": "..."},
            # etc.
        }
    }
}
```

## Test

1. Créer une nouvelle réservation via l'application Flutter
2. Vérifier les logs dans Firebase Console
3. Vérifier les emails reçus

## Dépannage

### La fonction ne se déclenche pas

- Vérifiez que le trigger est bien configuré dans Firebase Console
- Vérifiez les logs : `firebase functions:log`
- Vérifiez que la collection s'appelle bien `bookings`

### Erreur d'import

- Vérifiez que toutes les dépendances sont installées : `pip3 install -r requirements.txt`
- Vérifiez la version de Python : `python3 --version` (doit être 3.9+)

### Erreur d'envoi d'email

- Vérifiez que `RESEND_API_KEY` est configurée
- Vérifiez que `FROM_EMAIL` utilise un domaine vérifié dans Resend
- Vérifiez les logs pour les erreurs détaillées


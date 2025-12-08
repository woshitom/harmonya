# Configuration Email pour les Nouvelles Réservations

Ce guide explique comment configurer l'envoi automatique d'emails lorsqu'une nouvelle réservation est créée.

## Options Gratuites Disponibles

### 1. **EmailJS** (Recommandé pour débuter)
- **Gratuit** : 200 emails/mois
- **Avantages** : Facile à configurer, pas besoin de serveur
- **Limite** : 200 emails/mois

### 2. **Resend** (Recommandé pour production)
- **Gratuit** : 3,000 emails/mois
- **Avantages** : Plus d'emails, API moderne, bonne réputation
- **Limite** : 3,000 emails/mois

### 3. **SendGrid**
- **Gratuit** : 100 emails/jour
- **Avantages** : Fiable, bien documenté
- **Limite** : 100 emails/jour

## Solution Recommandée : Firebase Cloud Functions + Resend

**Deux implémentations disponibles :**
- **Python** (recommandé) - Voir section "Implémentation Python" ci-dessous
- **JavaScript** - Voir section "Implémentation JavaScript" ci-dessous

---

## Implémentation Python (Recommandée)

### Étape 1 : Installer Firebase CLI et Python

```bash
npm install -g firebase-tools
firebase login

# Vérifier que Python 3.11+ est installé
python3 --version
```

### Étape 2 : Initialiser Firebase Functions avec Python

```bash
cd /Users/wo.shi.tom/Documents/harmonya
firebase init functions
```

Sélectionnez :
- **Python** comme langage
- Installer les dépendances maintenant

### Étape 3 : Créer un compte Resend

1. Aller sur https://resend.com
2. Créer un compte gratuit
3. Obtenir votre API Key depuis le dashboard
4. Ajouter votre domaine (ou utiliser le domaine de test pour commencer)

### Étape 4 : Configurer la Cloud Function Python

Le fichier `functions/main.py` est déjà créé avec le code nécessaire. Vous devez seulement :

1. **Modifier les variables de configuration** dans `functions/main.py` :
   ```python
   ADMIN_EMAIL = "votre-email@example.com"  # Votre email admin
   FROM_EMAIL = "Harmonya <noreply@votre-domaine.com>"  # Votre domaine vérifié
   ```

2. **Installer les dépendances** :
   ```bash
   cd functions
   pip install -r requirements.txt
   ```

### Étape 5 : Configurer les variables d'environnement

**Option 1 : Via Firebase Config (recommandé)**
```bash
firebase functions:config:set resend.api_key="votre-api-key-resend"
```

**Option 2 : Via variables d'environnement locales (pour tests)**
```bash
export RESEND_API_KEY="votre-api-key-resend"
export ADMIN_EMAIL="votre-email@example.com"
export FROM_EMAIL="Harmonya <noreply@votre-domaine.com>"
```

### Étape 6 : Déployer la fonction

```bash
firebase deploy --only functions
```

### Structure des fichiers Python

```
functions/
├── main.py              # Code principal de la fonction
├── requirements.txt     # Dépendances Python
├── .python-version      # Version Python (3.11)
└── .gcloudignore        # Fichiers à ignorer lors du déploiement
```

---

## Implémentation JavaScript (Alternative)

### Étape 1 : Installer Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Étape 2 : Initialiser Firebase Functions

```bash
cd /Users/wo.shi.tom/Documents/harmonya
firebase init functions
```

Sélectionnez :
- TypeScript ou JavaScript (JavaScript est plus simple)
- Installer les dépendances maintenant

### Étape 3 : Créer un compte Resend

1. Aller sur https://resend.com
2. Créer un compte gratuit
3. Obtenir votre API Key depuis le dashboard
4. Ajouter votre domaine (ou utiliser le domaine de test pour commencer)

### Étape 4 : Configurer la Cloud Function

Créez le fichier `functions/index.js` :

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Resend } = require('resend');

admin.initializeApp();
const resend = new Resend(process.env.RESEND_API_KEY);

exports.sendBookingEmail = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    
    // Email pour l'administrateur
    try {
      await resend.emails.send({
        from: 'Harmonya <noreply@votre-domaine.com>',
        to: 'votre-email@example.com', // Votre email admin
        subject: 'Nouvelle réservation - Harmonya',
        html: `
          <h2>Nouvelle réservation reçue</h2>
          <p><strong>Nom:</strong> ${booking.name}</p>
          <p><strong>Email:</strong> ${booking.email}</p>
          <p><strong>Téléphone:</strong> ${booking.phone}</p>
          <p><strong>Date:</strong> ${booking.date.toDate().toLocaleDateString('fr-FR')}</p>
          <p><strong>Heure:</strong> ${booking.time}</p>
          <p><strong>Type de massage:</strong> ${booking.massageType}</p>
          ${booking.notes ? `<p><strong>Notes:</strong> ${booking.notes}</p>` : ''}
          <p><strong>Statut:</strong> ${booking.status}</p>
        `,
      });
      
      console.log('Email envoyé avec succès');
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email:', error);
    }
    
    // Email de confirmation pour le client (optionnel)
    try {
      await resend.emails.send({
        from: 'Harmonya <noreply@votre-domaine.com>',
        to: booking.email,
        subject: 'Confirmation de votre réservation - Harmonya',
        html: `
          <h2>Merci pour votre réservation !</h2>
          <p>Bonjour ${booking.name},</p>
          <p>Nous avons bien reçu votre demande de réservation :</p>
          <ul>
            <li><strong>Date:</strong> ${booking.date.toDate().toLocaleDateString('fr-FR')}</li>
            <li><strong>Heure:</strong> ${booking.time}</li>
            <li><strong>Type de massage:</strong> ${booking.massageType}</li>
          </ul>
          <p>Nous vous contacterons bientôt pour confirmer votre rendez-vous.</p>
          <p>Cordialement,<br>L'équipe Harmonya</p>
          <p>1 A rue de la poste 67400 ILLKIRCH GRAFFENSTADEN<br>Téléphone: 06 26 14 25 89</p>
        `,
      });
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email client:', error);
    }
    
    return null;
  });
```

### Étape 5 : Installer les dépendances

```bash
cd functions
npm install resend
```

### Étape 6 : Configurer les variables d'environnement

```bash
firebase functions:config:set resend.api_key="votre-api-key-resend"
```

### Étape 7 : Déployer la fonction

```bash
firebase deploy --only functions
```

## Alternative : EmailJS (Plus Simple, Moins d'emails)

Si vous préférez EmailJS (plus simple mais moins d'emails gratuits) :

### Configuration EmailJS

1. Créer un compte sur https://www.emailjs.com
2. Créer un service email (Gmail, Outlook, etc.)
3. Créer un template d'email
4. Obtenir votre Public Key et Service ID

### Code Cloud Function avec EmailJS

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.sendBookingEmail = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    
    const emailData = {
      service_id: 'votre-service-id',
      template_id: 'votre-template-id',
      user_id: 'votre-public-key',
      template_params: {
        to_email: 'votre-email@example.com',
        booking_name: booking.name,
        booking_email: booking.email,
        booking_phone: booking.phone,
        booking_date: booking.date.toDate().toLocaleDateString('fr-FR'),
        booking_time: booking.time,
        booking_type: booking.massageType,
        booking_notes: booking.notes || '',
      }
    };
    
    try {
      await axios.post('https://api.emailjs.com/api/v1.0/email/send', emailData);
      console.log('Email envoyé avec succès');
    } catch (error) {
      console.error('Erreur lors de l\'envoi de l\'email:', error);
    }
    
    return null;
  });
```

## Configuration dans Firebase Console

1. Aller dans Firebase Console > Functions
2. Vérifier que la fonction est déployée
3. Vérifier les logs pour s'assurer que les emails sont envoyés

## Test

1. Créer une nouvelle réservation via le formulaire
2. Vérifier les logs dans Firebase Console > Functions > Logs
3. Vérifier votre boîte email

## Notes Importantes

- **Resend** nécessite de vérifier votre domaine pour envoyer depuis votre propre adresse
- **EmailJS** peut utiliser votre Gmail directement sans vérification de domaine
- Les Cloud Functions Firebase ont un quota gratuit généreux
- Pour Resend, vous pouvez utiliser `onboarding@resend.dev` pour tester sans vérifier de domaine

## Coûts

- **Firebase Cloud Functions** : Gratuit jusqu'à 2 millions d'invocations/mois
- **Resend** : Gratuit jusqu'à 3,000 emails/mois
- **EmailJS** : Gratuit jusqu'à 200 emails/mois

## Support

Pour plus d'informations :
- [Documentation Resend](https://resend.com/docs)
- [Documentation EmailJS](https://www.emailjs.com/docs/)
- [Documentation Firebase Functions](https://firebase.google.com/docs/functions)


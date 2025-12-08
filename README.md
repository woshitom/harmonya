# Harmonya - Site Web de Massage & Bien-être

Application web Flutter pour Harmonya, un salon de massage dédié aux femmes situé à Illkirch-Graffenstaden, France.

🌐 **Site web en ligne** : [https://harmonyamassage.fr](https://harmonyamassage.fr)

## 🌟 Description

Harmonya est une application web moderne permettant aux visiteurs de :
- Découvrir les différents types de massages proposés
- Réserver une séance de massage en ligne (sur place ou à domicile)
- Laisser des avis et consulter les témoignages d'autres clientes
- Acheter des bons cadeaux pour offrir à leurs proches
- Accéder aux informations de contact

Les administrateurs peuvent gérer les réservations, modérer les avis, gérer les clients et les bons cadeaux via un panneau d'administration sécurisé.

## ✨ Fonctionnalités

### Pour les visiteurs
- **Page d'accueil** avec présentation des services et de la praticienne
- **Réservation en ligne** avec :
  - Sélection de date (pas de réservation le dimanche)
  - Sélection d'heure via un tableau horaire (Lun-Ven: 17h-22h, Sam: 10h-20h)
  - Choix du type de massage
  - Option "Massage à domicile" avec frais de transport
  - Vérification automatique des créneaux déjà réservés
- **Système d'avis** permettant de laisser un témoignage avec prénom et nom
- **Affichage des avis approuvés** pour consulter les retours d'autres clientes
- **Achat de bons cadeaux** avec paiement PayPal
- **Informations de contact** (adresse cliquable pour Google Maps, téléphone cliquable)

### Pour les administrateurs
- **Authentification sécurisée** via Firebase Auth avec réinitialisation de mot de passe
- **Gestion des réservations** :
  - Visualisation de toutes les réservations en liste
  - Vue calendrier pour une meilleure organisation
  - Création manuelle de réservations (statut "confirmé" automatique)
  - Modification du statut (en attente, confirmée, annulée)
  - Suppression de réservations
  - Badge indiquant le nombre de réservations en attente
- **Modération des avis** :
  - Consultation des avis en attente d'approbation
  - Approbation ou refus d'avis avec confirmation par dialog
  - Badge indiquant le nombre d'avis en attente
- **Gestion des clients** :
  - Liste de tous les clients
  - Création, modification et suppression de clients
  - Historique des types de massages par client
- **Gestion des bons cadeaux** :
  - Liste de tous les bons cadeaux
  - Suivi du statut (pending, paid, used, expired)
  - Informations sur l'acheteur et le destinataire
- **Navigation** vers la page d'accueil tout en restant connecté

## 🛠️ Technologies utilisées

### Frontend
- **Flutter Web** - Framework de développement multiplateforme
- **Firebase SDK** :
  - **Firestore** - Base de données pour les réservations, avis, clients et bons cadeaux
  - **Firebase Auth** - Authentification des administrateurs
- **table_calendar** - Affichage du calendrier dans le panneau admin
- **intl** - Formatage des dates en français
- **url_launcher** - Ouverture de Google Maps et de l'application téléphone
- **flutter_dotenv** - Gestion des variables d'environnement
- **PayPal Checkout SDK** - Intégration PayPal pour les paiements

### Backend
- **Firebase Cloud Functions (Python)** - Fonctions serverless pour :
  - Envoi d'emails automatiques (réservations, avis, bons cadeaux)
  - Gestion des clients lors de la confirmation de réservation
  - Webhook PayPal pour la confirmation des paiements
- **Resend API** - Service d'envoi d'emails transactionnels

## 📋 Prérequis

- Flutter SDK 3.10.1 ou supérieur
- Dart SDK
- Node.js (pour Firebase CLI)
- Python 3.12 (pour les Cloud Functions)
- Compte Firebase avec projet configuré
- Compte PayPal Developer (pour les paiements)
- Compte Resend (pour les emails)

## 🚀 Installation

### 1. Cloner le projet
```bash
git clone <repository-url>
cd harmonya
```

### 2. Installer les dépendances Flutter
```bash
flutter pub get
```

### 3. Configurer les variables d'environnement

Créez un fichier `.env` à la racine du projet (voir `.env.example`) :

```bash
cp .env.example .env
```

Remplissez les valeurs dans `.env` :
- **Firebase** : API Key, Auth Domain, Project ID, etc.
- **PayPal** : Client ID (Sandbox ou Production), Environment

> ⚠️ **Important** : Le fichier `.env` est déjà dans `.gitignore` et ne sera pas commité. Ne partagez jamais ce fichier !

### 4. Configurer Firebase

#### 4.1. Initialiser Firebase
```bash
firebase login
firebase use --add
# Sélectionnez votre projet Firebase
```

#### 4.2. Configurer les Cloud Functions

```bash
cd functions
python3.12 -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### 4.3. Configurer les variables d'environnement Firebase

```bash
firebase functions:config:set resend.api_key="votre_resend_api_key"
firebase functions:config:set admin.email="votre_email_admin"
firebase functions:config:set from.email="Harmonya <contact@harmonyamassage.fr>"
```

### 5. Lancer l'application en développement

```bash
flutter run -d chrome
```

## 📦 Structure du projet

```
harmonya/
├── lib/
│   ├── config/
│   │   ├── firebase_config.dart      # Configuration Firebase
│   │   └── paypal_config.dart        # Configuration PayPal
│   ├── models/
│   │   ├── booking.dart              # Modèle de données pour les réservations
│   │   ├── review.dart               # Modèle de données pour les avis
│   │   ├── customer.dart             # Modèle de données pour les clients
│   │   └── gift_voucher.dart        # Modèle de données pour les bons cadeaux
│   ├── pages/
│   │   ├── landing_page.dart         # Page d'accueil principale
│   │   ├── admin_login_page.dart     # Page de connexion admin
│   │   ├── admin_panel_page.dart     # Panneau d'administration
│   │   └── paypal_payment_page.dart  # Page de paiement PayPal
│   ├── services/
│   │   ├── firebase_service.dart     # Opérations Firestore
│   │   └── auth_service.dart         # Gestion de l'authentification
│   ├── theme/
│   │   └── app_theme.dart            # Thème avec palette brown/beige
│   └── widgets/
│       ├── booking_form.dart         # Formulaire de réservation
│       ├── review_form.dart          # Formulaire d'avis
│       ├── review_section.dart       # Affichage des avis approuvés
│       ├── massage_card.dart         # Carte de présentation d'un massage
│       ├── gift_voucher_form.dart    # Formulaire d'achat de bon cadeau
│       ├── paypal_button_widget.dart # Widget PayPal
│       ├── admin_booking_list.dart   # Liste des réservations (admin)
│       ├── admin_booking_calendar.dart # Calendrier des réservations (admin)
│       ├── admin_review_list.dart    # Liste des avis en attente (admin)
│       ├── admin_voucher_list.dart   # Liste des bons cadeaux (admin)
│       └── customers.dart            # Gestion des clients (admin)
├── functions/
│   ├── main.py                       # Cloud Functions Python
│   ├── requirements.txt              # Dépendances Python
│   └── venv/                         # Environnement virtuel Python
├── web/
│   └── index.html                    # Point d'entrée HTML avec meta tags
├── .env.example                      # Template pour les variables d'environnement
├── build_sandbox.sh                  # Script de build pour Sandbox
├── build_production.sh               # Script de build pour Production
└── firebase.json                     # Configuration Firebase
```

## 🎨 Types de massages

1. **Découverte** - 45€ / 30 min
   - Zones : cervicales, dos, épaule, jambes

2. **Immersion** - 60€ / 60 min
   - Thèmes : Les Îles, L'Asie, L'Orient, L'Afrique

3. **Evasion** - 85€ / 90 min
   - Techniques de réflexologie combinées

4. **Cocooning** - 95€ (60 min) ou 115€ (90 min)
   - Massage aux pierres chaudes
   - Zones : cervicales, dos, épaules, visage, jambes, pieds

### Massage à domicile
- **Frais de transport** : 5€ (Illkirch-Graffenstaden) ou 10€ (autres zones)

## 📧 Emails automatiques

Le système envoie automatiquement des emails via Resend :

- **Nouvelle réservation** : Email à l'admin
- **Réservation confirmée/annulée** : Email au client
- **Nouvel avis** : Email à l'admin
- **Bon cadeau payé** : Emails à l'acheteur, au destinataire et à l'admin

Voir `EMAIL_SETUP.md` pour la configuration détaillée.

## 💳 Intégration PayPal

Le système supporte les paiements PayPal pour les bons cadeaux :

- **Sandbox** : Pour les tests (voir `PAYPAL_TESTING.md`)
- **Production** : Pour les paiements réels

Voir `WEBHOOK_SETUP.md` pour configurer les webhooks PayPal.

## 🏗️ Build et Déploiement

### Build pour Sandbox (test)
```bash
./build_sandbox.sh
```

### Build pour Production
```bash
./build_production.sh
```

Voir `SANDBOX_BUILD.md` et `PRODUCTION_BUILD.md` pour plus de détails.

### Déploiement Firebase

```bash
# Déployer uniquement le hosting
firebase deploy --only hosting

# Déployer uniquement les fonctions
firebase deploy --only functions

# Déployer tout
firebase deploy
```

## 🔒 Sécurité

- ✅ Toutes les clés sensibles sont dans `.env` (non commité)
- ✅ Firebase API keys sont publiques mais protégées par les règles de sécurité
- ✅ Authentification admin sécurisée via Firebase Auth
- ✅ Validation côté serveur pour les emails et webhooks

Voir `SECURITY_CHECKLIST.md` avant de rendre le repository public.

## 📚 Documentation supplémentaire

- `ENV_SETUP.md` - Configuration des variables d'environnement
- `EMAIL_SETUP.md` - Configuration de Resend pour les emails
- `PAYPAL_TESTING.md` - Guide de test PayPal Sandbox
- `WEBHOOK_SETUP.md` - Configuration des webhooks PayPal
- `SANDBOX_BUILD.md` - Instructions de build Sandbox
- `PRODUCTION_BUILD.md` - Instructions de build Production
- `GITHUB_SETUP.md` - Configuration GitHub
- `SECURITY_CHECKLIST.md` - Checklist de sécurité

## 📞 Informations de contact

- **Adresse** : 1 A rue de la poste, 67400 ILLKIRCH GRAFFENSTADEN
- **Téléphone** : 06 26 14 25 89
- **Site web** : https://harmonyamassage.fr
- **Service** : Réservé aux femmes

## 🎨 Palette de couleurs

- **Brown** : `#6B4423` (primary)
- **Beige** : `#F5F1E8` (surface), `#E8DDD0` (medium), `#D4C4B0` (dark)

## 🧪 Développement

### Commandes utiles

```bash
# Lancer en mode développement
flutter run -d chrome

# Construire pour la production
flutter build web

# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Tester les fonctions localement
cd functions
firebase functions:shell
```

### Créer un compte administrateur

1. Aller dans Firebase Console > Authentication > Users
2. Ajouter un nouvel utilisateur avec email et mot de passe
3. Utiliser ces identifiants pour se connecter au panneau admin

### Index Firestore requis

Les index suivants sont créés automatiquement ou peuvent être créés manuellement :

- Collection `reviews` : index composite sur `approved` + `createdAt`
- Collection `bookings` : index sur `date` + `time` (pour éviter les doublons)
- Collection `bookings` : index sur `createdAt` (pour le tri)

## 📝 Notes importantes

- Les avis sont anonymisés pour la confidentialité (affichage : "Prénom L." au lieu du nom complet)
- Les réservations nécessitent une validation manuelle par l'administrateur (sauf si créées par l'admin)
- Le calendrier admin nécessite des index Firestore pour fonctionner correctement
- L'application est optimisée pour le web et utilise un design responsive
- Les bons cadeaux expirent après 1 an
- Les emails sont envoyés automatiquement via Firebase Cloud Functions

## 🐛 Dépannage

### PayPal SDK ne se charge pas
- Vérifiez que `PAYPAL_CLIENT_ID` est correctement configuré dans `.env`
- Vérifiez la console du navigateur pour les erreurs

### Les emails ne sont pas envoyés
- Vérifiez que `RESEND_API_KEY` est configuré dans Firebase Functions
- Vérifiez les logs Firebase Functions pour les erreurs

### Les dates ne s'affichent pas correctement
- Vérifiez que `initializeDateFormatting('fr_FR')` est appelé dans `main.dart`

## 📄 Licence

Ce projet est privé et réservé à l'usage de Harmonya.

## 👥 Contribution

Ce projet est privé. Pour toute question ou problème, contactez l'équipe de développement.

# Harmonya - Site Web de Massage & Bien-être

Application web Flutter pour Harmonya, un salon de massage dédié aux femmes situé à Illkirch-Graffenstaden, France.

## Description

Harmonya est une application web moderne permettant aux visiteurs de :
- Découvrir les différents types de massages proposés
- Réserver une séance de massage en ligne
- Laisser des avis et consulter les témoignages d'autres clientes
- Accéder aux informations de contact

Les administrateurs peuvent gérer les réservations et modérer les avis via un panneau d'administration sécurisé.

## Fonctionnalités

### Pour les visiteurs
- **Page d'accueil** avec présentation des services
- **Réservation en ligne** avec sélection de date, heure et type de massage
- **Système d'avis** permettant de laisser un témoignage
- **Affichage des avis approuvés** pour consulter les retours d'autres clientes
- **Informations de contact** (adresse et téléphone)

### Pour les administrateurs
- **Authentification sécurisée** via Firebase Auth
- **Gestion des réservations** :
  - Visualisation de toutes les réservations
  - Vue calendrier pour une meilleure organisation
  - Modification du statut (en attente, confirmée, annulée)
  - Suppression de réservations
- **Modération des avis** :
  - Consultation des avis en attente d'approbation
  - Approbation ou refus d'avis
- **Navigation** vers la page d'accueil tout en restant connecté

## Technologies utilisées

- **Flutter Web** - Framework de développement
- **Firebase** :
  - **Firestore** - Base de données pour les réservations et avis
  - **Firebase Auth** - Authentification des administrateurs
- **table_calendar** - Affichage du calendrier dans le panneau admin
- **intl** - Formatage des dates en français

## Configuration Firebase

Le projet utilise les identifiants Firebase suivants :
- **Project ID** : harmonya-fr
- **Auth Domain** : harmonya-fr.firebaseapp.com

### Configuration requise

1. **Créer un compte administrateur** dans Firebase Console :
   - Aller dans Authentication > Users
   - Ajouter un nouvel utilisateur avec email et mot de passe

2. **Créer les index Firestore** (si nécessaire) :
   - Collection `reviews` : index composite sur `approved` + `createdAt`
   - Collection `bookings` : index simple sur `createdAt`

## Installation

1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd harmonya
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run -d chrome
   ```

## Structure du projet

```
lib/
├── config/
│   └── firebase_config.dart      # Configuration Firebase
├── models/
│   ├── booking.dart              # Modèle de données pour les réservations
│   └── review.dart               # Modèle de données pour les avis
├── pages/
│   ├── landing_page.dart         # Page d'accueil principale
│   ├── admin_login_page.dart     # Page de connexion admin
│   └── admin_panel_page.dart     # Panneau d'administration
├── services/
│   ├── firebase_service.dart     # Opérations Firestore
│   └── auth_service.dart         # Gestion de l'authentification
├── theme/
│   └── app_theme.dart            # Thème avec palette brown/beige
└── widgets/
    ├── booking_form.dart         # Formulaire de réservation
    ├── review_form.dart          # Formulaire d'avis
    ├── review_section.dart       # Affichage des avis approuvés
    ├── massage_card.dart         # Carte de présentation d'un massage
    ├── admin_booking_list.dart   # Liste des réservations (admin)
    ├── admin_booking_calendar.dart # Calendrier des réservations (admin)
    └── admin_review_list.dart    # Liste des avis en attente (admin)
```

## Types de massages

1. **Découverte** - 45€ / 30 min
   - Zones : cervicales, dos, épaule, jambes

2. **Immersion** - 60€ / 60 min
   - Thèmes : Les Îles, L'Asie, L'Orient, L'Afrique

3. **Evasion** - 85€ / 90 min
   - Techniques de réflexologie combinées

4. **Cocooning** - 95€ (60 min) ou 115€ (90 min)
   - Massage aux pierres chaudes
   - Zones : cervicales, dos, épaules, visage, jambes, pieds

## Informations de contact

- **Adresse** : 1 A rue de la poste 67400 ILLKIRCH GRAFFENSTADEN
- **Téléphone** : 06 26 14 25 89
- **Service** : Réservé aux femmes

## Palette de couleurs

- **Brown** : #6B4423 (primary)
- **Beige** : #F5F1E8 (surface), #E8DDD0 (medium), #D4C4B0 (dark)

## Développement

### Prérequis
- Flutter SDK 3.10.1 ou supérieur
- Dart SDK
- Chrome ou navigateur web compatible

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
```

## Notes importantes

- Les avis sont anonymisés pour la confidentialité (affichage : "Prénom L." au lieu du nom complet)
- Les réservations nécessitent une validation manuelle par l'administrateur
- Le calendrier admin nécessite des index Firestore pour fonctionner correctement
- L'application est optimisée pour le web et utilise un design responsive

## Licence

Ce projet est privé et réservé à l'usage de Harmonya.

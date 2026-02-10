# Application Mobile - Festival Cale Sons

Cette application mobile Flutter est conçue pour la gestion et la participation aux festivals "Cale Sons". Elle permet aux utilisateurs de découvrir des événements, d'acheter des billets, et au personnel (Staff) de valider les entrées.

## Fonctionnalités Principales

### Pour les Visiteurs et Clients
- **Découverte** : Consultation de la liste des festivals et des manifestations associées.
- **Détails** : Informations complètes sur les lieux, dates, tarifs et résumés des événements.
- **Billetterie** : Achat de "Pass Festival" ou de tickets individuels pour les manifestations.
- **Portefeuille Numérique** : Accès à ses tickets sous forme de QR Codes, consultables même hors-ligne après chargement.
- **Gestion** : Possibilité d'annuler une réservation directement depuis l'application.

### Pour le Personnel (Staff)
- **Espace Dédié** : Connexion sécurisée pour les membres du staff.
- **Scanner QR Code** : Validation instantanée des tickets à l'entrée des événements.
- **Suivi en Temps Réel** : Compteurs dynamiques affichant le nombre de tickets validés par rapport à la jauge maximum du festival.
- **Feedback Immédiat** : Statut de validation (Succès, Déjà validé, Invalide) affiché instantanément après scan.

## Stack Technique
- **Framework** : [Flutter](https://flutter.dev/) (Dart)
- **Gestion d'état** : State Management natif (setState/FutureBuilder)
- **Réseau** : Package `http` pour les requêtes REST
- **QR Code** : `mobile_scanner` pour la lecture et `qr_flutter` pour la génération
- **UI** : Design moderne avec animations, dégradés et responsive layout

## Configuration

Toute la configuration de l'API se trouve dans le fichier :
`lib/config.dart`

Vous pouvez y modifier l'URL de base (`apiUrl`) pour pointer vers votre environnement local ou de production.

## Structure du Projet
- `lib/models/` : Modèles de données (Ticket, Festival, Manifestation, etc.)
- `lib/services/` : Logique de communication avec l'API (`DatabaseService`)
- `lib/widgets/` : Pages et composants de l'interface utilisateur
- `assets/` : Images, logos et icônes de l'application

## Installation
1. S'assurer d'avoir Flutter installé (`flutter doctor`)
2. Récupérer les dépendances :
   ```bash
   flutter pub get
   ```
3. Lancer l'application :
   ```bash
   flutter run
   ```

---
*Projet réalisé dans le cadre de l'AP4 - Festival Cale Sons.*

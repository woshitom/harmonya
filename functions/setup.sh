#!/bin/bash

# Script de configuration pour les Cloud Functions Python

echo "🚀 Configuration des Cloud Functions pour Harmonya"
echo ""

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé."
    echo "Installez-le avec: npm install -g firebase-tools"
    exit 1
fi

# Vérifier que Python est installé
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 n'est pas installé."
    exit 1
fi

echo "✅ Firebase CLI et Python détectés"
echo ""

# Installer les dépendances Python
echo "📦 Installation des dépendances Python..."
cd "$(dirname "$0")"
pip3 install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'installation des dépendances"
    exit 1
fi

echo "✅ Dépendances installées"
echo ""

# Demander la clé API Resend
echo "🔑 Configuration de Resend API Key"
read -p "Entrez votre Resend API Key (ou appuyez sur Entrée pour ignorer): " RESEND_KEY

if [ ! -z "$RESEND_KEY" ]; then
    echo "Configuration de la clé API..."
    firebase functions:config:set resend.api_key="$RESEND_KEY"
    echo "✅ Clé API configurée"
else
    echo "⚠️  Clé API non configurée. Vous devrez la configurer manuellement avec:"
    echo "   firebase functions:config:set resend.api_key=\"votre-key\""
fi

echo ""
echo "📧 Configuration de l'email administrateur"
read -p "Entrez votre email admin (ou appuyez sur Entrée pour ignorer): " ADMIN_EMAIL

if [ ! -z "$ADMIN_EMAIL" ]; then
    firebase functions:config:set admin.email="$ADMIN_EMAIL"
    echo "✅ Email admin configuré"
else
    echo "⚠️  Email admin non configuré. Modifiez ADMIN_EMAIL dans main.py"
fi

echo ""
echo "✅ Configuration terminée!"
echo ""
echo "Prochaines étapes:"
echo "1. Modifiez FROM_EMAIL dans functions/main.py avec votre domaine vérifié"
echo "2. Déployez avec: firebase deploy --only functions"
echo "3. Testez en créant une nouvelle réservation"


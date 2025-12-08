#!/bin/bash

# Production Build Script for Harmonya
# Usage: ./build_production.sh

set -e  # Exit on error

echo "🚀 Building Harmonya for production..."
echo ""

# Check if PayPal Client ID is provided
if [ -z "$PAYPAL_CLIENT_ID" ]; then
    echo "⚠️  Warning: PAYPAL_CLIENT_ID environment variable not set"
    echo "   Using placeholder. Make sure to set it before deploying!"
    PAYPAL_CLIENT_ID="YOUR_PRODUCTION_PAYPAL_CLIENT_ID"
fi

flutter build web \
  --dart-define=FIREBASE_API_KEY=AIzaSyDCxVfj5v5J74aPkxggrs1DjhMxVjIyuBc \
  --dart-define=FIREBASE_AUTH_DOMAIN=harmonya-fr.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=harmonya-fr \
  --dart-define=FIREBASE_STORAGE_BUCKET=harmonya-fr.firebasestorage.app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=798066243552 \
  --dart-define=FIREBASE_APP_ID=1:798066243552:web:c40e11753dab02369f1d85 \
  --dart-define=FIREBASE_MEASUREMENT_ID=G-4L6HBV1M02 \
  --dart-define=PAYPAL_CLIENT_ID="$PAYPAL_CLIENT_ID" \
  --dart-define=PAYPAL_ENVIRONMENT=production

echo ""
echo "✅ Build complete!"
echo ""
read -p "Deploy to Firebase Hosting? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying to Firebase Hosting..."
    firebase deploy --only hosting
    echo "✅ Deployment complete!"
else
    echo "Build ready in build/web/"
    echo "To deploy manually, run: firebase deploy --only hosting"
fi

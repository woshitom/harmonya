#!/bin/bash

# Sandbox/Testing Build Script for Harmonya
# Usage: ./build_sandbox.sh
# This uses PayPal Sandbox for testing

set -e  # Exit on error

echo "🧪 Building Harmonya for Sandbox/Testing environment..."
echo ""

# Use PayPal Sandbox Client ID from .env file
# IMPORTANT: Never hardcode API keys in scripts!
# Create a .env file with PAYPAL_CLIENT_ID=your_sandbox_client_id
if [ -f .env ]; then
    # Try to read from .env file
    PAYPAL_CLIENT_ID=$(grep PAYPAL_CLIENT_ID .env | cut -d '=' -f2 | tr -d ' ')
    if [ -z "$PAYPAL_CLIENT_ID" ]; then
        echo "⚠️  Error: PAYPAL_CLIENT_ID not found in .env file"
        echo "   Please create a .env file with your PayPal Sandbox Client ID"
        echo "   See .env.example for reference"
        exit 1
    fi
else
    echo "⚠️  Error: .env file not found"
    echo "   Please create a .env file with your PayPal Sandbox Client ID"
    echo "   See .env.example for reference"
    exit 1
fi

echo "Using PayPal Sandbox Client ID: ${PAYPAL_CLIENT_ID:0:20}..."
echo ""

flutter build web \
  --dart-define=FIREBASE_API_KEY=AIzaSyDCxVfj5v5J74aPkxggrs1DjhMxVjIyuBc \
  --dart-define=FIREBASE_AUTH_DOMAIN=harmonya-fr.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=harmonya-fr \
  --dart-define=FIREBASE_STORAGE_BUCKET=harmonya-fr.firebasestorage.app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=798066243552 \
  --dart-define=FIREBASE_APP_ID=1:798066243552:web:c40e11753dab02369f1d85 \
  --dart-define=FIREBASE_MEASUREMENT_ID=G-4L6HBV1M02 \
  --dart-define=PAYPAL_CLIENT_ID="$PAYPAL_CLIENT_ID" \
  --dart-define=PAYPAL_ENVIRONMENT=sandbox

echo ""
echo "✅ Build complete!"
echo ""
read -p "Deploy to Firebase Hosting? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying to Firebase Hosting..."
    firebase deploy --only hosting
    echo "✅ Deployment complete!"
    echo ""
    echo "🌐 Your site is live with PayPal Sandbox!"
    echo "   Test payments will use PayPal Sandbox (no real money)"
else
    echo "Build ready in build/web/"
    echo "To deploy manually, run: firebase deploy --only hosting"
fi

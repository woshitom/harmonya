#!/bin/bash

# Production Build Script for Harmonya
# Usage: ./build_production.sh
# IMPORTANT: Create a .env file with all required values before running

set -e  # Exit on error

echo "🚀 Building Harmonya for production..."
echo ""

# Read configuration from .env file
if [ -f .env ]; then
    # Read Firebase config from .env
    FIREBASE_API_KEY=$(grep FIREBASE_API_KEY .env | cut -d '=' -f2 | tr -d ' ')
    FIREBASE_AUTH_DOMAIN=$(grep FIREBASE_AUTH_DOMAIN .env | cut -d '=' -f2 | tr -d ' ')
    FIREBASE_PROJECT_ID=$(grep FIREBASE_PROJECT_ID .env | cut -d '=' -f2 | tr -d ' ')
    FIREBASE_STORAGE_BUCKET=$(grep FIREBASE_STORAGE_BUCKET .env | cut -d '=' -f2 | tr -d ' ')
    FIREBASE_MESSAGING_SENDER_ID=$(grep FIREBASE_MESSAGING_SENDER_ID .env | cut -d '=' -f2 | tr -d ' ')
    FIREBASE_APP_ID=$(grep FIREBASE_APP_ID .env | cut -d '=' -f2 | tr -d ' ')
    FIREBASE_MEASUREMENT_ID=$(grep FIREBASE_MEASUREMENT_ID .env | cut -d '=' -f2 | tr -d ' ')
    
    # Read PayPal config from .env
    PAYPAL_CLIENT_ID=$(grep PAYPAL_CLIENT_ID .env | cut -d '=' -f2 | tr -d ' ')
    
    # Validate required values
    if [ -z "$FIREBASE_API_KEY" ] || [ -z "$PAYPAL_CLIENT_ID" ]; then
        echo "⚠️  Error: Missing required configuration in .env file"
        echo "   Please ensure all Firebase and PayPal values are set"
        echo "   See .env.example for reference"
        exit 1
    fi
else
    echo "⚠️  Error: .env file not found"
    echo "   Please create a .env file with your production configuration"
    echo "   See .env.example for reference"
    exit 1
fi

echo "Using configuration from .env file..."
echo ""

flutter build web \
  --dart-define=FIREBASE_API_KEY="$FIREBASE_API_KEY" \
  --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_APP_ID="$FIREBASE_APP_ID" \
  --dart-define=FIREBASE_MEASUREMENT_ID="$FIREBASE_MEASUREMENT_ID" \
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

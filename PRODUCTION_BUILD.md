# Production Build Guide

This guide shows you exactly how to build and deploy your Harmonya website for production.

## Prerequisites

1. Make sure you have your production Firebase config values
2. Make sure you have your production PayPal Client ID (Live mode, not Sandbox)
3. Firebase CLI installed and logged in: `firebase login`

## Step 1: Build for Production

Run this command with your actual production values:

```bash
flutter build web \
  --dart-define=FIREBASE_API_KEY=AIzaSyDCxVfj5v5J74aPkxggrs1DjhMxVjIyuBc \
  --dart-define=FIREBASE_AUTH_DOMAIN=harmonya-fr.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=harmonya-fr \
  --dart-define=FIREBASE_STORAGE_BUCKET=harmonya-fr.firebasestorage.app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=798066243552 \
  --dart-define=FIREBASE_APP_ID=1:798066243552:web:c40e11753dab02369f1d85 \
  --dart-define=FIREBASE_MEASUREMENT_ID=G-4L6HBV1M02 \
  --dart-define=PAYPAL_CLIENT_ID=YOUR_PRODUCTION_PAYPAL_CLIENT_ID \
  --dart-define=PAYPAL_ENVIRONMENT=production
```

**Important:** Replace `YOUR_PRODUCTION_PAYPAL_CLIENT_ID` with your actual **Live** PayPal Client ID (not the Sandbox one).

## Step 2: Deploy to Firebase Hosting

After the build completes, deploy:

```bash
firebase deploy --only hosting
```

## Alternative: Using a Build Script

Create a file `build_production.sh` to make this easier:

```bash
#!/bin/bash

# Production Build Script for Harmonya
# Usage: ./build_production.sh

set -e  # Exit on error

echo "Building for production..."

flutter build web \
  --dart-define=FIREBASE_API_KEY=AIzaSyDCxVfj5v5J74aPkxggrs1DjhMxVjIyuBc \
  --dart-define=FIREBASE_AUTH_DOMAIN=harmonya-fr.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=harmonya-fr \
  --dart-define=FIREBASE_STORAGE_BUCKET=harmonya-fr.firebasestorage.app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=798066243552 \
  --dart-define=FIREBASE_APP_ID=1:798066243552:web:c40e11753dab02369f1d85 \
  --dart-define=FIREBASE_MEASUREMENT_ID=G-4L6HBV1M02 \
  --dart-define=PAYPAL_CLIENT_ID=YOUR_PRODUCTION_PAYPAL_CLIENT_ID \
  --dart-define=PAYPAL_ENVIRONMENT=production

echo "Build complete!"
echo "Deploying to Firebase Hosting..."

firebase deploy --only hosting

echo "Deployment complete!"
```

Make it executable and run:
```bash
chmod +x build_production.sh
./build_production.sh
```

## Step-by-Step Example

Here's a complete example with actual values (replace PayPal Client ID):

```bash
# 1. Navigate to project directory
cd /Users/wo.shi.tom/Documents/harmonya

# 2. Clean previous builds (optional but recommended)
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Build for production
flutter build web \
  --dart-define=FIREBASE_API_KEY=AIzaSyDCxVfj5v5J74aPkxggrs1DjhMxVjIyuBc \
  --dart-define=FIREBASE_AUTH_DOMAIN=harmonya-fr.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=harmonya-fr \
  --dart-define=FIREBASE_STORAGE_BUCKET=harmonya-fr.firebasestorage.app \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=798066243552 \
  --dart-define=FIREBASE_APP_ID=1:798066243552:web:c40e11753dab02369f1d85 \
  --dart-define=FIREBASE_MEASUREMENT_ID=G-4L6HBV1M02 \
  --dart-define=PAYPAL_CLIENT_ID=YOUR_LIVE_PAYPAL_CLIENT_ID_HERE \
  --dart-define=PAYPAL_ENVIRONMENT=production

# 5. Deploy to Firebase
firebase deploy --only hosting
```

## Getting Your Production PayPal Client ID

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
2. Log in with your PayPal Business account
3. Switch from **Sandbox** to **Live** mode (toggle in top right)
4. Navigate to **My Apps & Credentials**
5. Select your app (or create one for Live mode)
6. Copy the **Client ID** (this will be different from your Sandbox Client ID)

## Important Notes

### Firebase Config
- The Firebase values shown above are your actual production values
- These are safe to use in production (they're public anyway)
- Firebase security is handled by Firestore Security Rules and Firebase Auth

### PayPal Config
- **Sandbox Client ID** ≠ **Live Client ID**
- Make sure you're using the **Live** Client ID for production
- Set `PAYPAL_ENVIRONMENT=production` (not `sandbox`)

### Security
- Never commit your `.env` file to git (already in `.gitignore`)
- Use different PayPal Client IDs for development (Sandbox) and production (Live)
- Consider using Firebase Remote Config for client-side configs in the future

## Troubleshooting

### Build fails with "Missing environment variable"
- Make sure all `--dart-define` flags are provided
- Check for typos in variable names
- Verify values don't have extra spaces

### PayPal not working in production
- Verify you're using the **Live** PayPal Client ID
- Check that `PAYPAL_ENVIRONMENT=production`
- Verify PayPal webhook is configured for production URL
- Check browser console for errors

### Firebase not initializing
- Verify all Firebase config values are correct
- Check Firebase project is active: `firebase use harmonya-fr`
- Verify Firebase Hosting is configured in `firebase.json`

## Quick Reference

**Development (local):**
- Uses `.env` file
- PayPal Sandbox Client ID
- `PAYPAL_ENVIRONMENT=sandbox`

**Production:**
- Uses `--dart-define` flags
- PayPal Live Client ID
- `PAYPAL_ENVIRONMENT=production`
- Deployed to Firebase Hosting


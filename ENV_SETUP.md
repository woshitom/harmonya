# Environment Variables Setup Guide

This project uses environment variables to store sensitive configuration like Firebase API keys and PayPal Client IDs. This keeps your secrets out of version control.

## Setup Methods

There are two ways to provide environment variables:

### Method 1: Using `.env` File (Recommended for Development)

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your actual values:
   ```env
   FIREBASE_API_KEY=your_actual_api_key
   FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_APP_ID=your_app_id
   FIREBASE_MEASUREMENT_ID=your_measurement_id
   
   PAYPAL_CLIENT_ID=your_paypal_client_id
   PAYPAL_ENVIRONMENT=sandbox
   ```

3. The `.env` file is already in `.gitignore` and won't be committed to git.

### Method 2: Using `--dart-define` Flags (Recommended for Production)

For production builds, use `--dart-define` flags:

```bash
flutter build web \
  --dart-define=FIREBASE_API_KEY=your_key \
  --dart-define=FIREBASE_AUTH_DOMAIN=your_domain \
  --dart-define=FIREBASE_PROJECT_ID=your_project_id \
  --dart-define=FIREBASE_STORAGE_BUCKET=your_bucket \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id \
  --dart-define=FIREBASE_APP_ID=your_app_id \
  --dart-define=FIREBASE_MEASUREMENT_ID=your_measurement_id \
  --dart-define=PAYPAL_CLIENT_ID=your_paypal_client_id \
  --dart-define=PAYPAL_ENVIRONMENT=production
```

## Priority Order

The configuration system checks values in this order:
1. `--dart-define` flags (highest priority)
2. `.env` file
3. Default/empty values (lowest priority)

## Getting Your Firebase Config Values

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings (gear icon)
4. Scroll down to "Your apps"
5. Click on your web app
6. Copy the config values from the `firebaseConfig` object

## Getting Your PayPal Client ID

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
2. Log in with your PayPal Business account
3. Navigate to "My Apps & Credentials"
4. Select your app (or create one)
5. Copy the "Client ID" (Sandbox or Live)

## Deployment

### Firebase Hosting

For Firebase Hosting, you can use environment variables in `firebase.json` or set them in Firebase Console:

```bash
# Build with environment variables
flutter build web --dart-define=FIREBASE_API_KEY=... --dart-define=...

# Deploy
firebase deploy --only hosting
```

### CI/CD (GitHub Actions, etc.)

Set environment variables as secrets in your CI/CD platform:

```yaml
# Example GitHub Actions
env:
  FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  PAYPAL_CLIENT_ID: ${{ secrets.PAYPAL_CLIENT_ID }}
```

Then use `--dart-define` in your build command.

## Security Best Practices

1. ✅ **Never commit `.env` to git** (already in `.gitignore`)
2. ✅ **Use different values for development and production**
3. ✅ **Rotate keys regularly**
4. ✅ **Use Firebase App Check** to protect your Firebase resources
5. ✅ **Use PayPal webhook signature verification** in production
6. ✅ **Store production secrets in CI/CD secrets** (not in code)

## Troubleshooting

### "Firebase not initialized" error
- Check that all Firebase config values are set correctly
- Verify `.env` file exists and has correct values
- Check browser console for specific error messages

### "Localhost requests blocked" error
- **Common issue**: `[firebase_auth/requests-from-referer-http://localhost:58667-are-blocked.]`
- **Solution**: Add `localhost` to authorized domains in Firebase Console
  - Go to Firebase Console > Authentication > Settings > Authorized domains
  - Click "Add domain" and enter `localhost`
  - See `FIREBASE_LOCALHOST_SETUP.md` for detailed instructions

### "PayPal SDK not loaded" error
- Verify `PAYPAL_CLIENT_ID` is set correctly
- Check that `PAYPAL_ENVIRONMENT` is either 'sandbox' or 'production'
- Ensure you're using the correct Client ID for your environment

### Values not loading
- Make sure `.env` file is in the project root
- Verify `pubspec.yaml` includes `.env` in assets
- Check that `flutter_dotenv` package is installed (`flutter pub get`)
- Restart your development server after changing `.env`

## Current Configuration Files

- `lib/config/firebase_config.dart` - Reads Firebase config from env vars
- `lib/config/paypal_config.dart` - Reads PayPal config from env vars
- `.env.example` - Template file (safe to commit)
- `.env` - Your actual values (NOT committed to git)


# Sandbox/Testing Build Guide

This guide shows you how to build and deploy your Harmonya website for testing with PayPal Sandbox.

## Quick Start

**Option 1: Use the build script (easiest)**
```bash
./build_sandbox.sh
```

**Option 2: Manual command**

> ⚠️ **Note**: It's recommended to use the build script or `.env` file instead of hardcoding values.

```bash
flutter build web \
  --dart-define=FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_PROJECT.appspot.com \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MEASUREMENT_ID=YOUR_MEASUREMENT_ID \
  --dart-define=PAYPAL_CLIENT_ID=YOUR_SANDBOX_CLIENT_ID \
  --dart-define=PAYPAL_ENVIRONMENT=sandbox

firebase deploy --only hosting
```

## What's Different from Production?

| Setting | Sandbox | Production |
|---------|---------|------------|
| PayPal Client ID | Sandbox Client ID | Live Client ID |
| PayPal Environment | `sandbox` | `production` |
| Payments | Test/fake money | Real money |
| PayPal URL | `sandbox.paypal.com` | `paypal.com` |

## Complete Sandbox Deployment Workflow

```bash
# 1. Navigate to project
cd /Users/wo.shi.tom/Documents/harmonya

# 2. Clean previous builds (optional)
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Build for sandbox/testing
flutter build web \
  --dart-define=FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY \
  --dart-define=FIREBASE_AUTH_DOMAIN=YOUR_PROJECT.firebaseapp.com \
  --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
  --dart-define=FIREBASE_STORAGE_BUCKET=YOUR_PROJECT.appspot.com \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID \
  --dart-define=FIREBASE_APP_ID=YOUR_APP_ID \
  --dart-define=FIREBASE_MEASUREMENT_ID=YOUR_MEASUREMENT_ID \
  --dart-define=PAYPAL_CLIENT_ID=YOUR_SANDBOX_CLIENT_ID \
  --dart-define=PAYPAL_ENVIRONMENT=sandbox

# 5. Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Using the Build Script

The `build_sandbox.sh` script automates this process:

```bash
# Make sure it's executable (already done)
chmod +x build_sandbox.sh

# Run it
./build_sandbox.sh
```

The script will:
1. ✅ Use your Sandbox PayPal Client ID (from `.env` or default)
2. ✅ Set `PAYPAL_ENVIRONMENT=sandbox`
3. ✅ Build the web app
4. ✅ Ask if you want to deploy automatically
5. ✅ Deploy to Firebase Hosting if confirmed

## Testing PayPal Payments in Sandbox

After deployment, you can test payments:

1. **Use PayPal Sandbox test accounts:**
   - Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
   - Navigate to **Sandbox** → **Accounts**
   - Create or use existing test buyer account
   - Use test account email/password when paying

2. **Use test credit cards:**
   - Card: `4111111111111111`
   - Expiry: Any future date (e.g., `12/2025`)
   - CVV: Any 3 digits (e.g., `123`)

3. **Verify payments:**
   - Check Firestore `gift_vouchers` collection
   - Status should change to `paid`
   - Check Firebase Functions logs for webhook events
   - Verify emails are sent (if configured)

## Important Notes

### PayPal Sandbox Client ID
- Your Sandbox Client ID should be set in your `.env` file (see `.env.example`)
- This is already configured in your `.env` file
- The build script will use this automatically

### Environment
- Always use `PAYPAL_ENVIRONMENT=sandbox` for testing
- Never use real PayPal accounts in Sandbox mode
- All payments are fake/test money

### Webhooks
- Make sure your PayPal webhook is configured for Sandbox
- Webhook URL should point to your Firebase Function
- Use Sandbox webhook events for testing

## Troubleshooting

### PayPal buttons not showing
- Verify Sandbox Client ID is correct
- Check `PAYPAL_ENVIRONMENT=sandbox`
- Check browser console for errors

### Payments not completing
- Use PayPal Sandbox test accounts (not real accounts)
- Verify webhook is configured in PayPal Sandbox dashboard
- Check Firebase Functions logs

### Build fails
- Make sure all `--dart-define` flags are provided
- Check for typos in variable names
- Verify Flutter is up to date: `flutter doctor`

## Quick Reference

**For Testing (Sandbox):**
```bash
./build_sandbox.sh
```

**For Production (Live):**
```bash
./build_production.sh
```

**Local Development:**
- Uses `.env` file automatically
- No need for `--dart-define` flags
- Run: `flutter run -d chrome`


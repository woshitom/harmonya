# PayPal Sandbox Testing Guide

This guide explains how to test PayPal payments in Sandbox mode.

## Overview

PayPal Sandbox is a testing environment that simulates PayPal payments without using real money or real credit cards.

## Test Accounts

### Creating Test Accounts

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
2. Log in with your PayPal Business account
3. Navigate to **Sandbox** → **Accounts**
4. Click **Create Account**
5. Create two types of accounts:
   - **Personal** (for testing as a buyer)
   - **Business** (for testing as a seller)

### Using Test Accounts

When testing payments:
1. Click "Pay with PayPal" button
2. You'll be redirected to PayPal Sandbox login page
3. Use your **test buyer account** credentials (email/password)
4. Complete the payment flow

**Important:** Use the email and password from your Sandbox test account, NOT your real PayPal account!

## Test Credit Cards

If you want to test with a credit card instead of PayPal account:

### Visa Test Card
- **Card Number:** `4111111111111111`
- **Expiry Date:** Any future date (e.g., `12/2025`)
- **CVV:** Any 3 digits (e.g., `123`)
- **Name:** Any name

### Other Test Cards

PayPal provides various test cards for different scenarios:

**Successful Payment:**
- Visa: `4111111111111111`
- Mastercard: `5555555555554444`
- Amex: `378282246310005`

**Declined Payment:**
- Card: `4000000000000002` (Generic decline)
- Card: `4000000000000069` (Expired card)
- Card: `4000000000000127` (Insufficient funds)

## Testing Different Scenarios

### 1. Successful Payment
- Use a test buyer account or test card `4111111111111111`
- Complete the payment flow
- Check Firestore to verify voucher status changes to `paid`
- Verify emails are sent (purchaser, recipient, admin)

### 2. Failed Payment
- Use PayPal's test accounts that simulate failures
- Or use declined test cards (see above)
- Verify error handling works correctly

### 3. Cancelled Payment
- Click "Cancel" during PayPal checkout
- Verify the voucher remains in `pending` status
- Verify no emails are sent

### 4. Webhook Testing
- After a successful payment, PayPal sends a webhook
- Check Firebase Functions logs to verify webhook is received
- Verify voucher status is updated correctly

## Sandbox vs Production

### Sandbox Mode (Current)
- **URL:** `https://www.sandbox.paypal.com/sdk/js`
- **Client ID:** Sandbox Client ID (starts with `AV...`)
- **Purpose:** Testing only
- **Money:** Fake/test money only
- **Accounts:** Test accounts only

### Production Mode
- **URL:** `https://www.paypal.com/sdk/js`
- **Client ID:** Live Client ID (different from Sandbox)
- **Purpose:** Real payments
- **Money:** Real money
- **Accounts:** Real PayPal accounts

**To switch to production:**
1. Update `lib/config/paypal_config.dart`
2. Change `environment = 'production'`
3. Replace `clientId` with your **Live Client ID** (from PayPal Developer Dashboard)
4. Rebuild and redeploy

## Common Issues

### "PayPal SDK not loaded"
- Check that `clientId` is set correctly in `paypal_config.dart`
- Verify you're using Sandbox Client ID for Sandbox mode
- Check browser console for errors

### "Invalid Client ID"
- Make sure you're using the correct Client ID for your environment
- Sandbox Client ID ≠ Live Client ID
- Verify the Client ID in PayPal Developer Dashboard

### Payment Not Completing
- Check browser console for errors
- Verify webhook URL is configured in PayPal Dashboard
- Check Firebase Functions logs for webhook events

### Emails Not Sending
- Verify `RESEND_API_KEY` is set in Firebase Functions
- Check Firebase Functions logs for email errors
- Verify email addresses are valid

## Resources

- [PayPal Sandbox Documentation](https://developer.paypal.com/docs/api-basics/sandbox/)
- [PayPal Test Cards](https://developer.paypal.com/docs/api-basics/sandbox-testing/)
- [PayPal Developer Dashboard](https://developer.paypal.com/)


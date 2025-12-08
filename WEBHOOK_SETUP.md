# PayPal Webhook Setup Guide

This guide explains how to set up PayPal webhooks for automatic payment confirmation.

## Overview

Webhooks allow PayPal to notify your server when payment events occur, ensuring reliable payment confirmation even if the user closes their browser before the payment completes.

## Setup Steps

### 1. Deploy the Webhook Handler

The webhook handler is located in `functions/paypal_webhook.py`. Deploy it:

```bash
cd functions
firebase deploy --only functions:paypal_webhook
```

### 2. Get Your Webhook URL

After deployment, your webhook URL will be:
```
https://europe-west9-YOUR_PROJECT_ID.cloudfunctions.net/paypal_webhook
```

Replace `YOUR_PROJECT_ID` with your actual Firebase project ID.

### 3. Configure PayPal Webhooks

1. Go to [PayPal Developer Dashboard](https://developer.paypal.com/)
2. Log in with your PayPal Business account
3. Navigate to **My Apps & Credentials**
4. Select your app (or create one if needed)
5. Scroll down to **Webhooks** section
6. Click **Add Webhook**
7. Enter your webhook URL
8. Select the following events:
   - `PAYMENT.CAPTURE.COMPLETED` - Payment successfully captured
   - `PAYMENT.CAPTURE.DENIED` - Payment was denied
   - `PAYMENT.CAPTURE.REFUNDED` - Payment was refunded
9. Save the webhook

### 4. Get Webhook ID

**Important distinction:**
- **"Secret key 1" under API Credentials**: This is for authenticating YOUR API calls TO PayPal (used with Client ID)
- **Webhook Signing Secret**: This is for verifying webhook requests FROM PayPal TO your server (different purpose!)

After creating the webhook:
1. In PayPal Developer Dashboard, go to **My Apps & Credentials**
2. Select your app
3. Scroll down to the **Webhooks** section (NOT API Credentials)
4. Click on your webhook to view its details
5. Copy the **Webhook ID** - This is the unique identifier for your webhook

**Note about Signing Secret:**
- In **Sandbox mode**, PayPal often doesn't show a "Signing secret" option
- PayPal uses **header-based verification** instead
- Each webhook request includes verification headers:
  - `PAYPAL-TRANSMISSION-ID`
  - `PAYPAL-TRANSMISSION-SIG`
  - `PAYPAL-TRANSMISSION-TIME`
  - `PAYPAL-CERT-URL`
  - `PAYPAL-AUTH-ALGO`
- You can verify webhooks using PayPal's webhook verification API with these headers
- For testing, signature verification can be skipped, but **always implement it before production**

If you need to store the Webhook ID:
```bash
firebase functions:config:set paypal.webhook_id="YOUR_WEBHOOK_ID"
```

### 5. Webhook Handler Status

The webhook handler in `functions/main.py` currently:

✅ **Done:**
- Handles all necessary event types (`PAYMENT.CAPTURE.COMPLETED`, `DENIED`, `REFUNDED`)
- Updates voucher status in Firestore correctly
- Extracts voucher ID from PayPal webhook payload

⚠️ **Pending (for production):**
- Signature verification is currently disabled (acceptable for testing)
- Webhook ID/secret not yet loaded from environment variables (not critical for testing)

**For production**, you should:
1. Implement signature verification using PayPal's webhook verification API
2. Store webhook ID in environment variables (optional but recommended)
3. Add proper error handling and logging

The current implementation works for testing, but **always implement signature verification before going to production**.

### 6. Test the Webhook

1. Use PayPal's webhook simulator in the Developer Dashboard
2. Send a test event to your webhook URL
3. Check Firebase Functions logs to verify it's working

## Security Notes

⚠️ **IMPORTANT**: Always verify webhook signatures in production!

The current implementation has signature verification disabled for testing. Before going live:

1. Implement proper signature verification using PayPal's webhook verification API
2. Verify the webhook ID matches your configured webhook
3. Validate the payload structure
4. Handle errors gracefully

## How It Works

1. User completes payment on your site
2. PayPal processes the payment
3. PayPal sends a webhook event to your server
4. Your webhook handler:
   - Verifies the webhook signature
   - Extracts the voucher ID from `custom_id`
   - Updates the voucher status in Firestore
   - The Firestore trigger sends confirmation emails

## Troubleshooting

- **Webhook not receiving events**: Check that the URL is correct and publicly accessible
- **Signature verification fails**: Ensure webhook secret is correctly set
- **Voucher not updating**: Check Firestore rules and function logs
- **Emails not sending**: Verify Resend API key is configured

## Additional Resources

- [PayPal Webhooks Documentation](https://developer.paypal.com/docs/api-basics/notifications/webhooks/)
- [PayPal Webhook Verification](https://developer.paypal.com/docs/api-basics/notifications/webhooks/notification-messages/)
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)


# Firestore Rules and Indexes Deployment Guide

This guide explains how to deploy Firestore security rules and indexes to your Firebase project.

## Prerequisites

1. **Firebase CLI installed**: Make sure you have Firebase CLI installed on your system.
   ```bash
   npm install -g firebase-tools
   ```

2. **Logged in to Firebase**: Ensure you're logged in to Firebase CLI.
   ```bash
   firebase login
   ```

3. **Project initialized**: Make sure your project is initialized with Firebase.
   ```bash
   firebase init firestore
   ```

4. **Files present**: Ensure the following files exist in your project root:
   - `firestore.rules` - Firestore security rules file
   - `firestore.indexes.json` - Firestore indexes configuration file
   - `storage.rules` - Storage security rules file

## Deployment Options

### Option 1: Deploy Firestore Rules Only

To deploy only the Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

This will update the security rules in your Firebase project without affecting indexes.

### Option 2: Deploy Firestore Indexes Only

To deploy only the Firestore indexes:

```bash
firebase deploy --only firestore:indexes
```

**Note**: Index creation can take several minutes. Firestore will build the indexes in the background, and you can monitor the progress in the Firebase Console.

### Option 3: Deploy Both Firestore Rules and Indexes

To deploy both rules and indexes together:

```bash
firebase deploy --only firestore
```

This is the recommended approach as it ensures both rules and indexes are synchronized.

### Option 4: Deploy Storage Rules

To deploy Firebase Storage security rules:

```bash
firebase deploy --only storage
```

This will update the storage security rules in your Firebase project.

### Option 5: Deploy Everything

To deploy Firestore rules, indexes, and Storage rules all at once:

```bash
firebase deploy
```

Or deploy specific services together:

```bash
firebase deploy --only firestore,storage
```

## Verification

### Check Rules Deployment

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`harmonya-fr`)
3. Navigate to **Firestore Database** → **Rules** tab
4. Verify that your rules are displayed correctly

### Check Indexes Deployment

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`harmonya-fr`)
3. Navigate to **Firestore Database** → **Indexes** tab
4. Verify that your indexes are listed and their status is **Enabled**

**Note**: New indexes may show as "Building" initially. This process can take several minutes depending on the amount of data in your collections.

### Check Storage Rules Deployment

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`harmonya-fr`)
3. Navigate to **Storage** → **Rules** tab
4. Verify that your storage rules are displayed correctly

## Current Configuration

### Firestore Security Rules Summary

- **bookings**: Public create, authenticated read/update/delete
- **contactMessages**: Public create, authenticated read/update/delete
- **customers**: Authenticated only (all operations)
- **massages**: Public read, authenticated create/update/delete
- **treatments**: Public read, authenticated create/update/delete
- **reviews**: Public read/create, authenticated update/delete
- **giftVouchers**: Public create (with validation: status='pending', valid amounts only, required fields), authenticated read/update/delete
- **closedDays**: Public read, authenticated create/update/delete

### Gift Voucher Security Details

The `giftVouchers` collection has additional security validations on create:
- **Status validation**: Only `status: 'pending'` can be created (prevents creating paid vouchers without payment)
- **Amount validation**: Amount must be a number and exactly one of: 45.0, 60.0, 85.0, 95.0, or 115.0 (prevents arbitrary amounts). Uses explicit equality comparisons for reliability.
- **Required fields**: All required fields (purchaserName, purchaserEmail, recipientName, recipientEmail) must be present, non-empty strings
- **Payment fields protection**: `paidAt` must be `null` or not set, and `paypalOrderId` must be an empty string or not set (only PayPal webhook can set these after payment confirmation)

This ensures that:
- Vouchers are only valid after PayPal payment confirmation via webhook
- Users cannot manipulate voucher amounts or payment status
- Only properly formatted vouchers can be created

### Firestore Indexes Summary

- **reviews** collection: Composite index on `approved` (ASC) and `createdAt` (DESC)
  - Required for queries filtering by `approved` and ordering by `createdAt`
- **closedDays** collection: Composite index on `date` (ASC)
  - Required for queries filtering by `date` (isGreaterThanOrEqualTo) and ordering by `date`

### Storage Security Rules Summary

- **All paths**: Public read access, authenticated write/update/delete
  - Everyone can read files (images, etc.)
  - Only logged in users can upload, update, or delete files

## Troubleshooting

### Error: "File firestore.indexes.json does not exist"

If you encounter this error, ensure the `firestore.indexes.json` file exists in your project root. If it doesn't exist, create it with at least an empty structure:

```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

### Error: "File storage.rules does not exist"

If you encounter this error, ensure the `storage.rules` file exists in your project root. If it doesn't exist, create it with at least a basic structure:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Index Building Takes Too Long

Index building is a background process that can take several minutes to hours depending on:
- The amount of data in your collections
- The complexity of the index
- Current load on Firebase servers

You can monitor the progress in the Firebase Console under **Firestore Database** → **Indexes**.

### Rules Not Applied Immediately

After deploying rules, they should be applied immediately. However, if you're experiencing issues:

1. Clear your browser cache
2. Wait a few seconds and try again
3. Check the Firebase Console to verify the rules were deployed correctly

### Permission Denied Errors

If you encounter permission errors:

1. Verify you're logged in with the correct Firebase account:
   ```bash
   firebase login:list
   ```

2. Check that your account has the necessary permissions for the project

3. Verify the project ID in `firebase.json` matches your Firebase project

4. **For gift vouchers**: If you encounter permission errors when creating a voucher, ensure:
   - `status` is set to `'pending'` (cannot create paid vouchers)
   - `amount` is one of: 45.0, 60.0, 85.0, 95.0, or 115.0
   - All required fields are present and non-empty (purchaserName, purchaserEmail, recipientName, recipientEmail)
   - Do not attempt to set `paidAt` or `paypalOrderId` on create (only PayPal webhook can set these)

## Best Practices

1. **Test Rules Locally**: Use the Firebase Emulator Suite to test your rules before deploying:
   ```bash
   firebase emulators:start --only firestore
   ```

2. **Review Before Deploying**: Always review your rules and indexes before deploying to production

3. **Deploy During Low Traffic**: If possible, deploy indexes during periods of low traffic to minimize impact

4. **Monitor After Deployment**: After deploying, monitor your application for any errors or unexpected behavior

5. **Version Control**: Keep your `firestore.rules`, `firestore.indexes.json`, and `storage.rules` files in version control

## Additional Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexes)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)


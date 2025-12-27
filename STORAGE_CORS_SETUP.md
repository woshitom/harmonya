# Firebase Storage CORS Configuration

This guide explains how to configure CORS (Cross-Origin Resource Sharing) for Firebase Storage so that images can be displayed on web applications.

## Problem

When displaying images from Firebase Storage in a Flutter web app, you may encounter CORS errors preventing the images from loading. This happens because browsers enforce CORS policies for cross-origin requests.

## Solution: Configure CORS for Firebase Storage

**Important**: CORS configuration is NOT available in Firebase Console. You must use either:
- **Google Cloud Shell** (Recommended - Works even with Owner role) ✅ **THIS METHOD WORKS**
- Google Cloud Console (web UI)
- Command line (gsutil) - May have permission issues

### Method 1: Using Google Cloud Shell (✅ RECOMMENDED - This Works!)

**This method works even if you have permission issues with local gsutil!**

1. **Open Google Cloud Console**
   - Go to: https://console.cloud.google.com/
   - Select your project: `harmonya-fr`

2. **Activate Cloud Shell**
   - Click the **Cloud Shell** icon (terminal icon) in the top right corner
   - Wait for Cloud Shell to initialize

3. **Create the CORS configuration file**
   - In Cloud Shell, create a file:
     ```bash
     nano cors.json
     ```
   - Paste this content:
     ```json
     [
       {
         "origin": ["*"],
         "method": ["GET"],
         "maxAgeSeconds": 3600
       }
     ]
     ```
   - Save: Press `Ctrl+X`, then `Y`, then `Enter`

4. **Apply CORS Configuration**
   ```bash
   gsutil cors set cors.json gs://harmonya-fr.firebasestorage.app
   ```
   (Replace `harmonya-fr.firebasestorage.app` with your actual bucket name if different)

5. **Verify it worked**
   ```bash
   gsutil cors get gs://harmonya-fr.firebasestorage.app
   ```

6. **Hard reload your web app** (Ctrl+Shift+R or Cmd+Shift+R) to see the changes

**Why this works:** Cloud Shell automatically has the correct permissions, so it works even when local gsutil fails with permission errors.

### Method 2: Using Google Cloud Console (Web UI)

**Direct Link to CORS Configuration:**
- Try this direct link: https://console.cloud.google.com/storage/browser/harmonya-fr.firebasestorage.app?project=harmonya-fr&tab=configuration

**Step-by-Step:**

1. **Go to Google Cloud Console** (NOT Firebase Console)
   - Visit: https://console.cloud.google.com/storage/browser?project=harmonya-fr
   - Or use direct link above

2. **Select your bucket**
   - Click on the bucket: `harmonya-fr.firebasestorage.app`
   - If you don't see it, check Firebase Console → Storage → Files to confirm the exact bucket name

3. **Open CORS Configuration**
   - Click on the **"Configuration"** tab at the top (or use the direct link above)
   - Scroll down to find **"CORS configuration"** section
   - If you don't see it, try:
     - Refreshing the page
     - Checking if you're viewing the correct bucket
     - Looking for "Edit CORS configuration" button

4. **Paste the CORS configuration**
   ```json
   [
     {
       "origin": ["*"],
       "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
       "responseHeader": ["Content-Type", "Authorization"],
       "maxAgeSeconds": 3600
     }
   ]
   ```

5. **Save** the configuration

### Method 3: Using Local Command Line (gsutil) - May Have Permission Issues

**Prerequisites:**

1. **Install Google Cloud SDK (gsutil)** - Already installed ✓
   - Verify: `gsutil --version`

2. **Grant yourself Storage Admin permissions** (if you don't have them)
   - Go to: https://console.cloud.google.com/iam-admin/iam?project=harmonya-fr
   - Find your email (`woshitomdevth@gmail.com`)
   - Click **Edit** (pencil icon)
   - Click **Add Another Role**
   - Select: **Storage Admin** or **Storage Object Admin**
   - Click **Save**
   - Wait 1-2 minutes for permissions to propagate

3. **Authenticate with Google Cloud** (if needed)
   ```bash
   gcloud auth login
   ```

4. **Set your project** (already set ✓)
   ```bash
   gcloud config set project harmonya-fr
   ```

5. **Apply CORS Configuration**
   ```bash
   gsutil cors set storage-cors.json gs://harmonya-fr.firebasestorage.app
   ```

### Step 2: Verify CORS Configuration

To verify that the CORS configuration was applied correctly:

```bash
gsutil cors get gs://harmonya-fr.firebasestorage.app
```

You should see the CORS configuration displayed.

### Step 3: Test Image Display

After applying the CORS configuration, restart your Flutter web app and test if images are loading correctly.

## CORS Configuration Details

The `storage-cors.json` file contains:

- **origin**: `["*"]` - Allows requests from any origin (you can restrict this to specific domains for better security)
- **method**: `["GET", "HEAD", "PUT", "POST", "DELETE"]` - Allows these HTTP methods
- **responseHeader**: `["Content-Type", "Authorization"]` - Allows these response headers
- **maxAgeSeconds**: `3600` - Cache preflight requests for 1 hour

## Security Considerations

For production, consider restricting the `origin` field to specific domains:

```json
[
  {
    "origin": [
      "https://yourdomain.com",
      "https://www.yourdomain.com",
      "http://localhost:*"
    ],
    "method": ["GET", "HEAD"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

This limits which domains can access your storage bucket.

## Troubleshooting

### Error: "Command not found: gsutil"
- Install Google Cloud SDK (see Prerequisites above)

### Error: "Access Denied"
- Make sure you're authenticated: `gcloud auth login`
- Verify you have the correct project: `gcloud config get-value project`

### Images still not loading
- Clear browser cache
- Check browser console for CORS errors
- Verify the CORS configuration: `gsutil cors get gs://harmonya-fr.firebasestorage.app`
- Make sure you're using the correct bucket name

## Additional Resources

- [Google Cloud Storage CORS Documentation](https://cloud.google.com/storage/docs/configuring-cors)
- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)


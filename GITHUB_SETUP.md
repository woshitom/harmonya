# GitHub Setup Instructions

## Step 1: Create Repository on GitHub

1. Go to https://github.com/new
2. Repository name: `harmonya`
3. Description (optional): "Flutter web landing page for Harmonya massage parlor"
4. Choose **Public** or **Private** (your choice)
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click **Create repository**

## Step 2: Push Your Code

After creating the repository, GitHub will show you commands. Use these:

```bash
cd /Users/wo.shi.tom/Documents/harmonya
git remote add origin https://github.com/YOUR_USERNAME/harmonya.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

## Alternative: Using SSH (if you have SSH keys set up)

```bash
git remote add origin git@github.com:YOUR_USERNAME/harmonya.git
git push -u origin main
```

## What's Included

The repository includes:
- ✅ All Flutter source code
- ✅ Firebase configuration
- ✅ Python Cloud Functions
- ✅ Documentation (README.md, EMAIL_SETUP.md, etc.)
- ✅ Assets (images, icons)

## What's Excluded (.gitignore)

- Build artifacts (`build/`, `.dart_tool/`)
- Python virtual environment (`venv/`, `env/`)
- Firebase cache (`.firebase/`)
- IDE files (`.vscode/`, `.idea/`)
- OS files (`.DS_Store`)

## Important Notes

⚠️ **Security**: The following files contain sensitive information and should NOT be committed:
- `lib/config/firebase_config.dart` - Contains Firebase API keys (already committed, but consider using environment variables in production)
- `lib/config/paypal_config.dart` - Contains PayPal Client ID (already committed, but consider using environment variables in production)
- `functions/main.py` - Contains email API keys (should use Firebase environment variables)

For production, consider:
- Using Firebase Remote Config for client-side configs
- Using Firebase Functions environment variables for server-side secrets
- Adding these files to `.gitignore` and using template files instead


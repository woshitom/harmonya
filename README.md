# Harmonya - Massage & Wellness Website

Flutter web application for Harmonya, a massage salon dedicated to women located in Illkirch-Graffenstaden, France.

🌐 **Live website**: [https://harmonyamassage.fr](https://harmonyamassage.fr)

## 🌟 Description

Harmonya is a modern web application that allows visitors to:
- Discover the different types of massages offered
- Book a massage session online (on-site or at home)
- Leave reviews and read testimonials from other clients
- Purchase gift vouchers for their loved ones
- Access contact information

Administrators can manage bookings, moderate reviews, manage customers and gift vouchers through a secure admin panel.

## ✨ Features

### For Visitors
- **Homepage** with presentation of services and the practitioner
- **Online booking** with:
  - Date selection (no bookings on Sundays)
  - Time selection via timetable (Mon-Fri: 5pm-10pm, Sat: 10am-8pm)
  - Massage type selection
  - "Home massage" option with transportation fees
  - Automatic checking of already booked time slots
- **Review system** allowing visitors to leave testimonials with first name and last name
- **Display of approved reviews** to read feedback from other clients
- **Gift voucher purchase** with PayPal payment
- **Contact information** (clickable address for Google Maps, clickable phone number)

### For Administrators
- **Secure authentication** via Firebase Auth with password reset
- **Booking management**:
  - View all bookings in list format
  - Calendar view for better organization
  - Manual booking creation (automatically set to "confirmed" status)
  - Status modification (pending, confirmed, cancelled)
  - Booking deletion
  - Badge showing number of pending bookings
- **Review moderation**:
  - View reviews pending approval
  - Approve or reject reviews with confirmation dialog
  - Badge showing number of pending reviews
- **Customer management**:
  - List of all customers
  - Create, edit and delete customers
  - History of massage types per customer
- **Gift voucher management**:
  - List of all gift vouchers
  - Status tracking (pending, paid, used, expired)
  - Information about purchaser and recipient
- **Navigation** to homepage while remaining logged in

## 🛠️ Technologies Used

### Frontend
- **Flutter Web** - Cross-platform development framework
- **Firebase SDK**:
  - **Firestore** - Database for bookings, reviews, customers and gift vouchers
  - **Firebase Auth** - Administrator authentication
- **table_calendar** - Calendar display in admin panel
- **intl** - French date formatting
- **url_launcher** - Opening Google Maps and phone app
- **flutter_dotenv** - Environment variable management
- **PayPal Checkout SDK** - PayPal integration for payments

### Backend
- **Firebase Cloud Functions (Python)** - Serverless functions for:
  - Automatic email sending (bookings, reviews, gift vouchers)
  - Customer management when booking is confirmed
  - PayPal webhook for payment confirmation
- **Resend API** - Transactional email service

## 📋 Prerequisites

- Flutter SDK 3.10.1 or higher
- Dart SDK
- Node.js (for Firebase CLI)
- Python 3.12 (for Cloud Functions)
- Firebase account with configured project
- PayPal Developer account (for payments)
- Resend account (for emails)

## 🚀 Installation

### 1. Clone the project
```bash
git clone <repository-url>
cd harmonya
```

### 2. Install Flutter dependencies
```bash
flutter pub get
```

### 3. Configure environment variables

Create a `.env` file at the project root (see `.env.example`):

```bash
cp .env.example .env
```

Fill in the values in `.env`:
- **Firebase**: API Key, Auth Domain, Project ID, etc.
- **PayPal**: Client ID (Sandbox or Production), Environment

> ⚠️ **Important**: The `.env` file is already in `.gitignore` and will not be committed. Never share this file!

### 4. Configure Firebase

#### 4.1. Initialize Firebase
```bash
firebase login
firebase use --add
# Select your Firebase project
```

#### 4.2. Configure Cloud Functions

```bash
cd functions
python3.12 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### 4.3. Configure Firebase environment variables

```bash
firebase functions:config:set resend.api_key="your_resend_api_key"
firebase functions:config:set admin.email="your_admin_email"
firebase functions:config:set from.email="Harmonya <contact@harmonyamassage.fr>"
```

### 5. Run the application in development

```bash
flutter run -d chrome
```

## 📦 Project Structure

```
harmonya/
├── lib/
│   ├── config/
│   │   ├── firebase_config.dart      # Firebase configuration
│   │   └── paypal_config.dart        # PayPal configuration
│   ├── models/
│   │   ├── booking.dart              # Booking data model
│   │   ├── review.dart               # Review data model
│   │   ├── customer.dart             # Customer data model
│   │   └── gift_voucher.dart        # Gift voucher data model
│   ├── pages/
│   │   ├── landing_page.dart         # Main homepage
│   │   ├── admin_login_page.dart     # Admin login page
│   │   ├── admin_panel_page.dart     # Admin panel
│   │   └── paypal_payment_page.dart  # PayPal payment page
│   ├── services/
│   │   ├── firebase_service.dart     # Firestore operations
│   │   └── auth_service.dart         # Authentication management
│   ├── theme/
│   │   └── app_theme.dart            # Theme with brown/beige palette
│   └── widgets/
│       ├── booking_form.dart         # Booking form
│       ├── review_form.dart          # Review form
│       ├── review_section.dart       # Approved reviews display
│       ├── massage_card.dart         # Massage presentation card
│       ├── gift_voucher_form.dart    # Gift voucher purchase form
│       ├── paypal_button_widget.dart # PayPal widget
│       ├── admin_booking_list.dart   # Booking list (admin)
│       ├── admin_booking_calendar.dart # Booking calendar (admin)
│       ├── admin_review_list.dart    # Pending reviews list (admin)
│       ├── admin_voucher_list.dart   # Gift vouchers list (admin)
│       └── customers.dart            # Customer management (admin)
├── functions/
│   ├── main.py                       # Python Cloud Functions
│   ├── requirements.txt             # Python dependencies
│   └── venv/                         # Python virtual environment
├── web/
│   └── index.html                    # HTML entry point with meta tags
├── .env.example                      # Environment variables template
├── build_sandbox.sh                  # Sandbox build script
├── build_production.sh               # Production build script
└── firebase.json                     # Firebase configuration
```

## 🎨 Massage Types

1. **Découverte** - €45 / 30 min
   - Areas: neck, back, shoulders, legs

2. **Immersion** - €60 / 60 min
   - Themes: The Islands, Asia, The Orient, Africa

3. **Evasion** - €85 / 90 min
   - Combined reflexology techniques

4. **Cocooning** - €95 (60 min) or €115 (90 min)
   - Hot stone massage
   - Areas: neck, back, shoulders, face, legs, feet

### Home Massage
- **Transportation fees**: €5 (Illkirch-Graffenstaden) or €10 (other areas)

## 📧 Automatic Emails

The system automatically sends emails via Resend:

- **New booking**: Email to admin
- **Booking confirmed/cancelled**: Email to client
- **New review**: Email to admin
- **Gift voucher paid**: Emails to purchaser, recipient and admin

See `EMAIL_SETUP.md` for detailed configuration.

## 💳 PayPal Integration

The system supports PayPal payments for gift vouchers:

- **Sandbox**: For testing (see `PAYPAL_TESTING.md`)
- **Production**: For real payments

See `WEBHOOK_SETUP.md` to configure PayPal webhooks.

## 🏗️ Build and Deployment

### Build for Sandbox (testing)
```bash
./build_sandbox.sh
```

### Build for Production
```bash
./build_production.sh
```

See `SANDBOX_BUILD.md` and `PRODUCTION_BUILD.md` for more details.

### Firebase Deployment

```bash
# Deploy hosting only
firebase deploy --only hosting

# Deploy functions only
firebase deploy --only functions

# Deploy everything
firebase deploy
```

## 🔒 Security

- ✅ All sensitive keys are in `.env` (not committed)
- ✅ Firebase API keys are public but protected by security rules
- ✅ Secure admin authentication via Firebase Auth
- ✅ Server-side validation for emails and webhooks

See `FILES_TO_PROTECT.md` before making the repository public.

## 📚 Additional Documentation

- `ENV_SETUP.md` - Environment variable configuration
- `EMAIL_SETUP.md` - Resend email configuration
- `PAYPAL_TESTING.md` - PayPal Sandbox testing guide
- `WEBHOOK_SETUP.md` - PayPal webhook configuration
- `SANDBOX_BUILD.md` - Sandbox build instructions
- `PRODUCTION_BUILD.md` - Production build instructions
- `GITHUB_SETUP.md` - GitHub configuration
- `FILES_TO_PROTECT.md` - Security checklist

## 📞 Contact Information

- **Address**: 1 A rue de la poste, 67400 ILLKIRCH GRAFFENSTADEN
- **Phone**: 06 26 14 25 89
- **Website**: https://harmonyamassage.fr
- **Service**: Reserved for women

## 🎨 Color Palette

- **Brown**: `#6B4423` (primary)
- **Beige**: `#F5F1E8` (surface), `#E8DDD0` (medium), `#D4C4B0` (dark)

## 🧪 Development

### Useful Commands

```bash
# Run in development mode
flutter run -d chrome

# Build for production
flutter build web

# Analyze code
flutter analyze

# Format code
dart format lib/

# Test functions locally
cd functions
firebase functions:shell
```

### Create an Administrator Account

1. Go to Firebase Console > Authentication > Users
2. Add a new user with email and password
3. Use these credentials to log in to the admin panel

### Required Firestore Indexes

The following indexes are created automatically or can be created manually:

- Collection `reviews`: composite index on `approved` + `createdAt`
- Collection `bookings`: index on `date` + `time` (to avoid duplicates)
- Collection `bookings`: index on `createdAt` (for sorting)

## 📝 Important Notes

- Reviews are anonymized for privacy (display: "First Name L." instead of full name)
- Bookings require manual validation by administrator (except if created by admin)
- Admin calendar requires Firestore indexes to work correctly
- Application is optimized for web and uses responsive design
- Gift vouchers expire after 1 year
- Emails are sent automatically via Firebase Cloud Functions

## 🐛 Troubleshooting

### PayPal SDK not loading
- Verify that `PAYPAL_CLIENT_ID` is correctly configured in `.env`
- Check browser console for errors

### Emails not being sent
- Verify that `RESEND_API_KEY` is configured in Firebase Functions
- Check Firebase Functions logs for errors

### Dates not displaying correctly
- Verify that `initializeDateFormatting('fr_FR')` is called in `main.dart`

## 📄 License

This project is private and reserved for Harmonya's use.

## 👥 Contribution

This project is private. For any questions or issues, contact the development team.

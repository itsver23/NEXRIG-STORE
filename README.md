# NEXRIG STORE

NEXRIG STORE is a Flutter-based PC components and gaming accessories shopping application powered by Supabase and integrated with Xendit for payments.

## Features

- Customer registration and login
- Product browsing and search
- Shopping cart and checkout
- Customer orders and order tracking
- Admin dashboard using the existing login page
- Product management (add, edit, stock, and visibility)
- Order management and shipping status updates

## Requirements

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android SDK
- Supabase project
- Xendit payment integration

## Installation

1. Clone the GitHub repository.
2. Open the project folder.
3. Run:

```bash
flutter pub get
```

4. Configure the Supabase URL and publishable key using the configuration method supported by the project.
5. Run the application:

```bash
flutter run
```

## Build APK

```bash
flutter build apk --release
```

APK output:

`build/app/outputs/flutter-apk/app-release.apk`

## Security

Do not commit passwords, Supabase service-role keys, Xendit secret keys, or private environment files to GitHub.

## Technology Stack

- Flutter / Dart
- Supabase Authentication
- Supabase PostgreSQL
- Xendit Payment Gateway

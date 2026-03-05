# QRCodet

<p align="center">
  <a href="./LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-111827.svg?style=for-the-badge"></a>
  <img alt="Monorepo" src="https://img.shields.io/badge/Repo-Web%20%2B%20Mobile-0f766e.svg?style=for-the-badge">
  <img alt="Web: React + Vite" src="https://img.shields.io/badge/Web-React%20%2B%20Vite-2563eb.svg?style=for-the-badge">
  <img alt="Mobile: Flutter" src="https://img.shields.io/badge/Mobile-Flutter-0ea5e9.svg?style=for-the-badge">
</p>

QRCodet is a QR/Barcode studio with two clients:

- `web/`: React + Vite app for desktop and mobile browsers
- `mobile/`: Flutter app for Android/iOS

Both apps support code generation, scanning, themed styling, and saved history workflows.

## Highlights

- QR + Barcode generation for multiple payload types
- Real-time camera scanning + image upload scanning
- Parsed scan insights: code type, fields, decoded payload, useful metadata
- Themed code frames and styling controls
- Save generated images locally
- Scan history with configurable limits
- Settings for theme, scanner behavior, storage folder, and UX preferences

## Repository Structure

```text
.
├── web/                 # React + Vite application
│   ├── public/
│   ├── src/
│   └── package.json
├── mobile/              # Flutter application
│   ├── android/
│   ├── ios/
│   ├── lib/
│   └── pubspec.yaml
├── DESIGN_STYLE.md
└── README.md
```

## Requirements

### Web

- Node.js 18+
- npm 9+

### Mobile

- Flutter SDK (stable)
- Android Studio / Xcode (platform-specific)
- A physical device or emulator/simulator

## Quick Start

### 1) Clone

```bash
git clone <your-repo-url>
cd QRCodet
```

### 2) Run Web App

```bash
cd web
npm install
npm run dev
```

Build for production:

```bash
npm run build
npm run preview
```

### 3) Run Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

Validate and build:

```bash
flutter analyze
flutter build apk --debug
```

## Web App Details (`web/`)

- Generator with QR + barcode use-cases
- Responsive layout improvements for small screens
- Dedicated scanner tab
- Camera scanner + image upload scanner
- PNG/SVG export
- Local presets and browser storage persistence

Main commands:

```bash
npm run dev
npm run build
npm run preview
```

## Mobile App Details (`mobile/`)

- Flutter implementation of the same studio workflow
- Create / Scan / Gallery / Settings sections
- Real-time scan (camera), torch, camera switch
- Image upload scan
- Save to device storage (default gallery folder)
- In-app history + storage controls

Main commands:

```bash
flutter pub get
flutter run
flutter analyze
flutter build apk --debug
```

## Permissions & Storage Notes

- Camera permission is required for live scanning.
- Media/storage permissions are requested at runtime when needed.
- Android/iOS metadata is configured in:
  - `mobile/android/app/src/main/AndroidManifest.xml`
  - `mobile/ios/Runner/Info.plist`

## Troubleshooting

- `flutter analyze` issues: run `flutter pub get` and re-run.
- Camera not opening: check OS-level camera permission.
- Save path issues on Android: verify storage permission is granted for the app.
- Web scanner not reading: confirm browser camera access and HTTPS/localhost context.

## Tech Stack

- Web: React, Vite, ZXing (`@zxing/browser`), QR/Barcode rendering libraries
- Mobile: Flutter, `mobile_scanner`, `qr_flutter`, `barcode_widget`, `shared_preferences`

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).

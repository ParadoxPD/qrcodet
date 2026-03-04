# QRCodet

QRCodet is now split into two apps:

- `web/`: the React + Vite web studio
- `mobile/`: the Flutter mobile app

Both targets support QR and barcode generation, themed previews, reusable presets, and scanning workflows.

## Repo Layout

```text
.
├── web/
│   ├── src/
│   ├── public/
│   └── package.json
├── mobile/
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── DESIGN_STYLE.md
└── README.md
```

## Web App

Features:

- QR and barcode generation across all existing use cases
- Responsive mobile browser layout
- Collapsible use-case selection and field-reference panels for small screens
- Realtime QR/barcode scanning from camera
- QR/barcode image upload decoding
- Parsed scan details: code type, structured fields, and payload metadata
- PNG/SVG export and local preset storage

Run locally:

```bash
cd web
npm install
npm run dev
```

Build:

```bash
cd web
npm run build
```

## Mobile App

Features:

- Flutter implementation of the generator studio
- QR and barcode creation with themed framed previews
- Realtime QR/barcode scanning with camera switching and torch control
- Image-based scan analysis from local gallery
- Local save-to-storage workflow with a dedicated `QRCodetGallery` folder
- In-app gallery of generated codes
- Settings for app theme, generator defaults, camera scan behavior, save folder, and scan-history limit
- Persistent scan history with configurable cap

Run locally:

```bash
cd mobile
flutter run
```

Validate/build:

```bash
cd mobile
flutter analyze
flutter build apk --debug
```

## Notes

- iOS usage descriptions for camera and photo access are configured in `mobile/ios/Runner/Info.plist`.
- Android camera permission is configured in `mobile/android/app/src/main/AndroidManifest.xml`.
- The web scanner uses ZXing via `@zxing/browser`.

## License

See [LICENSE](./LICENSE).

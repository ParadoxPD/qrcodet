# QR & Barcode Builder

A modular, theme-driven generator studio for production-ready QR codes and barcodes.

This project is built with React + Vite and is designed to be extended through config-first use cases, reusable renderers, and consistent UI primitives.

## Highlights

- High-quality QR rendering with crisp edges and large export resolution.
- Full framed downloads (PNG/SVG) including selected layout style.
- Light and dark theme sets with frame-aware styling.
- QR customization:
  - Dot styles
  - Corner box styles
  - Error correction levels (`L`, `M`, `Q`, `H`)
  - Center logo embedding
- Preset save/load/delete for reusable branded configurations.
- Field-level helper text, strict validation, and reference panel.

## Supported Generators

### QR Use Cases

- UPI Payment
- Website URL
- YouTube
- X
- WiFi
- Contact (vCard)
- Geolocation
- Calendar
- Event
- SMS
- Email
- Plain Text

### Barcode Use Cases

- Code 128
- Code 39
- Code 93
- CODABAR
- EAN-13
- UPC-A
- UPC-E
- EAN-8
- ITF-14
- PDF-417
- Data Matrix
- Aztec

## Tech Stack

- `react`, `react-dom`
- `vite`, `@vitejs/plugin-react`
- `qrcode-generator` for QR matrix generation
- `jsbarcode` for 1D barcode families
- `bwip-js` for advanced 2D barcodes (PDF-417, Data Matrix, Aztec)
- `html-to-image` for full-frame PNG/SVG exports

## Quick Start

```bash
npm install
npm run dev
```

Production build:

```bash
npm run build
npm run preview
```

## Project Structure

```text
src/
  main.jsx
  qrcode.jsx
  style.css
  features/
    generator/
      components/
        CodeFrame.jsx
        GeneratorControls.jsx
        PatternIcon.jsx
        PreviewPane.jsx
      config/
        appearance.js
        useCases.js
      lib/
        barcodeRenderer.js
        download.js
        payloadBuilders.js
        qrRenderer.js
public/
  favicon.svg
```

## How to Extend

### Add a new QR use case

1. Add the use case in `src/features/generator/config/useCases.js`.
2. Add the payload builder in `src/features/generator/lib/payloadBuilders.js`.
3. Keep fields config-driven (labels, validation, helper text) so UI updates automatically.

### Add a new barcode type

1. Add config entry in `useCases.js` with:
   - `format`
   - `renderer` (`js` or `bwip`)
2. Ensure `barcodeRenderer.js` supports that format.

### Add a theme/frame/style

1. Add entries in `src/features/generator/config/appearance.js`.
2. Add render/UI support in:
   - `PatternIcon.jsx` (for visible style picker icons)
   - `CodeFrame.jsx` + `style.css` (for frame variants)

## Design Notes

Visual direction is documented in:

- `DESIGN_STYLE.md`

The app follows a "crafted utility" style:

- editorial typography
- warm dark surfaces
- accent-led hierarchy
- configurable but coherent component language

## License

See [LICENSE](./LICENSE).

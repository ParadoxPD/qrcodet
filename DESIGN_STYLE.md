# QRCodet Design Style

This project uses a single visual direction: `crafted utility`.

## Aesthetic Rules

1. Atmosphere
- Base is warm, dark editorial surfaces (`#0c0b09` family), not flat black.
- Backgrounds always include layered gradients or subtle patterns.
- Cards use a tactile border + heavy shadow so modules look like physical artifacts.

2. Typography
- Display and hierarchy: `Cormorant Garamond`.
- Product UI and controls: `Outfit`.
- Structured technical text (payloads, labels, refs): `DM Mono`.
- We avoid default/system-only typography unless a platform constraint requires it.

3. Color behavior
- `--c-accent` is gold/amber by default and used for active state and primary action only.
- `--c-muted` carries secondary text and metadata.
- Theme chips now include both light and dark sets; app chrome remains stable.
- Avoid random color additions: new colors should be introduced as CSS variables first.

4. Component language
- Layout is two-column: controls left, sticky live preview right.
- Control sections are modular `panel` blocks with eyebrow headers.
- Use case selection is card-based; appearance options use chips/swatches.
- Required marks are always red and validation messages are inline with helper text.
- Preview always includes:
  - Frame wrapper (stylistic context),
  - status indicator,
  - payload inspector,
  - export actions.
- Frames available: `none`, `minimal`, `scan`, `card`, `ticket`, `ornate`, `badge`, `poster`, `strip`.

5. Motion
- `rise-in` for first-load panel entrance.
- `pulse` only for waiting/incomplete states.
- No decorative micro-animation unless it communicates generation state.

6. Scalability conventions
- Add new generators through `config/useCases.js` + `lib/payloadBuilders.js`.
- Keep UI generic: a new use case should be mostly config, not a new bespoke page.
- Shared primitives live in `features/generator/components` and must stay reusable.
- Presets are first-class for team workflows; store/load from local storage with stable schema.

## Module Architecture

- `src/qrcode.jsx`: composition root for generator mode, payload state, and exports.
- `src/features/generator/config`: design and use-case registries.
- `src/features/generator/lib`: payload encoding, QR rendering, barcode rendering, download logic.
- `src/features/generator/components`: reusable views for controls, patterns, framing, preview.

This style and structure is the baseline for future pages and features.

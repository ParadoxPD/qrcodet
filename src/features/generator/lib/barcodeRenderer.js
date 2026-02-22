import JsBarcode from "jsbarcode";

export const renderBarcodeToSvg = (svgElement, payload, format, theme) => {
  if (!svgElement || !payload) return { ok: false, error: "Barcode payload is empty." };
  try {
    JsBarcode(svgElement, payload, {
      format,
      lineColor: theme.dark,
      background: theme.light,
      width: 2,
      height: 90,
      margin: 14,
      displayValue: true,
      fontSize: 16,
      textMargin: 6,
    });
    return { ok: true, error: "" };
  } catch (error) {
    return { ok: false, error: error?.message || "Unable to generate barcode." };
  }
};

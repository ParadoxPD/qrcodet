import JsBarcode from "jsbarcode";
import bwipjs from "bwip-js";

const BWIP_MAP = {
  PDF417: "pdf417",
  DATAMATRIX: "datamatrix",
  AZTEC: "azteccode",
};

const paintBwipSvg = (targetSvg, markup) => {
  const doc = new DOMParser().parseFromString(markup, "image/svg+xml");
  const sourceSvg = doc.documentElement;
  targetSvg.innerHTML = sourceSvg.innerHTML;
  const attrs = ["viewBox", "width", "height", "xmlns"];
  attrs.forEach((attr) => {
    const value = sourceSvg.getAttribute(attr);
    if (value) targetSvg.setAttribute(attr, value);
  });
};

export const renderBarcodeToSvg = (svgElement, payload, format, renderer, theme) => {
  if (!svgElement || !payload) return { ok: false, error: "Barcode payload is empty." };
  try {
    if (renderer === "bwip" || BWIP_MAP[format]) {
      const svgMarkup = bwipjs.toSVG({
        bcid: BWIP_MAP[format],
        text: payload,
        scale: 4,
        includetext: true,
        textxalign: "center",
        barcolor: theme.dark,
        backgroundcolor: theme.light.replace("#", ""),
      });
      paintBwipSvg(svgElement, svgMarkup);
      return { ok: true, error: "" };
    }

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

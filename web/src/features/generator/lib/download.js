const triggerDownload = (filename, href) => {
  const anchor = document.createElement("a");
  anchor.download = filename;
  anchor.href = href;
  anchor.click();
};

export const downloadBlob = (filename, blob) => {
  const url = URL.createObjectURL(blob);
  triggerDownload(filename, url);
  URL.revokeObjectURL(url);
};

export const downloadCanvasPng = (canvas, filename) => {
  if (!canvas) return;
  triggerDownload(filename, canvas.toDataURL("image/png"));
};

export const downloadSvgMarkup = (svgMarkup, filename) => {
  const blob = new Blob([svgMarkup], { type: "image/svg+xml" });
  downloadBlob(filename, blob);
};

export const downloadSvgElement = (svgElement, filename) => {
  if (!svgElement) return;
  const serializer = new XMLSerializer();
  const svgMarkup = serializer.serializeToString(svgElement);
  downloadSvgMarkup(svgMarkup, filename);
};

export const svgElementToPng = async (svgElement) => {
  const serializer = new XMLSerializer();
  const svgMarkup = serializer.serializeToString(svgElement);
  const blob = new Blob([svgMarkup], { type: "image/svg+xml" });
  const url = URL.createObjectURL(blob);

  try {
    const img = await new Promise((resolve, reject) => {
      const image = new Image();
      image.onload = () => resolve(image);
      image.onerror = reject;
      image.src = url;
    });
    const width = Number(svgElement.getAttribute("width")) || 480;
    const height = Number(svgElement.getAttribute("height")) || 220;
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0, width, height);
    return canvas.toDataURL("image/png");
  } finally {
    URL.revokeObjectURL(url);
  }
};

import qrcode from "qrcode-generator";

export const QR_SIZE = 1024;
export const QR_VIEW_SIZE = 288;
export const QR_MARGIN = 70;

const FINDER_PATTERN_AREAS = [
  { row: 0, col: 0 },
  { row: 0, col: -7 },
  { row: -7, col: 0 },
];

const isInFinderArea = (row, col, count) =>
  FINDER_PATTERN_AREAS.some((pattern) => {
    const startRow = pattern.row < 0 ? count + pattern.row : pattern.row;
    const startCol = pattern.col < 0 ? count + pattern.col : pattern.col;
    return row >= startRow && row < startRow + 7 && col >= startCol && col < startCol + 7;
  });

export const buildQrMatrix = (payload) => {
  const qr = qrcode(0, "M");
  qr.addData(payload);
  qr.make();
  const count = qr.getModuleCount();
  return Array.from({ length: count }, (_, row) =>
    Array.from({ length: count }, (_, col) => qr.isDark(row, col)),
  );
};

const drawModule = (ctx, x, y, moduleSize, style) => {
  const size = moduleSize * 0.96;
  const cx = x + moduleSize / 2;
  const cy = y + moduleSize / 2;
  switch (style) {
    case "dot":
      ctx.beginPath();
      ctx.arc(cx, cy, (size / 2) * 0.82, 0, Math.PI * 2);
      ctx.fill();
      break;
    case "rounded": {
      const r = size * 0.34;
      ctx.beginPath();
      ctx.roundRect(x, y, size, size, r);
      ctx.fill();
      break;
    }
    case "diamond": {
      const h = (size / 2) * 0.9;
      ctx.beginPath();
      ctx.moveTo(cx, cy - h);
      ctx.lineTo(cx + h, cy);
      ctx.lineTo(cx, cy + h);
      ctx.lineTo(cx - h, cy);
      ctx.closePath();
      ctx.fill();
      break;
    }
    case "squircle": {
      const r = size * 0.48;
      ctx.beginPath();
      ctx.roundRect(x, y, size, size, r);
      ctx.fill();
      break;
    }
    case "kite": {
      const h = (size / 2) * 0.86;
      ctx.beginPath();
      ctx.moveTo(cx, cy - h);
      ctx.lineTo(cx + h * 0.88, cy);
      ctx.lineTo(cx, cy + h);
      ctx.lineTo(cx - h * 0.88, cy);
      ctx.closePath();
      ctx.fill();
      break;
    }
    case "plus": {
      const arm = size * 0.35;
      const width = size * 0.22;
      ctx.beginPath();
      ctx.rect(cx - width / 2, y, width, size);
      ctx.rect(x, cy - width / 2, size, width);
      ctx.fill();
      break;
    }
    case "bars_v": {
      const bar = size * 0.35;
      const by = y + (moduleSize - size) / 2;
      ctx.fillRect(cx - bar - 1.3, by, bar, size);
      ctx.fillRect(cx + 1.3, by, bar, size);
      break;
    }
    default:
      ctx.fillRect(x, y, size, size);
  }
};

const drawFinder = (ctx, x, y, moduleSize, style, dark, accent, light) => {
  const outer = moduleSize * 7;
  const inner = moduleSize * 5;
  const core = moduleSize * 3;
  const innerOffset = moduleSize;
  const coreOffset = moduleSize * 2;
  const fill = (shape, sx, sy, size, color) => {
    ctx.fillStyle = color;
    if (shape === "dot") {
      ctx.beginPath();
      ctx.arc(sx + size / 2, sy + size / 2, size / 2, 0, Math.PI * 2);
      ctx.fill();
      return;
    }
    if (shape === "diamond") {
      ctx.beginPath();
      ctx.moveTo(sx + size / 2, sy);
      ctx.lineTo(sx + size, sy + size / 2);
      ctx.lineTo(sx + size / 2, sy + size);
      ctx.lineTo(sx, sy + size / 2);
      ctx.closePath();
      ctx.fill();
      return;
    }
    const radius = shape === "rounded" ? size * 0.22 : shape === "leaf" ? size * 0.45 : size * 0.12;
    ctx.beginPath();
    ctx.roundRect(sx, sy, size, size, radius);
    ctx.fill();
  };

  fill(style, x, y, outer, dark);
  fill(style, x + innerOffset, y + innerOffset, inner, light);
  fill(style, x + coreOffset, y + coreOffset, core, accent);
};

const drawLogo = (ctx, logoImage, theme) => {
  if (!logoImage) return;
  const size = QR_SIZE * 0.22;
  const x = (QR_SIZE - size) / 2;
  const y = (QR_SIZE - size) / 2;
  const pad = size * 0.16;
  ctx.fillStyle = theme.light;
  ctx.strokeStyle = theme.accent;
  ctx.lineWidth = 10;
  ctx.beginPath();
  ctx.roundRect(x - pad, y - pad, size + pad * 2, size + pad * 2, 36);
  ctx.fill();
  ctx.stroke();
  ctx.save();
  ctx.beginPath();
  ctx.roundRect(x, y, size, size, 22);
  ctx.clip();
  ctx.drawImage(logoImage, x, y, size, size);
  ctx.restore();
};

const modulePath = (x, y, moduleSize, style) => {
  const size = moduleSize * 0.96;
  const cx = x + moduleSize / 2;
  const cy = y + moduleSize / 2;
  if (style === "dot") {
    return `<circle cx="${cx}" cy="${cy}" r="${(size / 2) * 0.82}"/>`;
  }
  if (style === "diamond" || style === "kite") {
    const h = (size / 2) * 0.9;
    return `<polygon points="${cx},${cy - h} ${cx + h},${cy} ${cx},${cy + h} ${cx - h},${cy}"/>`;
  }
  if (style === "plus") {
    const width = size * 0.22;
    return `<rect x="${cx - width / 2}" y="${y}" width="${width}" height="${size}"/><rect x="${x}" y="${cy - width / 2}" width="${size}" height="${width}"/>`;
  }
  if (style === "bars_v") {
    const bar = size * 0.35;
    const by = y + (moduleSize - size) / 2;
    return `<rect x="${cx - bar - 1.3}" y="${by}" width="${bar}" height="${size}"/><rect x="${cx + 1.3}" y="${by}" width="${bar}" height="${size}"/>`;
  }
  const radius = style === "squircle" ? size * 0.48 : style === "rounded" ? size * 0.34 : 0;
  return `<rect x="${x}" y="${y}" width="${size}" height="${size}" rx="${radius}" ry="${radius}"/>`;
};

const finderSvg = (x, y, moduleSize, style, theme) => {
  const outer = moduleSize * 7;
  const inner = moduleSize * 5;
  const core = moduleSize * 3;
  const radius = style === "dot" ? "50%" : style === "rounded" ? `${outer * 0.22}` : style === "leaf" ? `${outer * 0.45}` : `${outer * 0.12}`;
  const innerRadius = style === "dot" ? "50%" : style === "rounded" ? `${inner * 0.22}` : style === "leaf" ? `${inner * 0.45}` : `${inner * 0.12}`;
  const coreRadius = style === "dot" ? "50%" : style === "rounded" ? `${core * 0.22}` : style === "leaf" ? `${core * 0.45}` : `${core * 0.12}`;
  return `
    <rect x="${x}" y="${y}" width="${outer}" height="${outer}" rx="${radius}" ry="${radius}" fill="${theme.dark}" />
    <rect x="${x + moduleSize}" y="${y + moduleSize}" width="${inner}" height="${inner}" rx="${innerRadius}" ry="${innerRadius}" fill="${theme.light}" />
    <rect x="${x + moduleSize * 2}" y="${y + moduleSize * 2}" width="${core}" height="${core}" rx="${coreRadius}" ry="${coreRadius}" fill="${theme.accent}" />
  `;
};

const logoSvg = (logoDataUrl, theme) => {
  if (!logoDataUrl) return "";
  const size = QR_SIZE * 0.22;
  const x = (QR_SIZE - size) / 2;
  const y = (QR_SIZE - size) / 2;
  const pad = size * 0.16;
  return `
    <rect x="${x - pad}" y="${y - pad}" width="${size + pad * 2}" height="${size + pad * 2}" rx="36" fill="${theme.light}" stroke="${theme.accent}" stroke-width="10" />
    <image href="${logoDataUrl}" x="${x}" y="${y}" width="${size}" height="${size}" preserveAspectRatio="xMidYMid slice" />
  `;
};

export const renderQrToCanvas = (canvas, matrix, options) => {
  const { moduleStyle, cornerStyle, theme, logoImage } = options;
  const ctx = canvas.getContext("2d");
  const count = matrix.length;
  const moduleSize = (QR_SIZE - QR_MARGIN * 2) / count;
  canvas.width = QR_SIZE;
  canvas.height = QR_SIZE;
  ctx.fillStyle = theme.light;
  ctx.fillRect(0, 0, QR_SIZE, QR_SIZE);
  ctx.fillStyle = theme.dark;

  for (let row = 0; row < count; row += 1) {
    for (let col = 0; col < count; col += 1) {
      if (!matrix[row][col]) continue;
      if (isInFinderArea(row, col, count)) continue;
      const x = QR_MARGIN + col * moduleSize;
      const y = QR_MARGIN + row * moduleSize;
      drawModule(ctx, x, y, moduleSize, moduleStyle);
    }
  }

  const topLeft = { x: QR_MARGIN, y: QR_MARGIN };
  const topRight = { x: QR_MARGIN + (count - 7) * moduleSize, y: QR_MARGIN };
  const bottomLeft = { x: QR_MARGIN, y: QR_MARGIN + (count - 7) * moduleSize };
  drawFinder(ctx, topLeft.x, topLeft.y, moduleSize, cornerStyle, theme.dark, theme.accent, theme.light);
  drawFinder(ctx, topRight.x, topRight.y, moduleSize, cornerStyle, theme.dark, theme.accent, theme.light);
  drawFinder(ctx, bottomLeft.x, bottomLeft.y, moduleSize, cornerStyle, theme.dark, theme.accent, theme.light);
  drawLogo(ctx, logoImage, theme);
};

export const qrMatrixToSvg = (matrix, options) => {
  const { moduleStyle, cornerStyle, theme, logoDataUrl } = options;
  const count = matrix.length;
  const moduleSize = (QR_SIZE - QR_MARGIN * 2) / count;
  const nodes = [];
  for (let row = 0; row < count; row += 1) {
    for (let col = 0; col < count; col += 1) {
      if (!matrix[row][col]) continue;
      if (isInFinderArea(row, col, count)) continue;
      const x = QR_MARGIN + col * moduleSize;
      const y = QR_MARGIN + row * moduleSize;
      nodes.push(modulePath(x, y, moduleSize, moduleStyle));
    }
  }

  const tl = finderSvg(QR_MARGIN, QR_MARGIN, moduleSize, cornerStyle, theme);
  const tr = finderSvg(QR_MARGIN + (count - 7) * moduleSize, QR_MARGIN, moduleSize, cornerStyle, theme);
  const bl = finderSvg(QR_MARGIN, QR_MARGIN + (count - 7) * moduleSize, moduleSize, cornerStyle, theme);

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${QR_SIZE}" height="${QR_SIZE}" viewBox="0 0 ${QR_SIZE} ${QR_SIZE}"><rect width="${QR_SIZE}" height="${QR_SIZE}" fill="${theme.light}"/><g fill="${theme.dark}">${nodes.join("")}</g>${tl}${tr}${bl}${logoSvg(logoDataUrl, theme)}</svg>`;
};

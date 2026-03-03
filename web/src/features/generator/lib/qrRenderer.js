import qrcode from "qrcode-generator";

export const QR_SIZE = 1400;
export const QR_VIEW_SIZE = 320;
export const QR_MARGIN = 90;

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

const geometry = (count) => {
  const moduleSize = Math.floor((QR_SIZE - QR_MARGIN * 2) / count);
  const gridSize = moduleSize * count;
  const offset = Math.floor((QR_SIZE - gridSize) / 2);
  return { moduleSize, offset };
};

export const buildQrMatrix = (payload, errorCorrection = "M") => {
  const qr = qrcode(0, errorCorrection);
  qr.addData(payload);
  qr.make();
  const count = qr.getModuleCount();
  return Array.from({ length: count }, (_, row) => Array.from({ length: count }, (_, col) => qr.isDark(row, col)));
};

const drawModule = (ctx, x, y, moduleSize, style) => {
  const size = moduleSize;
  const cx = x + moduleSize / 2;
  const cy = y + moduleSize / 2;
  switch (style) {
    case "dot":
      ctx.beginPath();
      ctx.arc(cx, cy, Math.floor((size / 2) * 0.8), 0, Math.PI * 2);
      ctx.fill();
      break;
    case "rounded":
      ctx.beginPath();
      ctx.roundRect(x, y, size, size, Math.floor(size * 0.28));
      ctx.fill();
      break;
    case "diamond": {
      const h = (size / 2) * 0.92;
      ctx.beginPath();
      ctx.moveTo(cx, cy - h);
      ctx.lineTo(cx + h, cy);
      ctx.lineTo(cx, cy + h);
      ctx.lineTo(cx - h, cy);
      ctx.closePath();
      ctx.fill();
      break;
    }
    case "squircle":
      ctx.beginPath();
      ctx.roundRect(x, y, size, size, Math.floor(size * 0.42));
      ctx.fill();
      break;
    case "kite": {
      const h = (size / 2) * 0.9;
      ctx.beginPath();
      ctx.moveTo(cx, cy - h);
      ctx.lineTo(cx + h * 0.86, cy);
      ctx.lineTo(cx, cy + h);
      ctx.lineTo(cx - h * 0.86, cy);
      ctx.closePath();
      ctx.fill();
      break;
    }
    case "plus": {
      const width = Math.max(1, Math.floor(size * 0.26));
      ctx.fillRect(Math.round(cx - width / 2), y, width, size);
      ctx.fillRect(x, Math.round(cy - width / 2), size, width);
      break;
    }
    case "star": {
      const outer = (size / 2) * 0.94;
      const inner = outer * 0.44;
      ctx.beginPath();
      for (let i = 0; i < 10; i += 1) {
        const r = i % 2 === 0 ? outer : inner;
        const angle = (Math.PI / 5) * i - Math.PI / 2;
        const px = cx + r * Math.cos(angle);
        const py = cy + r * Math.sin(angle);
        if (i === 0) ctx.moveTo(px, py);
        else ctx.lineTo(px, py);
      }
      ctx.closePath();
      ctx.fill();
      break;
    }
    case "cross": {
      const width = Math.max(1, Math.floor(size * 0.24));
      const arm = Math.floor(size * 0.36);
      ctx.beginPath();
      ctx.rect(Math.round(cx - width / 2), Math.round(cy - arm), width, arm * 2);
      ctx.rect(Math.round(cx - arm), Math.round(cy - width / 2), arm * 2, width);
      ctx.fill();
      break;
    }
    case "bars_v": {
      const bar = Math.max(1, Math.floor(size * 0.34));
      ctx.fillRect(Math.round(cx - bar - 1), y, bar, size);
      ctx.fillRect(Math.round(cx + 1), y, bar, size);
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
  const drawShape = (shape, sx, sy, size, color) => {
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
    const radius = shape === "rounded" ? Math.floor(size * 0.2) : shape === "leaf" ? Math.floor(size * 0.44) : Math.floor(size * 0.1);
    ctx.beginPath();
    ctx.roundRect(sx, sy, size, size, radius);
    ctx.fill();
  };
  drawShape(style, x, y, outer, dark);
  drawShape(style, x + moduleSize, y + moduleSize, inner, light);
  drawShape(style, x + moduleSize * 2, y + moduleSize * 2, core, accent);
};

const drawLogo = (ctx, logoImage, theme) => {
  if (!logoImage) return;
  const size = Math.floor(QR_SIZE * 0.2);
  const x = Math.floor((QR_SIZE - size) / 2);
  const y = Math.floor((QR_SIZE - size) / 2);
  const pad = Math.floor(size * 0.16);
  ctx.fillStyle = theme.light;
  ctx.strokeStyle = theme.accent;
  ctx.lineWidth = 12;
  ctx.beginPath();
  ctx.roundRect(x - pad, y - pad, size + pad * 2, size + pad * 2, 40);
  ctx.fill();
  ctx.stroke();
  ctx.save();
  ctx.beginPath();
  ctx.roundRect(x, y, size, size, 24);
  ctx.clip();
  ctx.drawImage(logoImage, x, y, size, size);
  ctx.restore();
};

const modulePath = (x, y, moduleSize, style) => {
  const size = moduleSize;
  const cx = x + moduleSize / 2;
  const cy = y + moduleSize / 2;
  if (style === "dot") return `<circle cx="${cx}" cy="${cy}" r="${(size / 2) * 0.8}"/>`;
  if (style === "diamond" || style === "kite") {
    const h = (size / 2) * 0.92;
    return `<polygon points="${cx},${cy - h} ${cx + h},${cy} ${cx},${cy + h} ${cx - h},${cy}"/>`;
  }
  if (style === "plus" || style === "cross") {
    const width = Math.max(1, Math.floor(size * 0.24));
    const arm = Math.floor(size * 0.36);
    return `<rect x="${Math.round(cx - width / 2)}" y="${Math.round(cy - arm)}" width="${width}" height="${arm * 2}"/><rect x="${Math.round(cx - arm)}" y="${Math.round(cy - width / 2)}" width="${arm * 2}" height="${width}"/>`;
  }
  if (style === "bars_v") {
    const bar = Math.max(1, Math.floor(size * 0.34));
    return `<rect x="${Math.round(cx - bar - 1)}" y="${y}" width="${bar}" height="${size}"/><rect x="${Math.round(cx + 1)}" y="${y}" width="${bar}" height="${size}"/>`;
  }
  if (style === "star") {
    const outer = (size / 2) * 0.94;
    const inner = outer * 0.44;
    const points = Array.from({ length: 10 }, (_, i) => {
      const r = i % 2 === 0 ? outer : inner;
      const angle = (Math.PI / 5) * i - Math.PI / 2;
      return `${cx + r * Math.cos(angle)},${cy + r * Math.sin(angle)}`;
    }).join(" ");
    return `<polygon points="${points}"/>`;
  }
  const radius = style === "squircle" ? Math.floor(size * 0.42) : style === "rounded" ? Math.floor(size * 0.28) : 0;
  return `<rect x="${x}" y="${y}" width="${size}" height="${size}" rx="${radius}" ry="${radius}"/>`;
};

const finderSvg = (x, y, moduleSize, style, theme) => {
  const outer = moduleSize * 7;
  const inner = moduleSize * 5;
  const core = moduleSize * 3;
  const radius = style === "dot" ? "50%" : style === "rounded" ? `${outer * 0.2}` : style === "leaf" ? `${outer * 0.44}` : `${outer * 0.1}`;
  const innerRadius = style === "dot" ? "50%" : style === "rounded" ? `${inner * 0.2}` : style === "leaf" ? `${inner * 0.44}` : `${inner * 0.1}`;
  const coreRadius = style === "dot" ? "50%" : style === "rounded" ? `${core * 0.2}` : style === "leaf" ? `${core * 0.44}` : `${core * 0.1}`;
  return `<rect x="${x}" y="${y}" width="${outer}" height="${outer}" rx="${radius}" ry="${radius}" fill="${theme.dark}" /><rect x="${x + moduleSize}" y="${y + moduleSize}" width="${inner}" height="${inner}" rx="${innerRadius}" ry="${innerRadius}" fill="${theme.light}" /><rect x="${x + moduleSize * 2}" y="${y + moduleSize * 2}" width="${core}" height="${core}" rx="${coreRadius}" ry="${coreRadius}" fill="${theme.accent}" />`;
};

const logoSvg = (logoDataUrl, theme) => {
  if (!logoDataUrl) return "";
  const size = Math.floor(QR_SIZE * 0.2);
  const x = Math.floor((QR_SIZE - size) / 2);
  const y = Math.floor((QR_SIZE - size) / 2);
  const pad = Math.floor(size * 0.16);
  return `<rect x="${x - pad}" y="${y - pad}" width="${size + pad * 2}" height="${size + pad * 2}" rx="40" fill="${theme.light}" stroke="${theme.accent}" stroke-width="12" /><image href="${logoDataUrl}" x="${x}" y="${y}" width="${size}" height="${size}" preserveAspectRatio="xMidYMid slice" />`;
};

export const renderQrToCanvas = (canvas, matrix, options) => {
  const { moduleStyle, cornerStyle, theme, logoImage } = options;
  const ctx = canvas.getContext("2d");
  const count = matrix.length;
  const { moduleSize, offset } = geometry(count);
  canvas.width = QR_SIZE;
  canvas.height = QR_SIZE;
  ctx.imageSmoothingEnabled = false;
  ctx.fillStyle = theme.light;
  ctx.fillRect(0, 0, QR_SIZE, QR_SIZE);
  ctx.fillStyle = theme.dark;

  for (let row = 0; row < count; row += 1) {
    for (let col = 0; col < count; col += 1) {
      if (!matrix[row][col]) continue;
      if (isInFinderArea(row, col, count)) continue;
      const x = offset + col * moduleSize;
      const y = offset + row * moduleSize;
      drawModule(ctx, x, y, moduleSize, moduleStyle);
    }
  }

  const topLeft = { x: offset, y: offset };
  const topRight = { x: offset + (count - 7) * moduleSize, y: offset };
  const bottomLeft = { x: offset, y: offset + (count - 7) * moduleSize };
  drawFinder(ctx, topLeft.x, topLeft.y, moduleSize, cornerStyle, theme.dark, theme.accent, theme.light);
  drawFinder(ctx, topRight.x, topRight.y, moduleSize, cornerStyle, theme.dark, theme.accent, theme.light);
  drawFinder(ctx, bottomLeft.x, bottomLeft.y, moduleSize, cornerStyle, theme.dark, theme.accent, theme.light);
  drawLogo(ctx, logoImage, theme);
};

export const qrMatrixToSvg = (matrix, options) => {
  const { moduleStyle, cornerStyle, theme, logoDataUrl } = options;
  const count = matrix.length;
  const { moduleSize, offset } = geometry(count);
  const nodes = [];
  for (let row = 0; row < count; row += 1) {
    for (let col = 0; col < count; col += 1) {
      if (!matrix[row][col]) continue;
      if (isInFinderArea(row, col, count)) continue;
      const x = offset + col * moduleSize;
      const y = offset + row * moduleSize;
      nodes.push(modulePath(x, y, moduleSize, moduleStyle));
    }
  }
  const tl = finderSvg(offset, offset, moduleSize, cornerStyle, theme);
  const tr = finderSvg(offset + (count - 7) * moduleSize, offset, moduleSize, cornerStyle, theme);
  const bl = finderSvg(offset, offset + (count - 7) * moduleSize, moduleSize, cornerStyle, theme);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${QR_SIZE}" height="${QR_SIZE}" viewBox="0 0 ${QR_SIZE} ${QR_SIZE}"><rect width="${QR_SIZE}" height="${QR_SIZE}" fill="${theme.light}"/><g fill="${theme.dark}" shape-rendering="crispEdges">${nodes.join("")}</g>${tl}${tr}${bl}${logoSvg(logoDataUrl, theme)}</svg>`;
};

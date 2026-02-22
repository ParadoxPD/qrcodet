const safe = (value) => (value ?? "").toString().trim();

const escVCard = (value) => safe(value).replaceAll(";", "\\;").replaceAll(",", "\\,");
const escWifi = (value) => safe(value).replaceAll("\\", "\\\\").replaceAll(";", "\\;").replaceAll(",", "\\,").replaceAll(":", "\\:");

const buildUPI = (values) => {
  const pa = safe(values.pa);
  const pn = safe(values.pn);
  if (!pa || !pn) {
    return { payload: "", error: "UPI ID and Payee Name are required." };
  }

  const params = new URLSearchParams();
  params.set("pa", pa);
  params.set("pn", pn);
  params.set("cu", safe(values.cu) || "INR");
  if (safe(values.am)) params.set("am", safe(values.am));
  if (safe(values.tn)) params.set("tn", safe(values.tn));
  if (safe(values.mc)) params.set("mc", safe(values.mc));
  return { payload: `upi://pay?${params.toString()}`, error: "" };
};

const buildURL = (values) => {
  const input = safe(values.url);
  if (!input) return { payload: "", error: "URL is required." };
  const payload = /^https?:\/\//i.test(input) ? input : `https://${input}`;
  return { payload, error: "" };
};

const buildWiFi = (values) => {
  const ssid = safe(values.ssid);
  if (!ssid) return { payload: "", error: "SSID is required." };
  const security = safe(values.security) || "WPA";
  const password = safe(values.password);
  const hidden = values.hidden ? "true" : "false";
  const payload = `WIFI:T:${escWifi(security)};S:${escWifi(ssid)};P:${escWifi(password)};H:${hidden};;`;
  return { payload, error: "" };
};

const buildVCard = (values) => {
  const name = safe(values.name);
  if (!name) return { payload: "", error: "Full Name is required." };
  const lines = [
    "BEGIN:VCARD",
    "VERSION:3.0",
    `FN:${escVCard(name)}`,
    safe(values.org) ? `ORG:${escVCard(values.org)}` : "",
    safe(values.phone) ? `TEL:${escVCard(values.phone)}` : "",
    safe(values.email) ? `EMAIL:${escVCard(values.email)}` : "",
    safe(values.website) ? `URL:${escVCard(values.website)}` : "",
    "END:VCARD",
  ].filter(Boolean);
  return { payload: lines.join("\n"), error: "" };
};

const buildSMS = (values) => {
  const phone = safe(values.phone);
  if (!phone) return { payload: "", error: "Phone number is required." };
  const body = safe(values.message);
  const payload = body ? `sms:${phone}?body=${encodeURIComponent(body)}` : `sms:${phone}`;
  return { payload, error: "" };
};

const buildEmail = (values) => {
  const to = safe(values.to);
  if (!to) return { payload: "", error: "Recipient email is required." };
  const params = new URLSearchParams();
  if (safe(values.subject)) params.set("subject", safe(values.subject));
  if (safe(values.body)) params.set("body", safe(values.body));
  const suffix = params.toString() ? `?${params.toString()}` : "";
  return { payload: `mailto:${to}${suffix}`, error: "" };
};

const buildText = (values) => {
  const text = safe(values.text);
  if (!text) return { payload: "", error: "Text is required." };
  return { payload: text, error: "" };
};

const BUILDERS = {
  upi: buildUPI,
  url: buildURL,
  wifi: buildWiFi,
  vcard: buildVCard,
  sms: buildSMS,
  email: buildEmail,
  text: buildText,
};

export const buildQrPayload = (builderId, values) => {
  const builder = BUILDERS[builderId];
  if (!builder) {
    return { payload: "", error: `Unsupported QR builder: ${builderId}` };
  }
  return builder(values);
};

export const buildBarcodePayload = (values) => {
  const raw = safe(values.value);
  if (!raw) return { payload: "", error: "Barcode value is required." };
  return { payload: raw, error: "" };
};

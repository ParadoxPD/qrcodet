const sanitize = (value) => String(value ?? "").trim();
const splitLines = (value) => sanitize(value).split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
const addIfValue = (list, label, value) => {
  const clean = sanitize(value);
  if (clean) list.push({ label, value: clean });
};
const parseKeyValueBlock = (lines, separator = ":") => {
  const out = {};
  lines.forEach((line) => {
    const idx = line.indexOf(separator);
    if (idx <= 0) return;
    out[line.slice(0, idx).trim().toUpperCase()] = line.slice(idx + 1).trim();
  });
  return out;
};
const formatName = (format) => sanitize(format).replaceAll("_", " ") || "Unknown";
const inferType = (payload, format) => {
  const text = sanitize(payload);
  if (format) return formatName(format);
  if (/^upi:\/\/pay\?/i.test(text)) return "UPI QR";
  if (/^WIFI:/i.test(text)) return "WiFi QR";
  if (/^BEGIN:VCARD/i.test(text)) return "vCard QR";
  if (/^BEGIN:VCALENDAR/i.test(text)) return "Calendar QR";
  if (/^mailto:/i.test(text)) return "Email QR";
  if (/^sms:/i.test(text)) return "SMS QR";
  if (/^geo:/i.test(text)) return "Geo QR";
  if (/^https?:\/\//i.test(text)) return "URL QR";
  return "Text Code";
};
const parseUrlLike = (payload) => {
  try {
    const url = new URL(payload);
    return { title: "Website / Link", fields: [{ label: "URL", value: url.toString() }, { label: "Host", value: url.host }, { label: "Path", value: url.pathname || "/" }].filter((item) => sanitize(item.value)), notes: ["Opens a web destination when scanned."] };
  } catch {
    return null;
  }
};
const parseUpi = (payload) => {
  if (!/^upi:\/\/pay\?/i.test(payload)) return null;
  const url = new URL(payload);
  const fields = [];
  addIfValue(fields, "UPI ID", url.searchParams.get("pa"));
  addIfValue(fields, "Payee Name", url.searchParams.get("pn"));
  addIfValue(fields, "Amount", url.searchParams.get("am"));
  addIfValue(fields, "Currency", url.searchParams.get("cu"));
  addIfValue(fields, "Note", url.searchParams.get("tn"));
  addIfValue(fields, "Merchant Code", url.searchParams.get("mc"));
  return { title: "UPI Payment", fields, notes: ["Payment QR detected.", "Most UPI apps can open this directly."] };
};
const parseWifi = (payload) => {
  if (!/^WIFI:/i.test(payload)) return null;
  const body = payload.replace(/^WIFI:/i, "").replace(/;;$/, "");
  const entries = body.split(/;(?!\\)/).reduce((acc, segment) => {
    const idx = segment.indexOf(":");
    if (idx <= 0) return acc;
    acc[segment.slice(0, idx)] = segment.slice(idx + 1).replace(/\\([;,:\\])/g, "$1");
    return acc;
  }, {});
  return { title: "WiFi Access", fields: [{ label: "SSID", value: entries.S }, { label: "Security", value: entries.T }, { label: "Password", value: entries.P }, { label: "Hidden", value: entries.H }].filter((item) => sanitize(item.value)), notes: ["Wireless network setup payload."] };
};
const parseMailto = (payload) => {
  if (!/^mailto:/i.test(payload)) return null;
  const url = new URL(payload);
  const fields = [];
  addIfValue(fields, "To", url.pathname);
  addIfValue(fields, "Subject", url.searchParams.get("subject"));
  addIfValue(fields, "Body", url.searchParams.get("body"));
  return { title: "Email Compose", fields, notes: ["Opens a draft email."] };
};
const parseSms = (payload) => {
  if (!/^sms:/i.test(payload)) return null;
  const [recipient, query = ""] = payload.slice(4).split("?");
  const params = new URLSearchParams(query);
  const fields = [];
  addIfValue(fields, "Phone", recipient);
  addIfValue(fields, "Body", params.get("body"));
  return { title: "SMS Shortcut", fields, notes: ["Opens an SMS draft."] };
};
const parseGeo = (payload) => {
  if (!/^geo:/i.test(payload)) return null;
  const match = payload.match(/^geo:([^,]+),([^?]+)(?:\?q=(.*))?$/i);
  if (!match) return null;
  const [, lat, lng, label] = match;
  const fields = [];
  addIfValue(fields, "Latitude", lat);
  addIfValue(fields, "Longitude", lng);
  addIfValue(fields, "Label", label ? decodeURIComponent(label) : "");
  return { title: "Geo Location", fields, notes: ["Opens map coordinates."] };
};
const parseVCard = (payload) => {
  if (!/^BEGIN:VCARD/i.test(payload)) return null;
  const lines = splitLines(payload).filter((line) => !/^BEGIN:VCARD|^END:VCARD|^VERSION:/i.test(line));
  const values = parseKeyValueBlock(lines);
  const fields = [];
  addIfValue(fields, "Full Name", values.FN);
  addIfValue(fields, "Organization", values.ORG);
  addIfValue(fields, "Phone", values.TEL);
  addIfValue(fields, "Email", values.EMAIL);
  addIfValue(fields, "Website", values.URL);
  return { title: "Contact Card", fields, notes: ["vCard contact payload."] };
};
const parseCalendar = (payload) => {
  if (!/^BEGIN:VCALENDAR/i.test(payload)) return null;
  const lines = splitLines(payload).filter((line) => !/^BEGIN:VCALENDAR|^END:VCALENDAR|^BEGIN:VEVENT|^END:VEVENT|^VERSION:/i.test(line));
  const values = parseKeyValueBlock(lines);
  const fields = [];
  addIfValue(fields, "Title", values.SUMMARY);
  addIfValue(fields, "Start", values.DTSTART);
  addIfValue(fields, "End", values.DTEND);
  addIfValue(fields, "Location", values.LOCATION);
  addIfValue(fields, "Description", values.DESCRIPTION);
  return { title: "Calendar Event", fields, notes: ["iCalendar event payload."] };
};
const parseEvent = (payload) => {
  if (!/^EVENT:/i.test(payload)) return null;
  const values = parseKeyValueBlock(splitLines(payload));
  return { title: "Event Payload", fields: Object.entries(values).map(([key, value]) => ({ label: key, value })), notes: ["Custom event payload."] };
};
export const describeScannedCode = ({ text, format }) => {
  const payload = sanitize(text);
  const parsed = [parseUpi(payload), parseWifi(payload), parseMailto(payload), parseSms(payload), parseGeo(payload), parseVCard(payload), parseCalendar(payload), parseEvent(payload), parseUrlLike(payload)].find(Boolean);
  return {
    typeLabel: inferType(payload, format),
    title: parsed?.title || "Scanned Result",
    payload,
    fields: parsed?.fields || [],
    usefulInfo: [{ label: "Characters", value: String(payload.length) }, { label: "Format", value: inferType(payload, format) }, { label: "Encoding", value: /^\d+$/.test(payload) ? "Numeric" : "Text / Mixed" }],
    notes: parsed?.notes || ["No structured parser matched this payload."],
  };
};

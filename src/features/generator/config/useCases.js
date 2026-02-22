const hasText = (value) => typeof value === "string" && value.trim().length > 0;
const digits = (value, length) => new RegExp(`^\\d{${length}}$`).test((value || "").trim());
const isEmail = (value) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test((value || "").trim());
const isUrl = (value) => /^(https?:\/\/)?([\w-]+\.)+[\w-]{2,}(\/.*)?$/i.test((value || "").trim());
const isPhone = (value) => /^\+?[0-9]{8,15}$/.test((value || "").trim());
const upiId = (value) => /^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z0-9.\-_]{2,}$/.test((value || "").trim());
const decimal = (value) => /^([1-9]\d{0,6}|0)(\.\d{1,2})?$/.test((value || "").trim());

const buildField = (config) => ({
  ...config,
  validate: config.validate || (() => ""),
  requiredMessage: config.requiredMessage || `${config.label} is required.`,
});

export const QR_USE_CASES = [
  {
    id: "upi",
    label: "UPI Payment",
    description: "Collect payments with upi://pay payloads.",
    filenamePrefix: "upi-qr",
    builder: "upi",
    defaults: { cu: "INR", header: "Scan & Pay", footer: "Powered by UPI" },
    fields: [
      buildField({
        name: "pa",
        label: "UPI ID",
        helperText: "Use valid VPA format, e.g. merchant@okicici",
        placeholder: "merchant@upi",
        required: true,
        validate: (v) => (hasText(v) && upiId(v) ? "" : "UPI ID must look like name@bank."),
      }),
      buildField({
        name: "pn",
        label: "Payee Name",
        helperText: "The receiving merchant/person name displayed in app.",
        placeholder: "Merchant Name",
        required: true,
        validate: (v) => (hasText(v) ? "" : "Payee Name cannot be empty."),
      }),
      buildField({
        name: "am",
        label: "Amount",
        helperText: "Optional fixed amount, up to 2 decimals.",
        placeholder: "0.00",
        type: "number",
        validate: (v) => (!hasText(v) || decimal(v) ? "" : "Amount must be a valid decimal, e.g. 1299.50."),
      }),
      buildField({
        name: "tn",
        label: "Transaction Note",
        helperText: "Visible in payer transaction history.",
        placeholder: "Invoice #1032",
        validate: (v) => (!hasText(v) || v.trim().length <= 80 ? "" : "Transaction Note must be 80 chars or less."),
      }),
      buildField({
        name: "mc",
        label: "Merchant Code",
        helperText: "MCC should be 4 numeric digits.",
        placeholder: "5411",
        validate: (v) => (!hasText(v) || digits(v, 4) ? "" : "Merchant Code must be exactly 4 digits."),
      }),
      buildField({
        name: "cu",
        label: "Currency",
        helperText: "UPI currently expects INR.",
        type: "select",
        options: ["INR"],
        required: true,
      }),
    ],
  },
  {
    id: "url",
    label: "Website URL",
    description: "Share links for products, portfolios, and landing pages.",
    filenamePrefix: "url-qr",
    builder: "url",
    defaults: { header: "Open Link", footer: "Scan to visit" },
    fields: [
      buildField({
        name: "url",
        label: "URL",
        helperText: "Protocol optional; https:// is added automatically.",
        placeholder: "https://example.com",
        required: true,
        validate: (v) => (hasText(v) && isUrl(v) ? "" : "Enter a valid URL."),
      }),
    ],
  },
  {
    id: "wifi",
    label: "WiFi Access",
    description: "Let guests connect by scanning once.",
    filenamePrefix: "wifi-qr",
    builder: "wifi",
    defaults: { header: "Guest WiFi", footer: "Scan to connect" },
    fields: [
      buildField({
        name: "ssid",
        label: "SSID",
        helperText: "Network name exactly as configured on router.",
        placeholder: "Cafe-Network",
        required: true,
        validate: (v) => (hasText(v) ? "" : "SSID is required."),
      }),
      buildField({
        name: "security",
        label: "Security",
        helperText: "Use nopass only for open networks.",
        type: "select",
        options: ["WPA", "WEP", "nopass"],
        required: true,
      }),
      buildField({
        name: "password",
        label: "Password",
        helperText: "Required for WPA/WEP networks.",
        placeholder: "wifi password",
      }),
      buildField({
        name: "hidden",
        label: "Hidden Network",
        helperText: "Enable if SSID broadcast is disabled.",
        type: "checkbox",
      }),
    ],
  },
  {
    id: "contact",
    label: "Contact Card",
    description: "Generate a vCard QR for quick contact save.",
    filenamePrefix: "contact-qr",
    builder: "vcard",
    defaults: { header: "Save Contact", footer: "vCard" },
    fields: [
      buildField({
        name: "name",
        label: "Full Name",
        helperText: "Primary contact name.",
        placeholder: "Aanya Rao",
        required: true,
        validate: (v) => (hasText(v) ? "" : "Full Name is required."),
      }),
      buildField({
        name: "org",
        label: "Organization",
        helperText: "Company or group name.",
        placeholder: "QRCodet",
      }),
      buildField({
        name: "phone",
        label: "Phone",
        helperText: "Include country code, e.g. +919999999999.",
        placeholder: "+919999999999",
        validate: (v) => (!hasText(v) || isPhone(v) ? "" : "Phone number should contain 8-15 digits with optional +."),
      }),
      buildField({
        name: "email",
        label: "Email",
        helperText: "Used by contact apps to compose mail.",
        placeholder: "contact@example.com",
        validate: (v) => (!hasText(v) || isEmail(v) ? "" : "Enter a valid email address."),
      }),
      buildField({
        name: "website",
        label: "Website",
        helperText: "Company or profile URL.",
        placeholder: "https://example.com",
        validate: (v) => (!hasText(v) || isUrl(v) ? "" : "Enter a valid website URL."),
      }),
    ],
  },
  {
    id: "sms",
    label: "SMS",
    description: "Pre-fill a message with one scan.",
    filenamePrefix: "sms-qr",
    builder: "sms",
    defaults: { header: "Text Us", footer: "SMS shortcut" },
    fields: [
      buildField({
        name: "phone",
        label: "Phone Number",
        helperText: "International format recommended.",
        placeholder: "+919999999999",
        required: true,
        validate: (v) => (hasText(v) && isPhone(v) ? "" : "Phone number should contain 8-15 digits."),
      }),
      buildField({
        name: "message",
        label: "Message",
        helperText: "Optional message body appended to SMS.",
        placeholder: "Hello, I want to order...",
      }),
    ],
  },
  {
    id: "email",
    label: "Email",
    description: "Open a compose window with subject/body.",
    filenamePrefix: "email-qr",
    builder: "email",
    defaults: { header: "Write Email", footer: "mailto shortcut" },
    fields: [
      buildField({
        name: "to",
        label: "To",
        helperText: "Recipient mailbox.",
        placeholder: "sales@example.com",
        required: true,
        validate: (v) => (hasText(v) && isEmail(v) ? "" : "Recipient email is invalid."),
      }),
      buildField({
        name: "subject",
        label: "Subject",
        helperText: "Mail subject line.",
        placeholder: "Demo request",
      }),
      buildField({
        name: "body",
        label: "Body",
        helperText: "Mail body content.",
        placeholder: "Please share details...",
      }),
    ],
  },
  {
    id: "text",
    label: "Plain Text",
    description: "Embed arbitrary text data.",
    filenamePrefix: "text-qr",
    builder: "text",
    defaults: { header: "Scan Text", footer: "Encoded text" },
    fields: [
      buildField({
        name: "text",
        label: "Text",
        helperText: "Any plain text or code snippet.",
        placeholder: "Any notes or content",
        required: true,
        validate: (v) => (hasText(v) ? "" : "Text content cannot be empty."),
      }),
    ],
  },
];

export const BARCODE_USE_CASES = [
  {
    id: "code128",
    label: "Code 128",
    description: "Best general-purpose barcode for IDs and labels.",
    filenamePrefix: "code128",
    format: "CODE128",
    fields: [
      buildField({
        name: "value",
        label: "Value",
        helperText: "Alphanumeric value allowed.",
        placeholder: "INV-2026-001",
        required: true,
        validate: (v) => (hasText(v) ? "" : "Barcode value is required."),
      }),
    ],
  },
  {
    id: "ean13",
    label: "EAN-13",
    description: "Retail product code for global markets.",
    filenamePrefix: "ean13",
    format: "EAN13",
    fields: [
      buildField({
        name: "value",
        label: "13 Digits",
        helperText: "Numbers only. Must be exactly 13 digits.",
        placeholder: "5901234123457",
        required: true,
        validate: (v) => (digits(v, 13) ? "" : "EAN-13 value must be exactly 13 digits."),
      }),
    ],
  },
  {
    id: "upca",
    label: "UPC-A",
    description: "Common barcode for North American retail.",
    filenamePrefix: "upca",
    format: "UPC",
    fields: [
      buildField({
        name: "value",
        label: "12 Digits",
        helperText: "Numbers only. Must be exactly 12 digits.",
        placeholder: "036000291452",
        required: true,
        validate: (v) => (digits(v, 12) ? "" : "UPC-A value must be exactly 12 digits."),
      }),
    ],
  },
  {
    id: "ean8",
    label: "EAN-8",
    description: "Compact retail barcode for smaller packaging.",
    filenamePrefix: "ean8",
    format: "EAN8",
    fields: [
      buildField({
        name: "value",
        label: "8 Digits",
        helperText: "Numbers only. Must be exactly 8 digits.",
        placeholder: "55123457",
        required: true,
        validate: (v) => (digits(v, 8) ? "" : "EAN-8 value must be exactly 8 digits."),
      }),
    ],
  },
  {
    id: "itf14",
    label: "ITF-14",
    description: "Shipping carton barcode for logistics.",
    filenamePrefix: "itf14",
    format: "ITF14",
    fields: [
      buildField({
        name: "value",
        label: "14 Digits",
        helperText: "Numbers only. Must be exactly 14 digits.",
        placeholder: "10012345000017",
        required: true,
        validate: (v) => (digits(v, 14) ? "" : "ITF-14 value must be exactly 14 digits."),
      }),
    ],
  },
];

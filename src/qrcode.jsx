import { useEffect, useMemo, useRef, useState } from "react";
import { toPng, toSvg } from "html-to-image";
import GeneratorControls from "./features/generator/components/GeneratorControls";
import PreviewPane from "./features/generator/components/PreviewPane";
import { FRAMES, QR_CORNER_STYLES, QR_STYLES, THEMES } from "./features/generator/config/appearance";
import { BARCODE_USE_CASES, QR_USE_CASES } from "./features/generator/config/useCases";
import { renderBarcodeToSvg } from "./features/generator/lib/barcodeRenderer";
import { buildBarcodePayload, buildQrPayload } from "./features/generator/lib/payloadBuilders";
import { buildQrMatrix, renderQrToCanvas } from "./features/generator/lib/qrRenderer";

const PRESET_STORAGE_KEY = "qrcodet.presets.v1";

const hasValue = (value) => {
  if (typeof value === "boolean") return value;
  return String(value ?? "").trim().length > 0;
};

const withInitialValues = (useCase) => {
  const fieldValues = Object.fromEntries(
    useCase.fields.map((field) => {
      if (field.type === "checkbox") return [field.name, false];
      if (field.type === "select") return [field.name, field.options?.[0] || ""];
      return [field.name, ""];
    }),
  );
  return { ...fieldValues, ...(useCase.defaults || {}) };
};

const createValuesMap = () => {
  const map = {};
  QR_USE_CASES.forEach((useCase) => {
    map[`qr:${useCase.id}`] = withInitialValues(useCase);
  });
  BARCODE_USE_CASES.forEach((useCase) => {
    map[`barcode:${useCase.id}`] = withInitialValues(useCase);
  });
  return map;
};

const loadPresets = () => {
  try {
    const raw = localStorage.getItem(PRESET_STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
};

export default function App() {
  const [mode, setMode] = useState("qr");
  const [selectedQrUseCaseId, setSelectedQrUseCaseId] = useState("upi");
  const [selectedBarcodeUseCaseId, setSelectedBarcodeUseCaseId] = useState("code128");
  const [valuesMap, setValuesMap] = useState(createValuesMap);
  const [appearance, setAppearanceState] = useState({
    header: "Scan & Pay",
    footer: "Powered by QRCodet",
    themeId: "classic",
    qrStyle: "rounded",
    cornerStyle: "rounded",
    errorLevel: "M",
    frameId: "scan",
  });
  const [matrix, setMatrix] = useState(null);
  const [runtimeError, setRuntimeError] = useState("");
  const [hasCode, setHasCode] = useState(false);
  const [logoDataUrl, setLogoDataUrl] = useState("");
  const [logoImage, setLogoImage] = useState(null);
  const [presets, setPresets] = useState(loadPresets);
  const [presetName, setPresetName] = useState("");

  const qrCanvasRef = useRef(null);
  const barcodeRef = useRef(null);
  const frameCaptureRef = useRef(null);

  const useCases = mode === "qr" ? QR_USE_CASES : BARCODE_USE_CASES;
  const selectedUseCaseId = mode === "qr" ? selectedQrUseCaseId : selectedBarcodeUseCaseId;
  const selectedUseCase = useCases.find((item) => item.id === selectedUseCaseId) || useCases[0];
  const formKey = `${mode}:${selectedUseCase.id}`;
  const values = valuesMap[formKey] || {};
  const theme = THEMES.find((item) => item.id === appearance.themeId) || THEMES[0];

  useEffect(() => {
    localStorage.setItem(PRESET_STORAGE_KEY, JSON.stringify(presets));
  }, [presets]);

  useEffect(() => {
    if (!logoDataUrl) {
      setLogoImage(null);
      return;
    }
    const image = new Image();
    image.onload = () => setLogoImage(image);
    image.src = logoDataUrl;
  }, [logoDataUrl]);

  const setSelectedUseCaseId = (id) => {
    if (mode === "qr") setSelectedQrUseCaseId(id);
    if (mode === "barcode") setSelectedBarcodeUseCaseId(id);
  };

  const setValue = (fieldName, fieldValue) => {
    setValuesMap((previous) => ({
      ...previous,
      [formKey]: { ...(previous[formKey] || {}), [fieldName]: fieldValue },
    }));
  };

  const setAppearance = (key, value) => {
    setAppearanceState((previous) => ({ ...previous, [key]: value }));
  };

  const validationByField = useMemo(() => {
    const map = {};
    for (const field of selectedUseCase.fields) {
      const value = values[field.name];
      if (field.required && !hasValue(value)) {
        map[field.name] = field.requiredMessage || `${field.label} is required.`;
        continue;
      }
      const message = field.validate?.(value, values);
      if (message) map[field.name] = message;
    }
    if (selectedUseCase.id === "wifi" && values.security !== "nopass" && !hasValue(values.password)) {
      map.password = "Password is required when security is WPA or WEP.";
    }
    return map;
  }, [selectedUseCase, values]);

  const validationError = useMemo(() => Object.values(validationByField)[0] || "", [validationByField]);

  const payloadResult = useMemo(() => {
    if (validationError) return { payload: "", error: validationError };
    if (mode === "qr") return buildQrPayload(selectedUseCase.builder, values);
    return buildBarcodePayload(values);
  }, [mode, selectedUseCase, validationError, values]);

  useEffect(() => {
    setRuntimeError("");
    setHasCode(false);
    if (mode !== "qr") {
      setMatrix(null);
      return;
    }
    if (!payloadResult.payload) {
      setMatrix(null);
      return;
    }
    try {
      setMatrix(buildQrMatrix(payloadResult.payload, appearance.errorLevel));
    } catch (error) {
      setMatrix(null);
      setRuntimeError(error?.message || "Failed to generate QR matrix.");
    }
  }, [mode, payloadResult.payload, appearance.errorLevel]);

  useEffect(() => {
    if (mode !== "qr") return;
    if (!matrix || !qrCanvasRef.current) {
      setHasCode(false);
      return;
    }
    renderQrToCanvas(qrCanvasRef.current, matrix, {
      moduleStyle: appearance.qrStyle,
      cornerStyle: appearance.cornerStyle,
      theme,
      logoImage,
    });
    setHasCode(true);
  }, [mode, matrix, appearance.qrStyle, appearance.cornerStyle, appearance.frameId, theme, logoImage]);

  useEffect(() => {
    if (mode !== "barcode") return;
    setRuntimeError("");
    if (!payloadResult.payload || !barcodeRef.current) {
      setHasCode(false);
      if (barcodeRef.current) barcodeRef.current.innerHTML = "";
      return;
    }
    const result = renderBarcodeToSvg(barcodeRef.current, payloadResult.payload, selectedUseCase.format, selectedUseCase.renderer, theme);
    setHasCode(result.ok);
    setRuntimeError(result.error);
  }, [mode, payloadResult.payload, selectedUseCase.format, selectedUseCase.renderer, theme]);

  useEffect(() => {
    const defaults = selectedUseCase.defaults || {};
    setAppearanceState((previous) => ({
      ...previous,
      header: defaults.header ?? previous.header,
      footer: defaults.footer ?? previous.footer,
    }));
  }, [selectedUseCase.id]);

  const effectiveError = payloadResult.error || runtimeError;
  const fileBase = `${selectedUseCase.filenamePrefix}-${Date.now()}`;
  const metaLine = mode === "qr" ? values.pn || values.name || values.url || "" : values.value || "";

  const downloadSvg = () => {
    if (!hasCode) return;
    if (!frameCaptureRef.current) return;
    toSvg(frameCaptureRef.current, { cacheBust: true })
      .then((dataUrl) => {
        const link = document.createElement("a");
        link.download = `${fileBase}.svg`;
        link.href = dataUrl;
        link.click();
      })
      .catch(() => {});
  };

  const downloadPng = async () => {
    if (!hasCode) return;
    if (frameCaptureRef.current) {
      const data = await toPng(frameCaptureRef.current, { cacheBust: true, pixelRatio: 5 });
      const link = document.createElement("a");
      link.download = `${fileBase}.png`;
      link.href = data;
      link.click();
    }
  };

  const onLogoChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const result = typeof reader.result === "string" ? reader.result : "";
      setLogoDataUrl(result);
    };
    reader.readAsDataURL(file);
  };

  const savePreset = () => {
    const cleanName = presetName.trim();
    if (!cleanName) return;
    const preset = {
      id: `preset-${Date.now()}`,
      name: cleanName,
      mode,
      useCaseId: selectedUseCase.id,
      values,
      appearance,
      logoDataUrl,
      createdAt: Date.now(),
    };
    setPresets((previous) => [preset, ...previous]);
    setPresetName("");
  };

  const loadPresetById = (presetId) => {
    const preset = presets.find((item) => item.id === presetId);
    if (!preset) return;
    setMode(preset.mode);
    if (preset.mode === "qr") setSelectedQrUseCaseId(preset.useCaseId);
    if (preset.mode === "barcode") setSelectedBarcodeUseCaseId(preset.useCaseId);
    setValuesMap((previous) => ({
      ...previous,
      [`${preset.mode}:${preset.useCaseId}`]: { ...preset.values },
    }));
    setAppearanceState((previous) => ({ ...previous, ...preset.appearance }));
    setLogoDataUrl(preset.logoDataUrl || "");
  };

  const deletePresetById = (presetId) => {
    setPresets((previous) => previous.filter((item) => item.id !== presetId));
  };

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <p className="brand-kicker">QRCodet Studio</p>
          <h1>QR & Barcode Builder</h1>
          <p className="tagline">High-resolution outputs, modular use-case definitions, branded themes, and reusable team presets.</p>
        </div>
      </header>

      <section className="workspace">
        <GeneratorControls
          mode={mode}
          setMode={setMode}
          useCases={useCases}
          selectedUseCaseId={selectedUseCase.id}
          setSelectedUseCaseId={setSelectedUseCaseId}
          values={values}
          setValue={setValue}
          appearance={appearance}
          setAppearance={setAppearance}
          themes={THEMES}
          qrStyles={QR_STYLES}
          qrCornerStyles={QR_CORNER_STYLES}
          frames={FRAMES}
          selectedUseCase={selectedUseCase}
          validationByField={validationByField}
          logoPreview={logoDataUrl}
          onLogoChange={onLogoChange}
          onClearLogo={() => setLogoDataUrl("")}
          presets={presets}
          presetName={presetName}
          setPresetName={setPresetName}
          onSavePreset={savePreset}
          onLoadPreset={loadPresetById}
          onDeletePreset={deletePresetById}
        />

        <PreviewPane
          mode={mode}
          hasCode={hasCode}
          theme={theme}
          appearance={appearance}
          previewLabel={selectedUseCase.label}
          payload={payloadResult.payload}
          error={effectiveError}
          metaLine={metaLine}
          fields={selectedUseCase.fields}
          qrCanvasRef={qrCanvasRef}
          barcodeRef={barcodeRef}
          frameCaptureRef={frameCaptureRef}
          onDownloadPng={downloadPng}
          onDownloadSvg={downloadSvg}
        />
      </section>
    </main>
  );
}

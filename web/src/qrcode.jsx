import { useEffect, useMemo, useRef, useState } from "react";
import { toPng, toSvg } from "html-to-image";
import GeneratorControls from "./features/generator/components/GeneratorControls";
import PreviewPane from "./features/generator/components/PreviewPane";
import ScannerGateway from "./features/scanner/components/ScannerGateway";
import { FRAMES, QR_CORNER_STYLES, QR_STYLES, THEMES } from "./features/generator/config/appearance";
import { BARCODE_USE_CASES, QR_USE_CASES } from "./features/generator/config/useCases";
import { buildBarcodePayload, buildQrPayload } from "./features/generator/lib/payloadBuilders";

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
  const [workspaceTab, setWorkspaceTab] = useState("build");
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
  const [exportModal, setExportModal] = useState({ open: false, label: "" });

  const qrCanvasRef = useRef(null);
  const barcodeRef = useRef(null);
  const frameCaptureRef = useRef(null);
  const qrRendererModuleRef = useRef(null);
  const barcodeRendererModuleRef = useRef(null);

  const loadQrRendererModule = () => {
    if (!qrRendererModuleRef.current) {
      qrRendererModuleRef.current = import("./features/generator/lib/qrRenderer");
    }
    return qrRendererModuleRef.current;
  };

  const loadBarcodeRendererModule = () => {
    if (!barcodeRendererModuleRef.current) {
      barcodeRendererModuleRef.current = import("./features/generator/lib/barcodeRenderer");
    }
    return barcodeRendererModuleRef.current;
  };

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
    let cancelled = false;
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
    loadQrRendererModule()
      .then(({ buildQrMatrix }) => {
        if (cancelled) return;
        try {
          setMatrix(buildQrMatrix(payloadResult.payload, appearance.errorLevel));
        } catch (error) {
          setMatrix(null);
          setRuntimeError(error?.message || "Failed to generate QR matrix.");
        }
      })
      .catch(() => {
        if (cancelled) return;
        setMatrix(null);
        setRuntimeError("Failed to load QR renderer.");
      });
    return () => {
      cancelled = true;
    };
  }, [mode, payloadResult.payload, appearance.errorLevel]);

  useEffect(() => {
    let cancelled = false;
    if (mode !== "qr") return;
    if (!matrix || !qrCanvasRef.current) {
      setHasCode(false);
      return;
    }
    loadQrRendererModule()
      .then(({ renderQrToCanvas }) => {
        if (cancelled || !qrCanvasRef.current) return;
        renderQrToCanvas(qrCanvasRef.current, matrix, {
          moduleStyle: appearance.qrStyle,
          cornerStyle: appearance.cornerStyle,
          theme,
          logoImage,
        });
        setHasCode(true);
      })
      .catch(() => {
        if (cancelled) return;
        setHasCode(false);
        setRuntimeError("Failed to render QR preview.");
      });
    return () => {
      cancelled = true;
    };
  }, [mode, matrix, appearance.qrStyle, appearance.cornerStyle, appearance.frameId, theme, logoImage]);

  useEffect(() => {
    let cancelled = false;
    if (mode !== "barcode") return;
    setRuntimeError("");
    if (!payloadResult.payload || !barcodeRef.current) {
      setHasCode(false);
      if (barcodeRef.current) barcodeRef.current.innerHTML = "";
      return;
    }
    loadBarcodeRendererModule()
      .then(({ renderBarcodeToSvg }) => {
        if (cancelled || !barcodeRef.current) return;
        const result = renderBarcodeToSvg(barcodeRef.current, payloadResult.payload, selectedUseCase.format, selectedUseCase.renderer, theme);
        setHasCode(result.ok);
        setRuntimeError(result.error);
      })
      .catch(() => {
        if (cancelled) return;
        setHasCode(false);
        setRuntimeError("Failed to load barcode renderer.");
      });
    return () => {
      cancelled = true;
    };
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

  const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const openExportModal = async (label) => {
    setExportModal({ open: true, label });
    await wait(40);
    await new Promise((resolve) => requestAnimationFrame(() => resolve()));
  };

  const closeExportModal = async (startedAt, minVisibleMs = 1200) => {
    const elapsed = Date.now() - startedAt;
    if (elapsed < minVisibleMs) {
      await wait(minVisibleMs - elapsed);
    }
    setExportModal({ open: false, label: "" });
  };

  const downloadSvg = () => {
    if (!hasCode || !frameCaptureRef.current) return;
    const startedAt = Date.now();
    openExportModal("Preparing SVG export...")
      .then(() => toSvg(frameCaptureRef.current, { cacheBust: true }))
      .then((dataUrl) => {
        setExportModal({ open: true, label: "Starting SVG download..." });
        const link = document.createElement("a");
        link.download = `${fileBase}.svg`;
        link.href = dataUrl;
        link.click();
      })
      .catch(() => setRuntimeError("Failed to export SVG."))
      .finally(() => closeExportModal(startedAt));
  };

  const downloadPng = async () => {
    if (!hasCode || !frameCaptureRef.current) return;
    const startedAt = Date.now();
    try {
      await openExportModal("Preparing PNG export...");
      const data = await toPng(frameCaptureRef.current, { cacheBust: true, pixelRatio: 5 });
      setExportModal({ open: true, label: "Starting PNG download..." });
      const link = document.createElement("a");
      link.download = `${fileBase}.png`;
      link.href = data;
      link.click();
    } catch {
      setRuntimeError("Failed to export PNG.");
    } finally {
      await closeExportModal(startedAt);
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
          <p className="tagline">High-resolution outputs, modular use-case definitions, branded themes, reusable presets, and realtime scan intelligence.</p>
        </div>
      </header>

      <div className="panel workspace-tabs">
        <div className="tab-row">
          <button className={workspaceTab === "build" ? "tab active" : "tab"} onClick={() => setWorkspaceTab("build")}>
            Build Codes
          </button>
          <button className={workspaceTab === "scan" ? "tab active" : "tab"} onClick={() => setWorkspaceTab("scan")}>
            Scan Codes
          </button>
        </div>
      </div>

      {workspaceTab === "build" ? (
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

          <div className="preview-column">
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
          </div>
        </section>
      ) : (
        <section className="scanner-workspace">
          <ScannerGateway />
        </section>
      )}

      {exportModal.open ? (
        <div className="modal-backdrop" role="status" aria-live="polite">
          <div className="modal-card">
            <div className="spinner" />
            <p>{exportModal.label}</p>
          </div>
        </div>
      ) : null}
    </main>
  );
}

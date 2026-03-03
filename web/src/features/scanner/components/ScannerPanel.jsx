import { useEffect, useMemo, useRef, useState } from "react";
import { BrowserMultiFormatReader } from "@zxing/browser";
import CollapsiblePanel from "../../generator/components/CollapsiblePanel";
import { describeScannedCode } from "../lib/scanParser";

const isExpectedScanMiss = (error) => {
  const name = error?.name || "";
  return name === "NotFoundException" || name === "ChecksumException" || name === "FormatException";
};

const labelDevice = (device, index) => device.label || `Camera ${index + 1}`;

export default function ScannerPanel() {
  const readerRef = useRef(null);
  const controlsRef = useRef(null);
  const videoRef = useRef(null);
  const [scannerMode, setScannerMode] = useState("camera");
  const [devices, setDevices] = useState([]);
  const [deviceId, setDeviceId] = useState("");
  const [isStarting, setIsStarting] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [scannerError, setScannerError] = useState("");
  const [lastResult, setLastResult] = useState(null);
  const [uploadName, setUploadName] = useState("");
  const [collapsed, setCollapsed] = useState(false);

  useEffect(() => {
    readerRef.current = new BrowserMultiFormatReader(undefined, {
      delayBetweenScanAttempts: 200,
      delayBetweenScanSuccess: 900,
    });

    const bootstrapCameras = async () => {
      try {
        // Request permission up-front so browsers expose device labels reliably.
        const tempStream = await navigator.mediaDevices.getUserMedia({ video: true });
        tempStream.getTracks().forEach((track) => track.stop());
      } catch {
        // Ignore. decodeFromVideoDevice will surface permission errors.
      }

      BrowserMultiFormatReader.listVideoInputDevices()
        .then((items) => {
          setDevices(items);
          setDeviceId((current) => current || items[0]?.deviceId || "");
        })
        .catch(() => {
          setScannerError("No camera devices were found for this browser.");
        });
    };
    bootstrapCameras();

    return () => {
      controlsRef.current?.stop?.();
      controlsRef.current = null;
      readerRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (scannerMode !== "camera") {
      controlsRef.current?.stop?.();
      controlsRef.current = null;
      setIsScanning(false);
    }
  }, [scannerMode]);

  const parsedResult = useMemo(() => (lastResult ? describeScannedCode(lastResult) : null), [lastResult]);

  const startScanning = async () => {
    if (!readerRef.current || !videoRef.current) return;
    setIsStarting(true);
    setScannerError("");
    controlsRef.current?.stop?.();
    controlsRef.current = null;

    try {
      const controls = await readerRef.current.decodeFromVideoDevice(deviceId || undefined, videoRef.current, (result, error) => {
        if (result) {
          setLastResult({ text: result.getText(), format: result.getBarcodeFormat()?.toString?.() || "", scannedAt: Date.now() });
          setScannerError("");
          setIsScanning(true);
        }
        if (error && !isExpectedScanMiss(error)) {
          setScannerError(error.message || "Camera scanning failed.");
        }
      });
      controlsRef.current = controls;
      setIsScanning(true);
    } catch (error) {
      setScannerError(error?.message || "Unable to start the scanner. Check browser camera permission.");
      setIsScanning(false);
    } finally {
      setIsStarting(false);
    }
  };

  const stopScanning = () => {
    controlsRef.current?.stop?.();
    controlsRef.current = null;
    setIsScanning(false);
  };

  const handleUpload = async (event) => {
    const file = event.target.files?.[0];
    if (!file || !readerRef.current) return;
    const objectUrl = URL.createObjectURL(file);
    setUploadName(file.name);
    setScannerError("");
    try {
      const result = await readerRef.current.decodeFromImageUrl(objectUrl);
      setLastResult({ text: result.getText(), format: result.getBarcodeFormat()?.toString?.() || "", scannedAt: Date.now() });
    } catch (error) {
      setScannerError(error?.message || "No supported code was found in this image.");
    } finally {
      URL.revokeObjectURL(objectUrl);
      event.target.value = "";
    }
  };

  return (
    <CollapsiblePanel
      title="Scan QR / Barcode"
      eyebrow="Scanner"
      collapsed={collapsed}
      onToggle={() => setCollapsed((value) => !value)}
      className="scanner-panel"
      action={<div className="scanner-chip-row"><span className={isScanning ? "status-chip live" : "status-chip"}>{isScanning ? "Live" : "Idle"}</span></div>}
    >
      <div className="scanner-mode-row">
        <button className={scannerMode === "camera" ? "pill active" : "pill"} type="button" onClick={() => setScannerMode("camera")}>Camera</button>
        <button className={scannerMode === "upload" ? "pill active" : "pill"} type="button" onClick={() => setScannerMode("upload")}>Image Upload</button>
      </div>

      {scannerMode === "camera" ? (
        <>
          <div className="field-grid scanner-grid">
            <label className="field">
              <span>Camera</span>
              <select className="input" value={deviceId} onChange={(event) => setDeviceId(event.target.value)}>
                {devices.length === 0 ? <option value="">Default camera</option> : null}
                {devices.map((device, index) => {
                  const optionValue = device.deviceId || "";
                  return (
                    <option key={`${optionValue || "default"}-${index}`} value={optionValue}>
                      {labelDevice(device, index)}
                    </option>
                  );
                })}
              </select>
            </label>
          </div>
          <div className="scanner-preview-wrap">
            <video ref={videoRef} className="scanner-video" muted playsInline />
            {!isScanning ? <div className="scanner-overlay">Start realtime scanning to detect QR and barcode formats.</div> : null}
          </div>
          <div className="action-row">
            <button className="solid" type="button" onClick={startScanning} disabled={isStarting}>{isStarting ? "Starting..." : "Start Scan"}</button>
            <button className="ghost" type="button" onClick={stopScanning} disabled={!isScanning}>Stop</button>
          </div>
        </>
      ) : (
        <div className="upload-stack">
          <label className="upload-btn scanner-upload-btn">
            <input type="file" accept="image/*" onChange={handleUpload} />
            <span>Upload Code Image</span>
          </label>
          <p className="muted-line">{uploadName ? `Last file: ${uploadName}` : "PNG, JPG, or WebP images supported."}</p>
        </div>
      )}

      {scannerError ? <p className="scanner-error">{scannerError}</p> : null}

      <div className="scanner-result-grid">
        <div className="scanner-result-card">
          <p className="eyebrow compact">Detected Type</p>
          <strong>{parsedResult?.typeLabel || "Nothing scanned yet."}</strong>
        </div>
        <div className="scanner-result-card">
          <p className="eyebrow compact">Summary</p>
          <strong>{parsedResult?.title || "Awaiting result"}</strong>
        </div>
      </div>

      <div className="scanner-data-layout">
        <div>
          <p className="eyebrow compact">Fields</p>
          <div className="scanner-info-list">
            {(parsedResult?.fields || []).length === 0 ? <p className="muted-line">Structured fields will appear here when the payload is recognized.</p> : parsedResult.fields.map((item) => (
              <div className="scanner-info-item" key={`${item.label}:${item.value}`}>
                <span>{item.label}</span>
                <strong>{item.value}</strong>
              </div>
            ))}
          </div>
        </div>
        <div>
          <p className="eyebrow compact">Useful Info</p>
          <div className="scanner-info-list">
            {(parsedResult?.usefulInfo || []).map((item) => (
              <div className="scanner-info-item" key={item.label}>
                <span>{item.label}</span>
                <strong>{item.value}</strong>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="payload-panel scanner-payload-panel">
        <p className="eyebrow compact">Decoded Payload</p>
        <pre>{parsedResult?.payload || "Nothing decoded yet."}</pre>
      </div>
    </CollapsiblePanel>
  );
}

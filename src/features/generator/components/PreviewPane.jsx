import CodeFrame from "./CodeFrame";

export default function PreviewPane({
  mode,
  hasCode,
  theme,
  appearance,
  previewLabel,
  payload,
  error,
  metaLine,
  fields,
  qrCanvasRef,
  barcodeRef,
  frameCaptureRef,
  onDownloadPng,
  onDownloadSvg,
}) {
  const body = mode === "qr" ? (
    <canvas ref={qrCanvasRef} className={hasCode ? "qr-canvas ready" : "qr-canvas"} />
  ) : (
    <svg ref={barcodeRef} width="480" height="220" className={hasCode ? "barcode-svg ready" : "barcode-svg"} />
  );

  return (
    <aside className="preview-shell">
      <div className="panel preview-panel">
        <p className="eyebrow">Live Preview</p>
        <div className="preview-grid">
          <div ref={frameCaptureRef}>
            <CodeFrame frameId={mode === "qr" ? appearance.frameId : "card"} theme={theme} header={appearance.header} footer={appearance.footer} metaLine={metaLine}>
              {body}
            </CodeFrame>
          </div>
        </div>

        <div className="status-row">
          <span className={hasCode ? "dot ok" : "dot"} />
          <p>{hasCode ? `${previewLabel} ready` : error || "Fill required fields to generate"}</p>
        </div>

        <div className="action-row">
          <button className="ghost" onClick={onDownloadSvg} disabled={!hasCode}>
            Download SVG
          </button>
          <button className="solid" onClick={onDownloadPng} disabled={!hasCode}>
            Download PNG
          </button>
        </div>
      </div>

      <div className="panel payload-panel">
        <p className="eyebrow">Encoded Payload</p>
        <pre>{payload || "Nothing encoded yet."}</pre>
      </div>

      <div className="panel">
        <p className="eyebrow">Field Reference</p>
        <div className="ref-list">
          {fields.map((field) => (
            <div className="ref-item" key={field.name}>
              <code>{field.name}</code>
              <div>
                <p>{field.label}</p>
                <small>{field.helperText || "No extra guidance."}</small>
              </div>
              <span className={field.required ? "badge req" : "badge opt"}>{field.required ? "required" : "optional"}</span>
            </div>
          ))}
        </div>
      </div>
    </aside>
  );
}

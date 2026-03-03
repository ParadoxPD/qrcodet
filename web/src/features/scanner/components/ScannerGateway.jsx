import { Suspense, lazy, useState } from "react";

const ScannerPanel = lazy(() => import("./ScannerPanel"));

export default function ScannerGateway() {
  const [enabled, setEnabled] = useState(false);

  if (!enabled) {
    return (
      <div className="panel scanner-intro-panel">
        <p className="eyebrow">Scanner</p>
        <h3 className="scanner-intro-title">Load realtime scanning only when needed.</h3>
        <p className="muted-line">Camera scanning and image decoding are split into a separate bundle so the generator loads faster.</p>
        <div className="action-row">
          <button className="solid" type="button" onClick={() => setEnabled(true)}>
            Open Scanner
          </button>
        </div>
      </div>
    );
  }

  return (
    <Suspense
      fallback={
        <div className="panel scanner-intro-panel">
          <p className="eyebrow">Scanner</p>
          <h3 className="scanner-intro-title">Loading scanner tools...</h3>
        </div>
      }
    >
      <ScannerPanel />
    </Suspense>
  );
}

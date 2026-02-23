import PatternIcon from "./PatternIcon";

const GROUP_TITLES = {
  qr: "QR Use Cases",
  barcode: "Barcode Use Cases",
};

const fieldInput = (field, value, onChange) => {
  if (field.type === "select") {
    return (
      <select className="input" value={value ?? field.options?.[0] ?? ""} onChange={(event) => onChange(field.name, event.target.value)}>
        {(field.options || []).map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    );
  }
  if (field.type === "checkbox") {
    return (
      <span className="checkbox-wrap">
        <input className="themed-checkbox" type="checkbox" checked={Boolean(value)} onChange={(event) => onChange(field.name, event.target.checked)} />
      </span>
    );
  }
  return (
    <input
      className="input"
      type={field.type || "text"}
      value={value ?? ""}
      placeholder={field.placeholder || ""}
      onChange={(event) => onChange(field.name, event.target.value)}
    />
  );
};

export default function GeneratorControls({
  mode,
  setMode,
  useCases,
  selectedUseCaseId,
  setSelectedUseCaseId,
  values,
  setValue,
  appearance,
  setAppearance,
  themes,
  qrStyles,
  qrCornerStyles,
  frames,
  selectedUseCase,
  validationByField,
  logoPreview,
  onLogoChange,
  onClearLogo,
  presets,
  presetName,
  setPresetName,
  onSavePreset,
  onLoadPreset,
  onDeletePreset,
}) {
  const lightThemes = themes.filter((theme) => theme.mood === "light");
  const darkThemes = themes.filter((theme) => theme.mood === "dark");

  return (
    <section className="control-stack">
      <div className="panel">
        <div className="tab-row">
          <button className={mode === "qr" ? "tab active" : "tab"} onClick={() => setMode("qr")}>
            QR Codes
          </button>
          <button className={mode === "barcode" ? "tab active" : "tab"} onClick={() => setMode("barcode")}>
            Barcodes
          </button>
        </div>
      </div>

      <div className="panel">
        <p className="eyebrow">{GROUP_TITLES[mode]}</p>
        <div className="cards-grid">
          {useCases.map((useCase) => (
            <button
              key={useCase.id}
              className={selectedUseCaseId === useCase.id ? "choice-card active" : "choice-card"}
              onClick={() => setSelectedUseCaseId(useCase.id)}
            >
              <strong>{useCase.label}</strong>
              <span>{useCase.description}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="panel">
        <p className="eyebrow">Data Fields</p>
        <div className="field-grid">
          {selectedUseCase?.fields.map((field) => (
            <label key={field.name} className={field.type === "checkbox" ? "field checkbox-field" : "field"}>
              <span>
                {field.label}
                {field.required ? <em className="required-mark">*</em> : ""}
              </span>
              {fieldInput(field, values[field.name], setValue)}
              {field.helperText ? <small className="field-help">{field.helperText}</small> : null}
              {validationByField[field.name] ? <small className="field-error">{validationByField[field.name]}</small> : null}
            </label>
          ))}
        </div>
      </div>

      <div className="panel">
        <p className="eyebrow">Appearance System</p>
        <div className="field-grid">
          <label className="field">
            <span>Header</span>
            <input className="input" value={appearance.header} onChange={(event) => setAppearance("header", event.target.value)} />
          </label>
          <label className="field">
            <span>Footer</span>
            <input className="input" value={appearance.footer} onChange={(event) => setAppearance("footer", event.target.value)} />
          </label>
        </div>

        <p className="eyebrow compact">Themes</p>
        <p className="theme-group-title">Light</p>
        <div className="swatch-row">
          {lightThemes.map((theme) => (
            <button
              key={theme.id}
              className={appearance.themeId === theme.id ? "swatch active" : "swatch"}
              onClick={() => setAppearance("themeId", theme.id)}
              title={theme.label}
            >
              <span style={{ background: `linear-gradient(125deg, ${theme.dark} 0%, ${theme.accent} 50%, ${theme.light} 100%)` }} />
            </button>
          ))}
        </div>
        <p className="theme-group-title">Dark</p>
        <div className="swatch-row">
          {darkThemes.map((theme) => (
            <button
              key={theme.id}
              className={appearance.themeId === theme.id ? "swatch active" : "swatch"}
              onClick={() => setAppearance("themeId", theme.id)}
              title={theme.label}
            >
              <span style={{ background: `linear-gradient(125deg, ${theme.dark} 0%, ${theme.accent} 50%, ${theme.light} 100%)` }} />
            </button>
          ))}
        </div>

        {mode === "qr" && (
          <>
            <p className="eyebrow compact">Error Correction</p>
            <div className="frame-row">
              {["L", "M", "Q", "H"].map((level) => (
                <button
                  key={level}
                  className={appearance.errorLevel === level ? "pill active" : "pill"}
                  onClick={() => setAppearance("errorLevel", level)}
                  title={`Error correction level ${level}`}
                >
                  {level}
                </button>
              ))}
            </div>

            <p className="eyebrow compact">QR Dot Style</p>
            <div className="pattern-row">
              {qrStyles.map((style) => (
                <button
                  key={style.id}
                  className={appearance.qrStyle === style.id ? "pattern active" : "pattern"}
                  onClick={() => setAppearance("qrStyle", style.id)}
                  title={style.label}
                >
                  <PatternIcon id={style.id} active={appearance.qrStyle === style.id} />
                </button>
              ))}
            </div>

            <p className="eyebrow compact">Corner Box Style</p>
            <div className="frame-row">
              {qrCornerStyles.map((style) => (
                <button
                  key={style.id}
                  className={appearance.cornerStyle === style.id ? "pill active" : "pill"}
                  onClick={() => setAppearance("cornerStyle", style.id)}
                >
                  {style.label}
                </button>
              ))}
            </div>

            <p className="eyebrow compact">Frame</p>
            <div className="frame-row">
              {frames.map((frame) => (
                <button key={frame.id} className={appearance.frameId === frame.id ? "pill active" : "pill"} onClick={() => setAppearance("frameId", frame.id)}>
                  {frame.label}
                </button>
              ))}
            </div>

            <p className="eyebrow compact">Center Logo</p>
            <div className="logo-row">
              <label className="upload-btn">
                <input type="file" accept="image/*" onChange={onLogoChange} />
                <span>Choose Logo</span>
              </label>
              {logoPreview ? (
                <>
                  <img src={logoPreview} alt="logo preview" />
                  <button className="pill" onClick={onClearLogo}>
                    Clear
                  </button>
                </>
              ) : null}
            </div>
          </>
        )}
      </div>

      <div className="panel">
        <p className="eyebrow">Preset Library</p>
        <div className="preset-row">
          <input className="input" value={presetName} placeholder="Preset name" onChange={(event) => setPresetName(event.target.value)} />
          <button className="solid preset-save" onClick={onSavePreset}>
            Save Preset
          </button>
        </div>
        <div className="preset-list">
          {presets.length === 0 ? (
            <p className="muted-line">No saved presets yet.</p>
          ) : (
            presets.map((preset) => (
              <div className="preset-item" key={preset.id}>
                <div>
                  <strong>{preset.name}</strong>
                  <span>{preset.mode.toUpperCase()} / {preset.useCaseId}</span>
                </div>
                <div>
                  <button className="ghost" onClick={() => onLoadPreset(preset.id)}>
                    Load
                  </button>
                  <button className="ghost" onClick={() => onDeletePreset(preset.id)}>
                    Delete
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </section>
  );
}

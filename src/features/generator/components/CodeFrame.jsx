export default function CodeFrame({ frameId, theme, header, footer, children, metaLine }) {
  if (frameId === "none") {
    return children;
  }

  if (frameId === "minimal") {
    return (
      <div className="frame minimal" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark }}>
        {header ? <p>{header}</p> : null}
        {children}
        {footer ? <small>{footer}</small> : null}
      </div>
    );
  }

  if (frameId === "card") {
    return (
      <div className="frame card" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
        <div className="ornament" />
        {header ? <p>{header}</p> : null}
        {children}
        {metaLine ? <strong>{metaLine}</strong> : null}
        {footer ? <small>{footer}</small> : null}
      </div>
    );
  }

  if (frameId === "ticket") {
    return (
      <div className="frame ticket" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
        <header>{header || "Scan"}</header>
        <div className="ticket-cut">{children}</div>
        <footer>{footer || "Verified payload"}</footer>
      </div>
    );
  }

  if (frameId === "badge") {
    return (
      <div className="frame badge" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
        <div className="badge-chip">{header || "Scan"}</div>
        <div className="badge-core">{children}</div>
        {metaLine ? <strong>{metaLine}</strong> : null}
        {footer ? <small>{footer}</small> : null}
      </div>
    );
  }

  if (frameId === "poster") {
    return (
      <div className="frame poster" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
        <header>
          <h3>{header || "Scan to Continue"}</h3>
          <p>{footer || "Trusted code"}</p>
        </header>
        <div className="poster-body">{children}</div>
      </div>
    );
  }

  if (frameId === "strip") {
    return (
      <div className="frame strip" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
        <div className="strip-side">
          <span>{header || "SCAN"}</span>
        </div>
        <div className="strip-main">
          {children}
          {footer ? <small>{footer}</small> : null}
        </div>
      </div>
    );
  }

  if (frameId === "ornate") {
    return (
      <div className="frame ornate" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
        <div className="ornate-cap">
          <span />
          <h4>{header || "Elegant Scan"}</h4>
          <span />
        </div>
        {children}
        {footer ? <small>{footer}</small> : null}
      </div>
    );
  }

  return (
    <div className="frame scan" style={{ "--frame-bg": theme.light, "--frame-fg": theme.dark, "--frame-accent": theme.accent }}>
      <header>{header || "Scan Code"}</header>
      <div className="scan-body">{children}</div>
      {footer ? <footer>{footer}</footer> : null}
    </div>
  );
}

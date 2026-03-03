export default function CollapsiblePanel({
  title,
  eyebrow,
  collapsed,
  onToggle,
  children,
  className = "",
  action = null,
  collapsible = true,
}) {
  if (!collapsible) {
    return (
      <div className={`panel ${className}`.trim()}>
        <div className="panel-static-head">
          <span>
            {eyebrow ? <small className="panel-toggle-eyebrow">{eyebrow}</small> : null}
            <strong>{title}</strong>
          </span>
        </div>
        {action ? <div className="panel-toggle-action">{action}</div> : null}
        <div className="panel-toggle-body">{children}</div>
      </div>
    );
  }

  return (
    <div className={`panel ${className}`.trim()}>
      <button className="panel-toggle" type="button" onClick={onToggle} aria-expanded={!collapsed}>
        <span>
          {eyebrow ? <small className="panel-toggle-eyebrow">{eyebrow}</small> : null}
          <strong>{title}</strong>
        </span>
        <span className={collapsed ? "panel-toggle-icon" : "panel-toggle-icon open"}>{collapsed ? "+" : "-"}</span>
      </button>
      {action ? <div className="panel-toggle-action">{action}</div> : null}
      {!collapsed ? <div className="panel-toggle-body">{children}</div> : null}
    </div>
  );
}

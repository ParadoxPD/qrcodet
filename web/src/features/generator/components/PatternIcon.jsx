export default function PatternIcon({ id, active }) {
  const fill = active ? "var(--c-accent)" : "var(--c-muted)";
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden="true">
      {id === "square" && (
        <>
          <rect x="2" y="2" width="8" height="8" fill={fill} />
          <rect x="14" y="2" width="8" height="8" fill={fill} />
          <rect x="2" y="14" width="8" height="8" fill={fill} />
          <rect x="14" y="14" width="3" height="3" fill={fill} />
          <rect x="19" y="14" width="3" height="3" fill={fill} />
          <rect x="14" y="19" width="3" height="3" fill={fill} />
        </>
      )}
      {id === "rounded" && (
        <>
          <rect x="2" y="2" width="8" height="8" rx="2.5" fill={fill} />
          <rect x="14" y="2" width="8" height="8" rx="2.5" fill={fill} />
          <rect x="2" y="14" width="8" height="8" rx="2.5" fill={fill} />
          <circle cx="15.5" cy="15.5" r="1.6" fill={fill} />
          <circle cx="20.5" cy="15.5" r="1.6" fill={fill} />
          <circle cx="15.5" cy="20.5" r="1.6" fill={fill} />
        </>
      )}
      {id === "dot" && (
        <>
          <circle cx="6" cy="6" r="4" fill={fill} />
          <circle cx="18" cy="6" r="4" fill={fill} />
          <circle cx="6" cy="18" r="4" fill={fill} />
          <circle cx="15.5" cy="15.5" r="1.8" fill={fill} />
          <circle cx="20.5" cy="15.5" r="1.8" fill={fill} />
          <circle cx="15.5" cy="20.5" r="1.8" fill={fill} />
        </>
      )}
      {id === "diamond" && (
        <>
          <polygon points="6,1.5 10.5,6 6,10.5 1.5,6" fill={fill} />
          <polygon points="18,1.5 22.5,6 18,10.5 13.5,6" fill={fill} />
          <polygon points="6,13.5 10.5,18 6,22.5 1.5,18" fill={fill} />
          <polygon points="15.5,13.8 17.8,16 15.5,18.2 13.2,16" fill={fill} />
          <polygon points="20.5,13.8 22.8,16 20.5,18.2 18.2,16" fill={fill} />
          <polygon points="15.5,18.8 17.8,21 15.5,23.2 13.2,21" fill={fill} />
        </>
      )}
      {id === "squircle" && (
        <>
          <rect x="2" y="2" width="8" height="8" rx="3.7" fill={fill} />
          <rect x="14" y="2" width="8" height="8" rx="3.7" fill={fill} />
          <rect x="2" y="14" width="8" height="8" rx="3.7" fill={fill} />
          <rect x="14" y="14" width="3.2" height="3.2" rx="1.5" fill={fill} />
          <rect x="19" y="14" width="3.2" height="3.2" rx="1.5" fill={fill} />
          <rect x="14" y="19" width="3.2" height="3.2" rx="1.5" fill={fill} />
        </>
      )}
      {id === "kite" && (
        <>
          <polygon points="6,1.5 10.5,6 6,10.5 1.5,6" fill={fill} />
          <polygon points="18,1.5 22.5,6 18,10.5 13.5,6" fill={fill} />
          <polygon points="6,13.5 10.5,18 6,22.5 1.5,18" fill={fill} />
          <polygon points="15.5,13.8 18,16 15.5,18.2 13,16" fill={fill} />
          <polygon points="20.5,13.8 23,16 20.5,18.2 18,16" fill={fill} />
          <polygon points="15.5,18.8 18,21 15.5,23.2 13,21" fill={fill} />
        </>
      )}
      {id === "plus" && (
        <>
          <path d="M4.8,1.6h2.4v2.4h2.4v2.4H7.2v2.4H4.8V6.4H2.4V4h2.4z" fill={fill} />
          <path d="M16.8,1.6h2.4v2.4h2.4v2.4h-2.4v2.4h-2.4V6.4h-2.4V4h2.4z" fill={fill} />
          <path d="M4.8,13.6h2.4v2.4h2.4v2.4H7.2v2.4H4.8v-2.4H2.4V16h2.4z" fill={fill} />
          <rect x="14" y="14" width="3.2" height="3.2" fill={fill} />
          <rect x="19" y="14" width="3.2" height="3.2" fill={fill} />
          <rect x="14" y="19" width="3.2" height="3.2" fill={fill} />
        </>
      )}
      {id === "star" && (
        <>
          <polygon points="6,1 7.4,4.5 11,4.5 8.1,6.8 9.1,10.5 6,8.5 2.9,10.5 3.9,6.8 1,4.5 4.6,4.5" fill={fill} />
          <polygon points="18,1 19.4,4.5 23,4.5 20.1,6.8 21.1,10.5 18,8.5 14.9,10.5 15.9,6.8 13,4.5 16.6,4.5" fill={fill} />
          <polygon points="6,13 7.4,16.5 11,16.5 8.1,18.8 9.1,22.5 6,20.5 2.9,22.5 3.9,18.8 1,16.5 4.6,16.5" fill={fill} />
          <rect x="14" y="14" width="3.2" height="3.2" fill={fill} />
          <rect x="19" y="14" width="3.2" height="3.2" fill={fill} />
          <rect x="14" y="19" width="3.2" height="3.2" fill={fill} />
        </>
      )}
      {id === "cross" && (
        <>
          <path d="M4.5,1h3v3h3v3h-3v3h-3v-3h-3V4h3z" fill={fill} />
          <path d="M16.5,1h3v3h3v3h-3v3h-3v-3h-3V4h3z" fill={fill} />
          <path d="M4.5,13h3v3h3v3h-3v3h-3v-3h-3v-3h3z" fill={fill} />
          <rect x="14" y="14" width="3.2" height="3.2" fill={fill} />
          <rect x="19" y="14" width="3.2" height="3.2" fill={fill} />
          <rect x="14" y="19" width="3.2" height="3.2" fill={fill} />
        </>
      )}
      {id === "bars_v" && (
        <>
          <rect x="2" y="2" width="2.8" height="8" fill={fill} />
          <rect x="6.3" y="2" width="2.8" height="8" fill={fill} />
          <rect x="14" y="2" width="2.8" height="8" fill={fill} />
          <rect x="18.2" y="2" width="2.8" height="8" fill={fill} />
          <rect x="2" y="14" width="2.8" height="8" fill={fill} />
          <rect x="6.3" y="14" width="2.8" height="8" fill={fill} />
          <rect x="14" y="14" width="1.4" height="4" fill={fill} />
          <rect x="16.7" y="14" width="1.4" height="4" fill={fill} />
          <rect x="19.4" y="14" width="1.4" height="4" fill={fill} />
        </>
      )}
    </svg>
  );
}

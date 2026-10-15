import React from "react";
import {
  AbsoluteFill,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { C, FONT } from "./theme";

export const clamp = {
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
} as const;

/** 0→1 arası yumuşak geçiş; `start` karesinde başlar. */
export const useSpring = (start: number, damping = 200, mass = 1) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - start, fps, config: { damping, mass } });
};

export const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 110) * 60;
  return (
    <AbsoluteFill
      style={{
        background: `linear-gradient(180deg, ${C.inkTop} 0%, ${C.inkBottom} 100%)`,
      }}
    >
      <div
        style={{
          position: "absolute",
          width: 1400,
          height: 1400,
          left: -420 + drift,
          top: -760,
          borderRadius: "50%",
          background:
            "radial-gradient(circle, rgba(232,163,61,0.16) 0%, rgba(232,163,61,0) 62%)",
        }}
      />
      <div
        style={{
          position: "absolute",
          width: 1500,
          height: 1500,
          right: -520 - drift,
          bottom: -900,
          borderRadius: "50%",
          background:
            "radial-gradient(circle, rgba(92,120,255,0.20) 0%, rgba(92,120,255,0) 62%)",
        }}
      />
    </AbsoluteFill>
  );
};

/** Sahneyi baştan ve sondan karartarak açıp kapatır. */
export const SceneFade: React.FC<{
  duration: number;
  fadeIn?: number;
  fadeOut?: number;
  children: React.ReactNode;
}> = ({ duration, fadeIn = 12, fadeOut = 12, children }) => {
  const frame = useCurrentFrame();
  const opacity = Math.min(
    fadeIn === 0 ? 1 : interpolate(frame, [0, fadeIn], [0, 1], clamp),
    fadeOut === 0
      ? 1
      : interpolate(frame, [duration - fadeOut, duration - 1], [1, 0], clamp),
  );
  return <AbsoluteFill style={{ opacity }}>{children}</AbsoluteFill>;
};

/** Markanın kahramanı: elle çizilmiş, yuvarlak uçlu düzeltme işareti. */
export const Circumflex: React.FC<{
  width: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({ width, color = C.amber, style }) => (
  <svg
    width={width}
    height={width * 0.46}
    viewBox="0 0 100 46"
    style={{ overflow: "visible", ...style }}
  >
    <polyline
      points="9,38 50,9 91,38"
      fill="none"
      stroke={color}
      strokeWidth={14}
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

/**
 * "Kamus" → "Kâmus": şapka yukarıdan düşüp "a"nın üzerine oturur.
 * `hat` 0 iken şapka görünmez, 1 iken yerindedir (yay ile 1'i aşabilir).
 */
export const Wordmark: React.FC<{ size: number; hat: number }> = ({
  size,
  hat,
}) => (
  <div
    style={{
      fontFamily: FONT.serif,
      fontWeight: 700,
      fontSize: size,
      lineHeight: 1,
      letterSpacing: -size * 0.02,
      color: C.cream,
      display: "flex",
    }}
  >
    <span>K</span>
    <span style={{ position: "relative", display: "inline-block" }}>
      a
      <Circumflex
        width={size * 0.4}
        style={{
          position: "absolute",
          left: "50%",
          top: size * 0.125,
          marginLeft: -size * 0.2 - size * 0.012,
          opacity: interpolate(hat, [0, 0.35], [0, 1], clamp),
          transform: `translateY(${(1 - hat) * -size * 0.9}px)`,
        }}
      />
    </span>
    <span>mus</span>
  </div>
);

export const AppIcon: React.FC<{ size: number; style?: React.CSSProperties }> = ({
  size,
  style,
}) => (
  <Img
    src={staticFile("icon.png")}
    style={{
      width: size,
      height: size,
      filter: "drop-shadow(0 30px 50px rgba(0,0,0,0.45))",
      ...style,
    }}
  />
);

export const Keycap: React.FC<{
  label: string;
  size?: number;
  pressed?: number;
  wide?: boolean;
}> = ({ label, size = 120, pressed = 0, wide = false }) => {
  const depth = size * 0.075;
  return (
    <div
      style={{
        width: wide ? size * 2.3 : size,
        height: size,
        borderRadius: size * 0.2,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontFamily: FONT.sans,
        fontWeight: 500,
        fontSize: wide ? size * 0.3 : size * 0.46,
        color: C.cream,
        background: `linear-gradient(180deg, #34427C 0%, #222C5C 100%)`,
        border: `1.5px solid rgba(255,255,255,${0.16 + pressed * 0.3})`,
        boxShadow: [
          `0 ${depth * (1 - pressed)}px 0 ${C.inkDeep}`,
          `0 ${depth * 2.4 * (1 - pressed)}px ${depth * 3}px rgba(0,0,0,0.4)`,
          `0 0 ${pressed * size * 0.5}px rgba(232,163,61,${pressed * 0.55})`,
          `inset 0 1.5px 0 rgba(255,255,255,0.14)`,
        ].join(", "),
        transform: `translateY(${depth * pressed}px)`,
      }}
    >
      {label}
    </div>
  );
};

export const Eyebrow: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div
    style={{
      fontFamily: FONT.sans,
      fontWeight: 600,
      fontSize: 24,
      letterSpacing: 5,
      color: C.amber,
    }}
  >
    {children}
  </div>
);

/* ---------- SF Symbols yerine basit SVG ikonlar ---------- */

type IconProps = { size: number; color?: string; style?: React.CSSProperties };

const Svg: React.FC<IconProps & { children: React.ReactNode }> = ({
  size,
  style,
  children,
}) => (
  <svg width={size} height={size} viewBox="0 0 24 24" style={style}>
    {children}
  </svg>
);

export const MagnifierIcon: React.FC<IconProps> = ({ color = "#8A8A8E", ...p }) => (
  <Svg {...p}>
    <circle cx="10.5" cy="10.5" r="6.2" fill="none" stroke={color} strokeWidth="2.2" />
    <line x1="15.2" y1="15.2" x2="20.5" y2="20.5" stroke={color} strokeWidth="2.4" strokeLinecap="round" />
  </Svg>
);

export const BookIcon: React.FC<IconProps> = ({ color = "#fff", ...p }) => (
  <Svg {...p}>
    <path
      d="M1.5 5.2C5.5 3.6 9 4 11.2 5.8V20c-2.2-1.6-5.7-2-9.7-0.6Z M22.5 5.2C18.5 3.6 15 4 12.8 5.8V20c2.2-1.6 5.7-2 9.7-0.6Z"
      fill={color}
    />
  </Svg>
);

export const XMarkIcon: React.FC<IconProps> = ({ color = "#8A8A8E", ...p }) => (
  <Svg {...p}>
    <path d="M6 6L18 18M18 6L6 18" stroke={color} strokeWidth="2.4" strokeLinecap="round" />
  </Svg>
);

export const GearIcon: React.FC<IconProps> = ({ color = "#8A8A8E", ...p }) => (
  <Svg {...p}>
    {Array.from({ length: 8 }).map((_, i) => (
      <rect
        key={i}
        x="10.4"
        y="1.6"
        width="3.2"
        height="5"
        rx="1"
        fill={color}
        transform={`rotate(${i * 45} 12 12)`}
      />
    ))}
    <circle cx="12" cy="12" r="5.6" fill="none" stroke={color} strokeWidth="3" />
  </Svg>
);

export const WifiIcon: React.FC<IconProps & { slash?: number; slashColor?: string }> = ({
  color = "#fff",
  slash = 0,
  slashColor = C.amber,
  ...p
}) => (
  <Svg {...p}>
    <g fill="none" stroke={color} strokeWidth="2.2" strokeLinecap="round" opacity={1 - slash * 0.55}>
      <path d="M2.5 9.5C8 4.2 16 4.2 21.5 9.5" />
      <path d="M6 13.2C9.5 9.9 14.5 9.9 18 13.2" />
      <path d="M9.6 16.8C11 15.5 13 15.5 14.4 16.8" />
    </g>
    <circle cx="12" cy="20" r="1.5" fill={color} opacity={1 - slash * 0.55} />
    {slash > 0 ? (
      <line
        x1="4"
        y1="3"
        x2={4 + 16 * slash}
        y2={3 + 19 * slash}
        stroke={slashColor}
        strokeWidth="2.6"
        strokeLinecap="round"
      />
    ) : null}
  </Svg>
);

export const KeyIcon: React.FC<IconProps> = ({ color = "#fff", ...p }) => (
  <Svg {...p}>
    <g fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="8" cy="15.5" r="4.5" />
      <path d="M11.3 12.3L20 3.6M16.4 7.2l3 3M13.6 10l2.4 2.4" />
    </g>
  </Svg>
);

export const CheckIcon: React.FC<IconProps> = ({ color = C.amber, ...p }) => (
  <Svg {...p}>
    <path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke={color} strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" />
  </Svg>
);

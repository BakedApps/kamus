import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { CheckIcon, Keycap, KeyIcon, clamp, useSpring } from "../components";
import { C, FONT } from "../theme";

const Card: React.FC<{
  at: number;
  title: string;
  body: string;
  children: React.ReactNode;
}> = ({ at, title, body, children }) => {
  const s = useSpring(at, 18);
  return (
    <div
      style={{
        width: 520,
        height: 510,
        borderRadius: 32,
        background: C.glass,
        border: `1.5px solid ${C.glassBorder}`,
        padding: 44,
        display: "flex",
        flexDirection: "column",
        opacity: Math.min(1, s * 1.4),
        transform: `translateY(${(1 - s) * 70}px)`,
      }}
    >
      <div style={{ height: 230, display: "flex", alignItems: "center", justifyContent: "center" }}>
        {children}
      </div>
      <div style={{ fontFamily: FONT.serif, fontWeight: 700, fontSize: 46, color: C.cream }}>
        {title}
      </div>
      <div
        style={{
          marginTop: 16,
          fontFamily: FONT.sans,
          fontSize: 28,
          lineHeight: 1.42,
          color: C.creamDim,
        }}
      >
        {body}
      </div>
    </div>
  );
};

const ShortcutVisual: React.FC = () => {
  const frame = useCurrentFrame();
  // Varsayılan kısayol, kullanıcının atadığı bir başkasına dönüşür.
  const swap = interpolate(frame, [72, 84], [0, 1], clamp);
  const row: React.CSSProperties = { position: "absolute", display: "flex", gap: 14 };
  return (
    <div style={{ position: "relative", width: "100%", height: 100, display: "flex", justifyContent: "center" }}>
      <div style={{ ...row, opacity: 1 - swap, transform: `translateY(${swap * -24}px)` }}>
        {["⌃", "⌘", "L"].map((k) => (
          <Keycap key={k} label={k} size={96} />
        ))}
      </div>
      <div style={{ ...row, opacity: swap, transform: `translateY(${(1 - swap) * 24}px)` }}>
        <Keycap label="⌥" size={96} />
        <Keycap label="Space" size={96} wide />
      </div>
    </div>
  );
};

const TurkishVisual: React.FC = () => {
  const frame = useCurrentFrame();
  const arrow = interpolate(frame, [40, 54], [0, 1], clamp);
  const strike = interpolate(frame, [62, 74], [0, 1], clamp);
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 18,
          fontFamily: FONT.serif,
          fontWeight: 700,
          fontSize: 62,
          color: C.cream,
        }}
      >
        <span>IŞIK</span>
        <span style={{ color: C.amber, opacity: arrow, fontFamily: FONT.sans, fontWeight: 400 }}>→</span>
        <span style={{ opacity: arrow, transform: `translateX(${(1 - arrow) * -16}px)` }}>ışık</span>
        <CheckIcon size={42} style={{ opacity: arrow }} />
      </div>
      <div
        style={{
          position: "relative",
          fontFamily: FONT.serif,
          fontSize: 40,
          color: C.creamFaint,
          opacity: strike,
        }}
      >
        işik
        <div
          style={{
            position: "absolute",
            left: -8,
            top: "56%",
            height: 3,
            width: `calc(${strike * 100}% + ${strike * 16}px)`,
            background: "#E5636B",
            borderRadius: 2,
          }}
        />
      </div>
    </div>
  );
};

const NoKeyVisual: React.FC = () => {
  const frame = useCurrentFrame();
  const slash = interpolate(frame, [58, 72], [0, 1], clamp);
  return (
    <div style={{ position: "relative", width: 170, height: 170 }}>
      <KeyIcon size={170} color={C.cream} style={{ opacity: 1 - slash * 0.5 }} />
      <svg width={170} height={170} viewBox="0 0 170 170" style={{ position: "absolute", inset: 0 }}>
        <line
          x1={20}
          y1={20}
          x2={20 + 130 * slash}
          y2={20 + 130 * slash}
          stroke={C.amber}
          strokeWidth={13}
          strokeLinecap="round"
          opacity={slash > 0 ? 1 : 0}
        />
      </svg>
    </div>
  );
};

export const Features: React.FC = () => {
  const head = useSpring(2);
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <div
        style={{
          fontFamily: FONT.serif,
          fontStyle: "italic",
          fontSize: 60,
          color: C.cream,
          marginBottom: 56,
          opacity: head,
          transform: `translateY(${(1 - head) * 20}px)`,
        }}
      >
        Küçük ama düşünülmüş.
      </div>
      <div style={{ display: "flex", gap: 40 }}>
        <Card at={10} title="Kısayol senin" body="⌃⌘L ile gelir; ayarlardan istediğin kombinasyonu ata.">
          <ShortcutVisual />
        </Card>
        <Card at={20} title="Türkçeyi bilir" body="Harf dönüşümü tr_TR kurallarıyla; “Işık” ile “ışık” aynı kayıt.">
          <TurkishVisual />
        </Card>
        <Card at={30} title="API anahtarı yok" body="Hesap açma, anahtar alma yok. Derle, aç, kullan.">
          <NoKeyVisual />
        </Card>
      </div>
    </AbsoluteFill>
  );
};

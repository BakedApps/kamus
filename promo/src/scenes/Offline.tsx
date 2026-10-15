import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { CheckIcon, Eyebrow, WifiIcon, clamp, useSpring } from "../components";
import { C, FONT } from "../theme";

const WORDS: [string, number][] = [
  ["müstesna", 4],
  ["rüzgâr", 2],
  ["sükûnet", 3],
  ["teveccüh", 1],
  ["ışık", 5],
  ["mütevazı", 2],
  ["hülya", 1],
];

const ROW_START = 18;
const ROW_STEP = 9;
const OFFLINE_AT = 104;

const Row: React.FC<{ word: string; count: number; index: number }> = ({
  word,
  count,
  index,
}) => {
  const frame = useCurrentFrame();
  const s = useSpring(ROW_START + index * ROW_STEP, 20);
  // Çevrimdışına geçince ilk satır "yerelden açıldı" diye vurgulanır.
  const hit = index === 0 ? interpolate(frame, [OFFLINE_AT + 22, OFFLINE_AT + 34], [0, 1], clamp) : 0;
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 20,
        padding: "0 28px",
        height: 74,
        borderRadius: 16,
        background: `rgba(232,163,61,${hit * 0.16})`,
        border: `1.5px solid rgba(232,163,61,${hit * 0.7})`,
        opacity: s,
        transform: `translateX(${(1 - s) * 90}px)`,
      }}
    >
      <CheckIcon size={30} />
      <span style={{ flex: 1, fontFamily: FONT.serif, fontSize: 38, color: C.cream }}>{word}</span>
      <span style={{ fontFamily: FONT.mono, fontSize: 22, color: hit > 0.5 ? C.amber : C.creamFaint }}>
        {hit > 0.5 ? "yerelden açıldı" : `${count} arama`}
      </span>
    </div>
  );
};

export const Offline: React.FC = () => {
  const frame = useCurrentFrame();
  const textIn = useSpring(4);
  const panelIn = useSpring(8);
  const slash = interpolate(frame, [OFFLINE_AT, OFFLINE_AT + 12], [0, 1], clamp);
  const pill = useSpring(OFFLINE_AT + 8, 14);
  const saved = Math.min(
    WORDS.length,
    Math.max(0, Math.floor((frame - ROW_START) / ROW_STEP) + 1),
  );

  return (
    <AbsoluteFill style={{ flexDirection: "row", alignItems: "center", padding: "0 130px", gap: 100 }}>
      <div style={{ flex: 1, opacity: textIn, transform: `translateY(${(1 - textIn) * 30}px)` }}>
        <Eyebrow>YEREL VERİTABANI</Eyebrow>
        <div
          style={{
            marginTop: 26,
            fontFamily: FONT.serif,
            fontWeight: 700,
            fontSize: 84,
            lineHeight: 1.12,
            color: C.cream,
          }}
        >
          Aradıkça büyüyen
          <br />
          kendi sözlüğün.
        </div>
        <div
          style={{
            marginTop: 34,
            fontFamily: FONT.sans,
            fontSize: 34,
            lineHeight: 1.45,
            color: C.creamDim,
            maxWidth: 720,
          }}
        >
          Her başarılı arama SQLite'a kaydedilir. Kayıtlı kelimeler anında açılır
          — internet olmadan da.
        </div>
        <div
          style={{
            marginTop: 44,
            display: "inline-flex",
            alignItems: "center",
            gap: 16,
            padding: "16px 30px",
            borderRadius: 999,
            background: C.amber,
            color: C.inkBottom,
            fontFamily: FONT.sans,
            fontWeight: 700,
            fontSize: 30,
            transform: `scale(${pill})`,
            transformOrigin: "left center",
            opacity: Math.min(1, pill * 1.5),
          }}
        >
          <WifiIcon size={34} color={C.inkBottom} slash={1} slashColor={C.inkBottom} />
          Çevrimdışı çalışır
        </div>
      </div>

      <div
        style={{
          width: 760,
          borderRadius: 30,
          background: C.glass,
          border: `1.5px solid ${C.glassBorder}`,
          boxShadow: "0 40px 90px rgba(0,0,0,0.35)",
          padding: 26,
          opacity: panelIn,
          transform: `translateY(${(1 - panelIn) * 40}px)`,
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            padding: "6px 28px 22px",
            fontFamily: FONT.mono,
            fontSize: 24,
            color: C.creamDim,
          }}
        >
          <span style={{ flex: 1 }}>dictionary.sqlite</span>
          <span style={{ marginRight: 24, color: C.creamFaint }}>{saved} kelime</span>
          <WifiIcon size={34} color={C.cream} slash={slash} />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {WORDS.map(([w, c], i) => (
            <Row key={w} word={w} count={c} index={i} />
          ))}
        </div>
      </div>
    </AbsoluteFill>
  );
};

import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import {
  BookIcon,
  GearIcon,
  Keycap,
  MagnifierIcon,
  WifiIcon,
  XMarkIcon,
  clamp,
  useSpring,
} from "../components";
import { C, FONT } from "../theme";

// Sahne içi zaman çizelgesi (kare)
const T = {
  selectStart: 48,
  selectEnd: 74,
  keysIn: 96,
  press: 138,
  release: 172,
  popover: 166,
  resultsAt: 200,
};

// Popover'ın ve menü çubuğu simgesinin yatay merkezi
const POPOVER_X = 1500;
const POPOVER_SCALE = 1.6;

const Caption: React.FC<{ from: number; to: number; children: React.ReactNode }> = ({
  from,
  to,
  children,
}) => {
  const frame = useCurrentFrame();
  const o = Math.min(
    interpolate(frame, [from, from + 12], [0, 1], clamp),
    interpolate(frame, [to - 12, to], [1, 0], clamp),
  );
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 64,
        textAlign: "center",
        fontFamily: FONT.serif,
        fontSize: 54,
        color: C.cream,
        opacity: o,
        transform: `translateY(${(1 - o) * 14}px)`,
      }}
    >
      {children}
    </div>
  );
};

const MenuBar: React.FC<{ active: number }> = ({ active }) => (
  <div
    style={{
      position: "absolute",
      top: 0,
      left: 0,
      right: 0,
      height: 46,
      background: "rgba(255,255,255,0.10)",
      borderBottom: "1px solid rgba(255,255,255,0.08)",
      fontFamily: FONT.sans,
      fontSize: 22,
      color: "rgba(255,255,255,0.92)",
      display: "flex",
      alignItems: "center",
      paddingLeft: 30,
      gap: 34,
    }}
  >
    <span style={{ fontWeight: 700 }}>Notlar</span>
    <span>Dosya</span>
    <span>Düzen</span>
    <span>Biçim</span>
    <span>Görünüm</span>
    <div
      style={{
        position: "absolute",
        left: POPOVER_X - 27,
        top: 5,
        width: 54,
        height: 36,
        borderRadius: 8,
        background: `rgba(255,255,255,${active * 0.24})`,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <BookIcon size={28} />
    </div>
    <div style={{ position: "absolute", right: 30, display: "flex", alignItems: "center", gap: 26 }}>
      <WifiIcon size={26} />
      <span>Cum 09:41</span>
    </div>
  </div>
);

const DocWindow: React.FC = () => {
  const frame = useCurrentFrame();
  const sel = interpolate(frame, [T.selectStart, T.selectEnd], [0, 1], clamp);
  return (
    <div
      style={{
        width: 980,
        height: 500,
        borderRadius: 18,
        overflow: "hidden",
        background: "#FBF8F1",
        boxShadow: "0 40px 90px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.08)",
      }}
    >
      <div
        style={{
          height: 56,
          background: "#ECE7DC",
          borderBottom: "1px solid #DAD4C6",
          position: "relative",
          display: "flex",
          alignItems: "center",
          paddingLeft: 22,
          gap: 11,
        }}
      >
        {["#FF5F57", "#FEBC2E", "#28C840"].map((c) => (
          <div key={c} style={{ width: 17, height: 17, borderRadius: "50%", background: c }} />
        ))}
        <div
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: 980,
            lineHeight: "56px",
            textAlign: "center",
            fontFamily: FONT.sans,
            fontWeight: 600,
            fontSize: 21,
            color: "#6B675E",
          }}
        >
          Deneme.txt
        </div>
      </div>
      <div
        style={{
          padding: "50px 60px",
          fontFamily: FONT.serif,
          fontSize: 40,
          lineHeight: 1.75,
          color: "#2A2A33",
        }}
      >
        O akşam sahilde{" "}
        <span
          style={{
            backgroundImage: `linear-gradient(${C.selection}, ${C.selection})`,
            backgroundRepeat: "no-repeat",
            backgroundSize: `${sel * 100}% 100%`,
            padding: "4px 2px",
            margin: "0 -2px",
          }}
        >
          müstesna
        </span>{" "}
        bir sessizlik vardı; ne rüzgâr konuşuyordu ne de dalgalar. Herkes,
        söylenmemiş bir sözün ağırlığını dinliyordu.
      </div>
    </div>
  );
};

/* ---------- Popover: SearchView.swift'in birebir düzeni, 400×500 pt ---------- */

const Tag: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <span
    style={{
      alignSelf: "flex-start",
      fontSize: 10,
      fontWeight: 500,
      color: C.macBlue,
      background: "rgba(10,122,255,0.12)",
      borderRadius: 999,
      padding: "2px 7px",
    }}
  >
    {children}
  </span>
);

const Meaning: React.FC<{
  n: number;
  at: number;
  text: string;
  tag?: string;
  example?: string;
}> = ({ n, at, text, tag, example }) => {
  const frame = useCurrentFrame();
  const o = interpolate(frame, [at, at + 10], [0, 1], clamp);
  return (
    <div
      style={{
        display: "flex",
        gap: 8,
        opacity: o,
        transform: `translateY(${(1 - o) * 6}px)`,
      }}
    >
      <div style={{ width: 20, fontSize: 12, color: "#8A8A8E", textAlign: "center", paddingTop: 1 }}>
        {n}.
      </div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
        <div style={{ fontSize: 13, lineHeight: 1.3, color: "#1D1D1F" }}>{text}</div>
        {tag ? <Tag>{tag}</Tag> : null}
        {example ? (
          <div
            style={{
              display: "flex",
              gap: 6,
              fontSize: 12,
              lineHeight: 1.3,
              color: "#8A8A8E",
              fontStyle: "italic",
              paddingTop: 2,
            }}
          >
            <span style={{ fontStyle: "normal" }}>•</span>
            <span>{example}</span>
          </div>
        ) : null}
      </div>
    </div>
  );
};

const Popover: React.FC = () => {
  const frame = useCurrentFrame();
  const loading = frame < T.resultsAt;
  const cardIn = interpolate(frame, [T.resultsAt, T.resultsAt + 10], [0, 1], clamp);
  const step = 7;

  return (
    <div
      style={{
        width: 400,
        height: 500,
        borderRadius: 12,
        background: "#F4F4F5",
        boxShadow: "0 22px 60px rgba(0,0,0,0.55), 0 0 0 0.5px rgba(0,0,0,0.3)",
        fontFamily: FONT.sans,
        display: "flex",
        flexDirection: "column",
        position: "relative",
      }}
    >
      {/* Menü çubuğu simgesini gösteren ok */}
      <div
        style={{
          position: "absolute",
          top: -7,
          left: 200 - 8,
          width: 16,
          height: 16,
          background: "#F4F4F5",
          transform: "rotate(45deg)",
          borderRadius: 3,
        }}
      />
      <div
        style={{
          margin: "12px 12px 0",
          padding: "6px 8px",
          display: "flex",
          alignItems: "center",
          gap: 6,
          borderRadius: 8,
          background: "#fff",
          border: "1px solid #D9D9DC",
          fontSize: 13,
          color: "#1D1D1F",
        }}
      >
        <MagnifierIcon size={14} />
        <span style={{ flex: 1 }}>müstesna</span>
        <div
          style={{
            width: 14,
            height: 14,
            borderRadius: "50%",
            background: "#8A8A8E",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <XMarkIcon size={9} color="#fff" />
        </div>
      </div>
      <div style={{ height: 1, background: "#DDDDE0", marginTop: 12 }} />

      <div style={{ flex: 1, padding: "8px 12px", position: "relative" }}>
        {loading ? (
          <div
            style={{
              height: 100,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              gap: 8,
              fontSize: 12,
              color: "#8A8A8E",
            }}
          >
            <div
              style={{
                width: 16,
                height: 16,
                borderRadius: "50%",
                border: "2px solid #C8C8CC",
                borderTopColor: "#6E6E73",
                transform: `rotate(${frame * 24}deg)`,
              }}
            />
            Aranıyor...
          </div>
        ) : (
          <div
            style={{
              padding: 12,
              borderRadius: 8,
              background: "#fff",
              border: "1px solid rgba(0,0,0,0.08)",
              boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
              opacity: cardIn,
              display: "flex",
              flexDirection: "column",
              gap: 6,
            }}
          >
            <div style={{ marginBottom: 2 }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: "#1D1D1F" }}>müstesna</div>
              <div style={{ fontSize: 12, color: "#8A8A8E", marginTop: 2 }}>Arapça mustes̱nā</div>
            </div>
            <Meaning
              n={1}
              at={T.resultsAt + step}
              text="Bir bütünün veya kuralın dışında olan"
              tag="sf."
            />
            <Meaning
              n={2}
              at={T.resultsAt + step * 2}
              text="Benzerlerinden üstün olan, benzerleri az bulunan"
              example="Kendisi bu resimlerin hepsinden daha sevimli, daha canlı, daha müstesna bir simaydı."
            />
            <Meaning n={3} at={T.resultsAt + step * 3} text="► kural dışı" />
            <Meaning
              n={4}
              at={T.resultsAt + step * 4}
              text="Dışında, ayrı, hariç tutularak"
              tag="zf."
            />
          </div>
        )}
      </div>

      <div style={{ height: 1, background: "#DDDDE0" }} />
      <div
        style={{
          padding: "8px 12px",
          display: "flex",
          alignItems: "center",
          gap: 8,
          fontSize: 11,
          color: "#8A8A8E",
        }}
      >
        <span style={{ flex: 1 }}>⌃⌘L - Aç/Kapat</span>
        <GearIcon size={13} />
        <XMarkIcon size={12} />
      </div>
    </div>
  );
};

export const Demo: React.FC = () => {
  const frame = useCurrentFrame();
  const docIn = useSpring(4);
  const shift = useSpring(T.popover - 4);
  const pop = useSpring(T.popover, 18, 0.8);

  const keysOut = interpolate(frame, [T.resultsAt, T.resultsAt + 14], [1, 0], clamp);
  const press = (i: number) =>
    Math.min(
      interpolate(frame, [T.press + i * 6, T.press + i * 6 + 4], [0, 1], clamp),
      interpolate(frame, [T.release, T.release + 5], [1, 0], clamp),
    );
  const active = interpolate(frame, [T.popover - 2, T.popover + 4], [0, 1], clamp);

  // Popover açılınca belge sola çekilir ve hafifçe geri plana düşer.
  const docX = interpolate(shift, [0, 1], [470, 110]);

  return (
    <AbsoluteFill>
      <MenuBar active={active} />

      <div
        style={{
          position: "absolute",
          left: docX,
          top: 150,
          opacity: docIn,
          filter: `brightness(${interpolate(shift, [0, 1], [1, 0.8])})`,
          transform: `translateY(${(1 - docIn) * 50}px)`,
        }}
      >
        <DocWindow />
        <div
          style={{
            marginTop: 60,
            display: "flex",
            justifyContent: "center",
            gap: 26,
            opacity: keysOut,
          }}
        >
          {["⌃", "⌘", "L"].map((k, i) => (
            <KeyIn key={k} at={T.keysIn + i * 5}>
              <Keycap label={k} pressed={press(i)} />
            </KeyIn>
          ))}
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          left: POPOVER_X - 200,
          top: 62,
          transformOrigin: "top center",
          transform: `scale(${POPOVER_SCALE * interpolate(pop, [0, 1], [0.86, 1])})`,
          opacity: interpolate(pop, [0, 0.5], [0, 1], clamp),
        }}
      >
        <Popover />
      </div>

      <Caption from={14} to={T.keysIn + 14}>
        Herhangi bir uygulamada bir kelime seç.
      </Caption>
      <Caption from={T.keysIn + 18} to={T.resultsAt}>
        Kısayola bas.
      </Caption>
      <Caption from={T.resultsAt + 6} to={400}>
        Tanımı anında karşında.
      </Caption>
    </AbsoluteFill>
  );
};

const KeyIn: React.FC<{ at: number; children: React.ReactNode }> = ({ at, children }) => {
  const s = useSpring(at, 14);
  return (
    <div style={{ transform: `scale(${s})`, opacity: Math.min(1, s * 1.5) }}>{children}</div>
  );
};

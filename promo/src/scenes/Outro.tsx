import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { AppIcon, Wordmark, clamp, useSpring } from "../components";
import { C, FONT } from "../theme";

export const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const iconIn = useSpring(2, 16);
  const wordIn = useSpring(10);
  const fade = (from: number) => interpolate(frame, [from, from + 16], [0, 1], clamp);

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <AppIcon size={230} style={{ transform: `scale(${iconIn})` }} />
      <div style={{ opacity: wordIn, transform: `translateY(${(1 - wordIn) * 30}px)` }}>
        <Wordmark size={150} hat={1} />
      </div>
      <div
        style={{
          marginTop: 30,
          fontFamily: FONT.serif,
          fontStyle: "italic",
          fontSize: 50,
          color: C.cream,
          opacity: fade(24),
        }}
      >
        Kelimenin anlamı, bir kısayol uzağında.
      </div>
      <div
        style={{
          marginTop: 54,
          padding: "20px 44px",
          borderRadius: 999,
          border: `2px solid ${C.amber}`,
          fontFamily: FONT.mono,
          fontSize: 34,
          color: C.amber,
          opacity: fade(40),
          transform: `translateY(${(1 - fade(40)) * 14}px)`,
        }}
      >
        github.com/mapetek/kamus
      </div>
      <div
        style={{
          marginTop: 34,
          fontFamily: FONT.sans,
          fontSize: 28,
          letterSpacing: 1,
          color: C.creamFaint,
          opacity: fade(52),
        }}
      >
        macOS 12+ · Açık kaynak · MIT · BakedApps
      </div>
    </AbsoluteFill>
  );
};

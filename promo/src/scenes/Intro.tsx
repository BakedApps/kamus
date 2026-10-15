import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { AppIcon, Wordmark, clamp, useSpring } from "../components";
import { C, FONT } from "../theme";

export const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const iconIn = useSpring(4, 14);
  const wordIn = useSpring(22);
  // Düşük sönüm: şapka yerine otururken hafifçe yaylanır.
  const hat = useSpring(46, 11, 0.7);
  const tagIn = interpolate(frame, [66, 84], [0, 1], clamp);

  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <AppIcon
        size={300}
        style={{ transform: `scale(${iconIn})`, opacity: Math.min(1, iconIn * 2) }}
      />
      <div
        style={{
          marginTop: 10,
          opacity: wordIn,
          transform: `translateY(${(1 - wordIn) * 40}px)`,
        }}
      >
        <Wordmark size={190} hat={hat} />
      </div>
      <div
        style={{
          marginTop: 34,
          fontFamily: FONT.sans,
          fontSize: 44,
          color: C.creamDim,
          opacity: tagIn,
          transform: `translateY(${(1 - tagIn) * 16}px)`,
        }}
      >
        Menü çubuğundan anında Türkçe sözlük.
      </div>
    </AbsoluteFill>
  );
};

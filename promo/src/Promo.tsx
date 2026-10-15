import React from "react";
import { AbsoluteFill, Series } from "remotion";
import { Background, SceneFade } from "./components";
import { Demo } from "./scenes/Demo";
import { Features } from "./scenes/Features";
import { Intro } from "./scenes/Intro";
import { Offline } from "./scenes/Offline";
import { Outro } from "./scenes/Outro";

const SCENES: { component: React.FC; duration: number; fadeOut?: number }[] = [
  { component: Intro, duration: 110 },
  { component: Demo, duration: 410 },
  { component: Offline, duration: 190 },
  { component: Features, duration: 170 },
  { component: Outro, duration: 140, fadeOut: 20 },
];

export const PROMO_DURATION = SCENES.reduce((sum, s) => sum + s.duration, 0);

export const Promo: React.FC = () => (
  <AbsoluteFill>
    <Background />
    <Series>
      {SCENES.map(({ component: Scene, duration, fadeOut }) => (
        <Series.Sequence key={Scene.name} durationInFrames={duration}>
          <SceneFade duration={duration} fadeOut={fadeOut}>
            <Scene />
          </SceneFade>
        </Series.Sequence>
      ))}
    </Series>
  </AbsoluteFill>
);

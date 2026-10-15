import React from "react";
import { Composition } from "remotion";
import { PROMO_DURATION, Promo } from "./Promo";
import { FPS, HEIGHT, WIDTH } from "./theme";

export const Root: React.FC = () => (
  <Composition
    id="Promo"
    component={Promo}
    durationInFrames={PROMO_DURATION}
    fps={FPS}
    width={WIDTH}
    height={HEIGHT}
  />
);

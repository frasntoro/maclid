# Changelog

## 1.0.0 — 2026-09-18

First public release.

- The blur follows the real lid angle, read from the MacBook's lid sensor, and
  falls back to a timed animation on sleep and wake where that sensor isn't
  available.
- The fade follows a smootherstep curve and sweeps down from the top of the
  screen, so it has no visible edge.
- Menu bar panel with an on/off switch, blur intensity, the angle at which the
  effect starts, and launch at login.
- Settings window: softness, four visual styles, and an optional colour tint
  taken from the desktop picture, the system accent colour, or one you pick;
  the exact start and full angles, a live lid angle reading, and a manual
  preview; version and credits.
- Reads the sensor eight times a second while the lid is still and sixty while
  it moves, which keeps the idle cost at 0.4% CPU, and stops entirely while the
  effect is off or the screen is locked.
- No permissions, no network access, no screen capture.

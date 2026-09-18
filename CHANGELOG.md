# Changelog

## 2.0.0 — 2026-09-19

### The effect
- New default motion, *Mist*: every part of the screen fogs over together,
  the top a little ahead of the bottom, instead of a front sliding down it.
- The sliding front of 1.0 remains as the *Curtain* style. It now starts as a
  narrow strip growing out of the top edge, visible from the first degrees,
  where 1.0 showed almost nothing for the first tenth of the closing.
- The blur builds up gently over the first part of the closing at any
  intensity, and leaves the same way when the lid opens.
- Softness shapes the motion: how far ahead the top stays in *Mist*, how wide
  the front is in *Curtain*.
- Previews in the settings follow the same shape frame by frame, instead of
  cross-fading between start and end.

### Colour
- Tint options are now Glass, Wallpaper, Color and Gradient.
- Gradient: two colours, which can be swapped, laid top to bottom, diagonally,
  side to side or from the centre, with a Mix control for where they meet and
  a live preview shaped like the screen.
- Only the controls for the chosen tint are shown.

### Settings
- Menu bar panel: both lid angles, *Starts at* and *Full at*, next to
  intensity. The two can't cross: moving one past the other takes it along.
- New General tab, with launch at login (moved out of the panel) and the
  update button (moved out of About).
- The settings window fits each tab, instead of staying as tall as the tallest
  one opened so far.
- The settings window follows changes made from the panel while it's open.

### Removed
- The four blur styles (Adaptive, Light, Dark, Smoke), which differed only in
  a faint veil. The blur is now always the dark glass; Light and Smoke users
  will see it change.
- The system accent colour as a tint source. Anyone who had chosen it keeps
  the same colour, now as a plain *Color* they can change.

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

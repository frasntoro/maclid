# Developing MacLid

## Requirements

Command Line Tools (`xcode-select --install`). Full Xcode is only needed to sign
and notarize a release build.

## Running

```bash
swift run MacLid
```

Launch at login stays disabled here: `SMAppService` registers an app bundle, not
a bare executable.

## Building the app

```bash
./Scripts/build-app.sh
cp -R .build/MacLid.app /Applications/
```

Produces `MacLid.app` with its `Info.plist` (including `LSUIElement`) and icon,
signed ad-hoc. That is enough for the Mac that built it, because locally built
apps carry no quarantine flag, but not for anyone else: once downloaded,
Gatekeeper refuses it until the user right-clicks → Open. Distributing it
cleanly means joining the Apple Developer Program, signing with a Developer ID,
enabling the hardened runtime, and notarizing.

## Icon

Drawn in code, so it lives in the repository as source:

```bash
swift run IconGenerator
iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
```

## Sensor probe

```bash
swift run LidAngleProbe
```

Lists candidate HID devices and prints their raw feature reports while you move
the lid. Useful for checking the sensor on a different Mac.

## Layout

- `Sources/MacLid/main.swift` — entry point and activation policy
- `Sources/MacLid/AppDelegate.swift` — wiring: sensor, settings, sleep/wake
- `Sources/MacLid/EffectSettings.swift` — shared, persisted settings
- `Sources/MacLid/LidAngleSensor.swift` — lid angle over IOKit HID, with an
  adaptive polling rate
- `Sources/MacLid/OverlayWindowController.swift` — full-screen overlay,
  `NSVisualEffectView` behind a soft gradient mask
- `Sources/MacLid/StatusBarController.swift` — menu bar item
- `Sources/MacLid/QuickPanel.swift` — the menu bar panel, hand-built because
  `NSPopover` always centres on its anchor and always draws an arrow
- `Sources/MacLid/*TabViewController.swift` — settings tabs
- `Sources/IconArt/IconArtwork.swift` — app icon and menu bar glyph
- `Sources/IconGenerator/main.swift` — writes the iconset
- `Sources/LidAngleProbe/main.swift` — sensor diagnostics

## Notes

- Angles map to blur: nothing above the start angle, full effect at the full
  angle, both adjustable.
- Without a sensor, `NSWorkspace.willSleepNotification` / `didWakeNotification`
  drive a timed animation. They fire for any sleep, not just the lid.
- `NSVisualEffectView` has a fixed blur radius and always adds a tint, so
  progressive strength comes from blending blurred and sharp. A genuinely
  variable radius, or any 3D transform of the screen contents, would require
  capturing the screen with ScreenCaptureKit — and therefore the Screen
  Recording permission.
- The overlay covers the built-in display only; multi-monitor is still open.

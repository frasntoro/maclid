# MacLid

<img src="Resources/AppIcon-preview.png" width="128" alt="MacLid icon">

The blur follows your lid.

MacLid is a macOS menu bar app that progressively blurs the screen as you close
your MacBook, and clears it as you open it again.

On MacBooks that expose the lid angle sensor (HID sensor page `0x20`, usage
`0x8A`) the blur tracks the real angle in real time. On other Macs it falls back
to a timed animation driven by sleep and wake notifications.

## Requirements

- macOS 12 or later
- Command Line Tools (`xcode-select --install`). Full Xcode is only needed later,
  to sign and notarize a release build.

## Running it

```bash
swift run MacLid
```

The app lives in the menu bar only — no Dock icon, no window in Cmd+Tab, thanks
to `NSApp.setActivationPolicy(.accessory)`.

Click the menu bar icon for the quick controls: an on/off switch, **Intensity**,
and **Start** — the lid angle at which the blur kicks in, from "right away" to
"near closed".

**Settings…** opens the full window:

- **Effect** — intensity, softness, and the system material and tint used for
  the blur
- **Lid** — the start and full angles, the live lid angle reading, and a manual
  preview slider for judging the effect without moving the lid
- **About** — version and credits

Settings are shared between the popover and the window, and persist across
restarts.

## Building a .app

```bash
./Scripts/build-app.sh
open .build/MacLid.app
```

Produces an app bundle with `Info.plist` (including `LSUIElement`) and the
generated icon, ad-hoc signed.

## Icon

The icon is drawn in code, so it lives in the repository as source:

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
- `Sources/MacLid/LidAngleSensor.swift` — lid angle over IOKit HID
- `Sources/MacLid/OverlayWindowController.swift` — full-screen overlay,
  `NSVisualEffectView` behind a soft gradient mask
- `Sources/MacLid/StatusBarController.swift` — menu bar item and popover
- `Sources/MacLid/*TabViewController.swift` — settings tabs
- `Sources/IconGenerator/main.swift` — icon artwork
- `Sources/LidAngleProbe/main.swift` — sensor diagnostics

## Notes

- The blur maps the lid angle: nothing above the start angle, full effect at the
  full angle. Both are adjustable.
- Without a sensor, `NSWorkspace.willSleepNotification` / `didWakeNotification`
  are used, but they fire for any sleep — low battery, idle — not just the lid.
- `NSVisualEffectView` has a fixed blur radius and always adds a tint, so the
  progressive strength is achieved by blending the blurred and sharp images. A
  genuinely variable radius would require ScreenCaptureKit plus
  `CIMaskedVariableBlur`, and therefore the Screen Recording permission.
- The overlay covers the built-in display only; multi-monitor support is still
  open.

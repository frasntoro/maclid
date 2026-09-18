# MacLid

<img src="Resources/AppIcon-preview.png" width="128" alt="MacLid icon">

**The blur follows your lid.**

MacLid gently blurs your screen as you close your MacBook, and clears it as you
open it again. On MacBooks that have a lid angle sensor the blur follows the
real angle, in real time — move the lid halfway and the blur sits halfway.

It lives in the menu bar. No Dock icon, no window in your way.

## Installing

1. Download `MacLid.app`.
2. Drag it into your **Applications** folder.
3. Open it. The lid icon appears in your menu bar, on the right.

The first time you open it, macOS may warn you that it comes from an
unidentified developer. That is because the app isn't signed with a paid Apple
developer certificate, not because anything is wrong with it. To get past it:
**right-click the app → Open**, then confirm. You only need to do this once.

To uninstall, drag `MacLid.app` to the Trash.

## Using it

Click the lid icon in the menu bar:

- **The switch** turns the effect on and off.
- **Intensity** — how strong the blur gets when the lid is fully closed.
- **Start** — how early the effect begins, from *right away* as soon as you
  start closing, to *near closed* only at the end of the movement.
- **Launch at login** — start MacLid automatically when you turn on your Mac.

**Settings…** opens the full window:

| Tab | What's in it |
| --- | --- |
| **Effect** | Softness of the fade, the visual style (adaptive, light, dark, smoke), and an optional colour tint taken from your wallpaper, your system accent colour, or one you pick |
| **Lid** | The exact angles where the blur starts and reaches full strength, a live reading of your lid angle, and a slider to preview the effect without moving the lid |
| **About** | Version and credits |

Your settings are saved and kept between restarts.

## What it does to your Mac

Nothing permanent. MacLid draws a translucent window on top of the screen and
reads the lid angle sensor — reading only, the sensor cannot be controlled. It
asks for no permissions, has no network access, installs no drivers or system
extensions, and changes no system settings. Quit it and everything is gone
instantly.

## Requirements

- macOS 12 or later
- The real-time lid tracking needs a MacBook with an accessible lid angle
  sensor, which most models from the 2019 16-inch MacBook Pro onwards have. On
  other Macs the effect still works, animated on a timer when the Mac sleeps and
  wakes. The About tab tells you which of the two applies to yours.

## Building it yourself

See [DEVELOPING.md](DEVELOPING.md).

---

By Francesco Santoro — [frasntoro](https://github.com/frasntoro)

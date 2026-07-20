# NuPhy keyboard files

These files are manual backups. The dotfiles installer does not load or flash them.

## Air60 V2

- `nuphy-air60-v2-via.json` is NuPhy's official VIA device definition for VID `0x19F5`, PID `0x3255`. It lets VIA recognize the keyboard; it does not contain personal mappings or firmware.
- `nuphy_air60_v2.layout.json` is the personal VIA keymap backup. It contains 8 layers, macros, and the mapped keys stored on the keyboard.

### Verified baseline

Last verified: **2026-07-20**.

- The definition matches the current download from [NuPhy's JSON files page](https://nuphy.com/pages/json-files-for-nuphy-keyboards).
- Definition SHA-256: `dcc25e91fc83bfd4e47bf18a3b9a0aa58aceef2dc99a6e319c3fbe9d4b63325c`.
- The saved layout exactly matches the VIA export made on 2026-07-20.
- Layout SHA-256: `53dfc59f3c75500c7d48b618c2069bedd99abfef0be975c7970f9845bd5653e1`.
- NuPhy's latest listed Air60 V2 firmware was `v2.1.5`, released 2025-03-04. This does not prove which version is installed; VIA and macOS do not expose a reliable NuPhy release number. No firmware was flashed during this verification.
- **Do not flash v2.1.5 without rechecking it:** on 2026-07-20, NuPhy's current RF ZIP had SHA-1 `a72416beb909331e704e70253072f3a840f905ba`, which did not match the published RF SHA-1 `c65a9279d4cc8ca0aec5c01ff7b5c35863673900` or any file inside the ZIP.

### Connect in VIA

1. Put the Air60 V2 in wired mode and connect it by USB.
2. Open [VIA](https://usevia.app/) in a Chromium browser.
3. In Settings, enable **Show Design Tab**.
4. In Design, load `nuphy-air60-v2-via.json`.
5. Return to Configure, choose **Authorize device**, and select **NuPhy Air60 V2**.

### Restore the saved mappings

Only do this when the keyboard mappings need to be restored: in Configure, open **Save + Load** and load `nuphy_air60_v2.layout.json`. Loading it writes the saved keymap back to the keyboard.

Save a fresh layout before any firmware update. Use only the exact Air60 V2 files and steps from [NuPhy's firmware page](https://nuphy.com/pages/qmk-firmwares); VIA does not reliably report the installed NuPhy release version.

## Maintenance

No scheduled maintenance is required. If the keyboard works correctly, leave the firmware alone.

After changing any mapping in VIA:

1. Open **Save + Load** and save a fresh layout.
2. Replace `nuphy_air60_v2.layout.json` with that export.
3. Confirm it still reports `NuPhy Air60 V2`, 8 layers, and the expected mappings before committing it.

After a long gap, or when troubleshooting:

1. Confirm the device is Air60 V2 with VID `0x19F5` and PID `0x3255`.
2. Compare the official definition with `nuphy-air60-v2-via.json`; update it only if the official JSON changed.
3. Read the current Air60 V2 firmware release notes. Update only for a relevant fix, not merely because a newer version exists.
4. Before any firmware work, save a fresh layout and follow every Air60 V2 QMK, RF, and macOS-dongle step listed for that release.

If VIA enters a repeated error loop, reload the VIA tab and authorize the keyboard again. Do not repeatedly reload the definition, and do not load the saved layout unless restoring mappings.

## Firmware safety

No firmware binaries are stored here. Only use firmware made specifically for the **Air60 V2**; never flash Air75 firmware onto it.

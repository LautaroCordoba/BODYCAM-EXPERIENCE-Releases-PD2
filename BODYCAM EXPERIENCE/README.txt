BODYCAM 1.0.0
By Brouken

Bodycam-style weapon handling for PAYDAY 2, with Wrist inertia, FreeAim,
smooth camera follow and aligned aiming, including canted sights.
Compatible hitscan weapons use the visible muzzle's direction when firing.

INSTALLATION
1. Install SuperBLT for PAYDAY 2.
2. Extract the BODYCAM folder into PAYDAY 2/mods/.
   The resulting path must be PAYDAY 2/mods/BODYCAM/mod.txt.
3. Start the game. BODYCAM is ON on the first installation.

CONTROLS
F8: BODYCAM Mode (ON / OFF).
Change this key in Options > Mod Keybinds > BODYCAM Mode.
Your last ON/OFF state and assigned key are remembered between sessions.
ON enables Bodycam view, Wrist inertia, FreeAim and muzzle-directed firing.
OFF restores native weapon handling and native firing direction.

COMPATIBILITY
Designed for desktop play. VR is not supported.
Muzzle direction applies to compatible normal hitscan weapons. Special firing
paths, active underbarrel weapons and unsupported implementations keep their
native firing behavior. Native bullet spread and aim assistance are retained.
The shot still originates at the game's native firing position, not physically
at the muzzle. Close-wall weapon interaction is not included.
Other mods that replace camera or weapon firing code may conflict.

UNINSTALLATION
Close the game and remove the BODYCAM folder from mods/.
To also reset saved preferences, remove mods/saves/bodycam_settings.json.

See LICENSE.txt for usage permissions. Modification and reuploading require
prior written permission from Brouken.

<!-- BODYCAM_CONTROLS_START -->

## Controls

### BODYCAM Mode

Toggle Bodycam view, Wrist inertia, FreeAim and muzzle-directed firing. Your last ON/OFF state is remembered. Default: F8.

**Keybind:** `bodycam_mode`

Keybinds can be changed from PAYDAY 2's keybind settings.

<!-- BODYCAM_CONTROLS_END -->

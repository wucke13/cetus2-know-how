# Before you start using this

This config is optimized for my specific printer. Be cautious when trying this
out, it might damage your printer!

The super slicer config shipped in this repo assumes that you fix the generated
GCODE using the `fix-gcode.awk` script before you put it on the printer.

# Interesting Commands

| GCODE              | Effect                                                             |
| ------------------ | ------------------------------------------------------------------ |
| `OUT 13 0`         | ? stop cooling fan                                                 |
| `OUT 13 1`         | ? start cooling fan                                                |
| `M42 P14 S<speed>` | set cooling fan PWM speed, any value between (including) 0 and 511 |
| `SET 23 1`         | ? use extruder 1                                                   |
| `SET 23 2`         | ? use extruder 2                                                   |
| `SET 23 3`         | ? use 50/50 mix of both extruders                                  |


# Known issues

- Extrusion is roughly 1/25 of what it should be
  - `Filament Settings` -> `Extrusion Multiplier` := 25
- The Print status via `M73` is broken, SuperSlicer emits the time after `R` in
  minutes, but Cetus2 expects the time in seconds after `T`
  - The command is converted by the `awk` script
- Auto Bed Leveling does not seem to work - values are picked up while
  measuring, but the Z axis is never adjusted according to them
- Extrusion with extruder 2 uses `B` instead of `E` as extrusion amount prefix
  - The character is replaced on demand by the `awk` script
- The printer seems to expect a negative Z offset; if the UP Studio3 slicer is
  configured for 0.15 mm layer thickness, the first layer starts at `Z` -0.1
  mm, the second one is applied at 0.05 mm etc.
  - A `Z offset` of -0.25 mm is applied in the SuperSlicer config

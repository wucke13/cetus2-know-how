# Before you start using this

This config is optimized for my specific printer. One thing that has to be
adjusted for your printer to avoid damage is the `Z offset`. The Up Studio
slicer seems to start its first layer at `Z0`. And the auto bed leveling
feature does pick up values, but it does not seem to apply them - e.g. when
the print bed is not perfectly flat, you might end up with a nozzle lingering
some 1 mm to 1.5 mm above the print bed surface. In order to fix that, I set a
negative `Z offset` in the slicer, which on your particular printer might crash
the nozzle into the bed. Thus, it is strongly advised that you start with no
`Z offset`, slowly lowering the value until your prints start sticking to the
print bed.

Let `h` be the bed leveling height at the middle of the bed and `f`
be the desired first layer height, then `Z offset` should be `f-h`.


# Interesting Commands

| GCODE              | Effect                                                             |
| ---                | ---                                                                |
| `OUT 13 0`         | ? stop cooling fan                                                 |
| `OUT 13 1`         | ? start cooling fan                                                |
| `M42 P14 S<speed>` | set cooling fan PWM speed, any value between (including) 0 and 511 |
| `SET 23 1`         | ? use extruder 1                                                   |
| `SET 23 2`         | ? use extruder 2                                                   |
| `SET 23 3`         | ? use 50/50 mix of both extruders                                  |


# Known issues

+ Extrusion is roughly 1/25 of what it should be
  + `Filament Settings` -> `Extrusion Multiplier` := 25
+ The Print status via `M73` is broken
  + SuperSlicer emits the time after `T` in minutes, but Cetus2 expects seconds
+ Auto Bed Leveling does not seem to work - values are picked up while
  measuring, but the Z axis is never adjusted according to them

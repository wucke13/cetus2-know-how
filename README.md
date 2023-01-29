# Interesting Commands

| GCODE              | Effect                                                             |
| ---                | ---                                                                |
| `OUT 13 0`         | ? stop cooling fan                                                 |
| `OUT 13 1`         | ? start cooling fan                                                |
| `M42 P14 S<speed>` | set cooling fan PWM speed, any value between (including) 0 and 511 |
| `SET 23 1`         | ? activates filament 1                                               |
| `SET 23 2`         | ? activates filament 2                                               |
| `SET 23 3`         | ? activates 50/50 mix of both filaments                            |

# Quirks

It is assumed that the first layer is started at Z0, e.g. first_layer_height
should be 0. However, that is forbidden by SuperSlicer, thus a negative Z
offset. Let `h` be the bed leveling height at the middle of the bed and `f`
be the desired first layer height, then set the `Z offset` to `f-h`.

# Known issues

+ Extrusion is roughly 1/25 of what it should be
  + `Filament Settings` -> `Extrusion Multiplier` := 25
+ The Print status via `M73` is broken
  + SuperSlicer emits the time after `T` in minutes, but Cetus2 expects seconds
+

#!/usr/bin/env -S awk --exec

BEGIN {
  # either space or semicolon delimit fields
  FS=" |;"

  # prefix for extrusion length on the different extruders
  extruder_pref[1]="A"
  extruder_pref[2]="B"

  # index of the current extruder, 0 means not set
  extruder_idx=0

  # whether we are retracted currently
  retracted=0

  # how far to retract
  retraction=30

  # extra length to add while unretracting
  # only applied to active extruder
  unretraction_extra_length=-10

  # how far to rise on the Z axis during retraction
  # currently unused
  retraction_z=0
}

# set the current extruder
/^SET 23/ {
  extruder_idx=int($3)
}

# adjust extrusion amount and retraction speed
"G1" == $1 {
  # fail if current extruder is unknown
  if (!(extruder_idx in extruder_pref))
    exit 1

  extrusion_in_mm_for_e1000=38 # change this if necessary
  correction_factor=1000 / extrusion_in_mm_for_e1000 # or change this?
  extrusion_length=0
  extrusion_speeed=0
  for (i=1; i<=NF; i++){
    if ($i ~/^E/) extrusion_length=substr($i, 2)
    if ($i ~/^F/) extrusion_speed=substr($i, 2)
  }
  sub("E" extrusion_length, extruder_pref[extruder_idx] (extrusion_length * correction_factor))
  if (NF==3 && extrusion_length != 0 && extrusion_speed != 0)
    sub("F" extrusion_speed, "F" (extrusion_speed * correction_factor))
}

# DEF G9 G0 A-30 B-30,G9 X{X} Y{Y} Z{Z} R0 H{H},G0 A30 B30
# firmware retraction
"G10" == $1 {
  # only retract once
  if (retracted) next
  retracted=1
  print "G1 A-" retraction " B-" retraction "; retract"
  next
}

# firmware detraction
"G11" == $1 {
  # only unretract once
  if (!retracted) next
  retracted=0

  # to avoid small blobs unretract only partial on the active extruder
  if (extruder_idx == 1)
    print "G1 A" (retraction + unretraction_extra_length) " B" retraction "; unretract"
  else if (extruder_idx == 2)
    print "G1 A" retraction " B" (retraction + unretraction_extra_length) "; unretract"
  next
}

# convert remaining print time to seconds
"M73" == $1 {
  for(i=1; i<=NF; i++) if ($i ~/R/) ete_minutes=substr($i, 2)
  sub("R" ete_minutes, "T" (ete_minutes * 60))
}

# adjust cooling fan
"M106" == $1 {
  for (i=1; i<=NF; i++) if ($i ~/S/) fan_percent=substr($i, 2)
  print "M42 P14 S" int(511 * fan_percent / 100) "; set cooling fan to " fan_percent "%"
}

# stop cooling fan
"M107" == $1 {
  print "M42 P14 S0; stop cooling fan"
}

# set retraction length
"M207" == $1 {
  for (i=1; i<=NF; i++){
    if ($i ~/^S/) retraction=substr($i, 2)
    if ($i ~/^Z/) retraction_z=substr($i, 2)
  }
  next
}

# set unretraction length
"M208" == $1 {
  for (i=1; i<=NF; i++) if ($i ~/^S/) unretraction_extra_length=substr($i, 2)
  next
}

# remove these commands, they might confuse the printer
"M486" == $1 { next }

# everything unmatched stays as it is
{ print $0 }


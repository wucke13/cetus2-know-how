#!/usr/bin/env -S awk -f

BEGIN {
  # either space or semicolon delimit fields
  FS=" |;"

  # prefix for extrusion length on the different extruders
  extruder_pref[0]="A"
  extruder_pref[1]="B"

  # index of the current extruder, 0 means not set
  extruder_idx=-1

  # whether we are retracted currently
  retracted=0

  # how far to retract
  retraction=30

  # extra length to add while unretracting
  # only applied to active extruder
  unretraction_extra_length=0

  # how far to rise on the Z axis during retraction
  # currently unused
  z_hop=0
}

# set the current extruder
$1 ~/^T[01]/ {
  extruder_idx=int(substr($1, 2))
  print "SET", "23", extruder_idx + 1, ";", $0
  next
}

# adjust extrusion amount and retraction speed
"G0" == $1 || "G1" == $1 {
  # fail if current extruder is unknown
  if (!(extruder_idx in extruder_pref)) exit 1

  extrusion_in_mm_for_e1000=36 # change this if necessary
  correction_factor=1000 / extrusion_in_mm_for_e1000 # or change this?
  extrusion_length=0
  extrusion_speeed=0
  for (i=1; i<=NF; i++){
    if ($i ~/^E/) extrusion_length=substr($i, 2)
    if ($i ~/^F/) extrusion_speed=substr($i, 2)
    if ($i ~/^Z/) position["z"]=substr($i,2)
  }
  sub("E" extrusion_length, extruder_pref[extruder_idx] (extrusion_length * correction_factor))
  if (NF==3 && extrusion_length != 0 && extrusion_speed != 0)
    sub("F" extrusion_speed, "F" (extrusion_speed * correction_factor))
}

# firmware retraction
"G10" == $1 {
  # terminate if z_hop negative
  if (z_hop < 0) exit 1
  # terminate if position["z"] is not set
  if (!("z" in position)) exit 1

  # only retract once
  if (retracted) next
  retracted=1
  print "G0", "A" (-retraction), "B" (-retraction) "; retract"
  print "G0", "Z" (position["z"] + z_hop) "; z hop"
  next
}

# firmware detraction
"G11" == $1 {
  # terminate if position["z"] is not set
  if (!("z" in position)) exit 1

  # only unretract once
  if (!retracted) next
  retracted=0

  # to avoid small blobs unretract only partial on the active extruder
  if (extruder_idx == 0)
    print "G0", "Z" position["z"], "A" (retraction + unretraction_extra_length), "B" retraction "; unretract"
  else if (extruder_idx == 1)
    print "G0", "Z" position["z"], "A" retraction, "B" (retraction + unretraction_extra_length) "; unretract"

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
  print "M42", "P14", "S" int(511 * fan_percent / 100) "; set cooling fan to", fan_percent "%"
}

# stop cooling fan
"M107" == $1 {
  print "M42 P14 S0; stop cooling fan"
}

# set retraction length
"M207" == $1 {
  for (i=1; i<=NF; i++){
    if ($i ~/^S/) retraction=substr($i, 2)
    if ($i ~/^Z/) z_hop=substr($i, 2)
  }
  print ";", $0
  next
}

# set unretraction length
"M208" == $1 {
  for (i=1; i<=NF; i++) if ($i ~/^S/) unretraction_extra_length=substr($i, 2)
  print ";", $0
  next
}

# remove these commands, they might confuse the printer
"M486" == $1 { next }

# everything unmatched stays as it is
{ print $0 }


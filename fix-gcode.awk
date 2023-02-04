#!/usr/bin/env -S awk --exec

BEGIN {
  extruder_pref[1]="E"
  extruder_pref[2]="B"
  extruder_idx=0
}

# set the current extruder
/^SET 23/ {
  extruder_idx=int($3)
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


# adjust extrusion ammount and retraction speed
"G1" == $1 {
  # fail if current extruder is unknown
  if (!(extruder_idx in extruder_pref))
    exit 1

  extrusion_in_mm_for_e1000=38 # change this if necessary
  correction_factor=1000 / extrusion_in_mm_for_e1000 # or change this?
  extrusion_length=0
  extrusion_speeed=0
  for (i=1; i<=NF; i++){
    if ($i ~/E/) extrusion_length=substr($i, 2)
    if ($i ~/F/) extrusion_speed=substr($i, 2)
  }
  sub("E" extrusion_length, extruder_pref[extruder_idx] (extrusion_length * correction_factor))
  if (NF==3 && extrusion_length != 0 && extrusion_speed != 0)
    sub("F" extrusion_speed, "F" (extrusion_speed * correction_factor))
}

# adjust remaining print time
"M73" == $1 {
  for(i=1; i<=NF; i++) if ($i ~/R/) ete_minutes=substr($i, 2)
  sub("R" ete_minutes, "T" (ete_minutes * 60))
}

# everything unmatched stays as it is
{print $0}


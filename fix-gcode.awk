#!/usr/bin/env -S awk -f

# adjust cooling fan
/M106/ {
  for(i=1; i<=NF; i++) if ($i ~/S/) fan_percent=substr($i, 2)
  print "M42 P14 S" int(511 * fan_percent / 100) "; set cooling fan to " fan_percent "%"
}

# stop cooling fan
/M107/ {
  print "M42 P14 S0; stop cooling fan"
}

# adjust extrusion ammount
/G1/ {
  extrusion_in_mm_for_e1000=38 # change this if necessary
  correction_factor=1000 / extrusion_in_mm_for_e1000 # or change this?
  extrusion_ammount=0
  for(i=1; i<=NF; i++) if ($i ~/E/) extrusion_ammount=substr($i, 2)
  sub("E" extrusion_ammount, "E" extrusion_ammount * correction_factor, $0)
}

# adjust remaining print time
/M73/ {
  for(i=1; i<=NF; i++) if ($i ~/R/) ete_minutes=substr($i, 2)
  sub("R" ete_minutes, "T" ete_minutes * 60, $0)
}

# everything unmatched stays as it is
{print $0}

